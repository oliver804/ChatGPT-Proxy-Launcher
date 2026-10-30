using System.Diagnostics;
using System.Text.Json;
using System.Runtime.InteropServices;
using System.Net;

namespace LocalRouteLauncher;

public static class WindowsPlatform
{
    private static string PowerShell => Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
    // Fixed scripts only; no host, port, or application path is interpolated into PowerShell.
    private static async Task<string> RunScript(string script)
    {
        var info = new ProcessStartInfo(PowerShell) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
        foreach (var a in new[] { "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); $ErrorActionPreference='Stop'; " + script }) info.ArgumentList.Add(a);
        using var process = Process.Start(info) ?? throw new InvalidOperationException("ProcessReadFailed");
        var output = process.StandardOutput.ReadToEndAsync();
        var errors = process.StandardError.ReadToEndAsync();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        try { await process.WaitForExitAsync(timeout.Token); }
        catch (OperationCanceledException) { process.Kill(true); await process.WaitForExitAsync(); throw new InvalidOperationException("ProcessReadFailed"); }
        await errors; // Do not include unrelated process or system data in user-facing errors.
        if (process.ExitCode != 0) throw new InvalidOperationException("ProcessReadFailed");
        return await output;
    }
    public static async Task<List<ProcessRow>> Processes()
    {
        var json = await RunScript("@(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,ExecutablePath,CommandLine) | ConvertTo-Json -Compress");
        if (string.IsNullOrWhiteSpace(json)) throw new InvalidOperationException("ProcessReadFailed");
        using var doc = JsonDocument.Parse(json);
        var nodes = doc.RootElement.ValueKind == JsonValueKind.Array ? doc.RootElement.EnumerateArray().ToArray() : [doc.RootElement];
        return nodes.Select(e => new ProcessRow(e.GetProperty("ProcessId").GetInt32(), e.GetProperty("ParentProcessId").GetInt32(),
            e.GetProperty("ExecutablePath").GetString() ?? "", e.GetProperty("CommandLine").GetString() ?? "")).ToList();
    }
    public static async Task<string[]> Discover(string application = "chatgpt")
    {
        const string script = "@(Get-AppxPackage | Where-Object { $_.Name -in @('OpenAI.ChatGPT','OpenAI.Codex') } | ForEach-Object { $p=$_; $m=Get-AppxPackageManifest $p; @($m.Package.Applications.Application) | ForEach-Object { if ($_.Executable) { Join-Path $p.InstallLocation $_.Executable } } }) | ConvertTo-Json -Compress";
        var candidates = new List<string>();
        try
        {
            var json = application == "chatgpt" ? await RunScript(script) : "";
            if (!string.IsNullOrWhiteSpace(json))
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.ValueKind == JsonValueKind.Array) candidates.AddRange(doc.RootElement.EnumerateArray().Select(e => e.GetString() ?? ""));
                else if (doc.RootElement.ValueKind == JsonValueKind.String) candidates.Add(doc.RootElement.GetString()!);
            }
        }
        catch (Exception ex) when (ex is InvalidOperationException or JsonException) { /* Manual selection remains available. */ }
        var local = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);
        var target = TargetApp.Get(application);
        foreach (var root in new[] { Path.Combine(local, "Programs"), local, Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles) })
        foreach (var executable in application == "antigravityIDE" ? new[] { target.Executable, "Antigravity.exe" } : new[] { target.Executable })
            candidates.Add(Path.Combine(root, target.Folder, executable));
        return candidates.Where(path => IsCompatible(path, application)).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
    }
    public static bool IsCompatible(string path, string application = "chatgpt")
    {
        try
        {
            var directory = Path.GetDirectoryName(Path.GetFullPath(path))!;
            var target = TargetApp.Get(application);
            var file = Path.GetFileName(path);
            if (!File.Exists(path) || !(string.Equals(file, target.Executable, StringComparison.OrdinalIgnoreCase) ||
                application == "antigravityIDE" && string.Equals(file, "Antigravity.exe", StringComparison.OrdinalIgnoreCase)) ||
                !File.Exists(Path.Combine(directory, "icudtl.dat")) || !File.Exists(Path.Combine(directory, "chrome_100_percent.pak"))) return false;
            if (application == "antigravityIDE")
            {
                var product = Path.Combine(directory, "resources", "app", "product.json");
                if (!File.Exists(product)) return false;
                using var data = JsonDocument.Parse(File.ReadAllText(product));
                return data.RootElement.TryGetProperty("applicationName", out var name) && name.GetString() == "antigravity-ide";
            }
            if (!File.Exists(Path.Combine(directory, "resources", "app.asar"))) return false;
            return application == "chatgpt" || string.Equals(FileVersionInfo.GetVersionInfo(path).ProductName, "Antigravity", StringComparison.OrdinalIgnoreCase);
        }
        catch (Exception ex) when (ex is ArgumentException or IOException or UnauthorizedAccessException or JsonException) { return false; }
    }
    public static List<ProcessRow> Roots(string path, IEnumerable<ProcessRow> rows) => rows.Where(p => string.Equals(p.Path, path, StringComparison.OrdinalIgnoreCase) && !SplitArguments(p.CommandLine).Any(a => a.StartsWith("--type=", StringComparison.Ordinal))).ToList();
    public static async Task<int> Launch(string path, ProxyEndpoint endpoint, string application = "chatgpt")
    {
        path = Path.GetFullPath(path);
        if (!IsCompatible(path, application)) throw new InvalidOperationException("InvalidApplication");
        var rows = await Processes();
        // Refuse ambiguous same-name processes instead of accidentally starting a second instance.
        foreach (var process in Process.GetProcessesByName(Path.GetFileNameWithoutExtension(path)))
        {
            using (process)
                if (!rows.Any(row => row.Pid == process.Id && row.Path.Length > 0 && !string.Equals(row.Path, path, StringComparison.OrdinalIgnoreCase)))
                    throw new InvalidOperationException("AlreadyRunning");
        }
        var info = new ProcessStartInfo(path) { UseShellExecute = false, WorkingDirectory = Path.GetDirectoryName(path)! };
        foreach (var a in endpoint.Arguments) info.ArgumentList.Add(a);
        foreach (var pair in endpoint.Environment) info.Environment[pair.Key] = pair.Value;
        using var started = Process.Start(info) ?? throw new InvalidOperationException("LaunchFailed");
        return started.Id;
    }
    public static async Task Stop(string path)
    {
        var roots = Roots(Path.GetFullPath(path), await Processes());
        foreach (var row in roots)
        {
            try
            {
                using var process = Process.GetProcessById(row.Pid);
                // Recheck path to protect against a PID being reused after the snapshot.
                if (!string.Equals(process.MainModule?.FileName, path, StringComparison.OrdinalIgnoreCase)) continue;
                if (!process.CloseMainWindow() && !process.HasExited) throw new InvalidOperationException("CloseManually");
            }
            catch (ArgumentException) { /* Exited during snapshot. */ }
        }
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(8));
        foreach (var row in roots)
        {
            try
            {
                using var process = Process.GetProcessById(row.Pid);
                if (string.Equals(process.MainModule?.FileName, path, StringComparison.OrdinalIgnoreCase))
                    await process.WaitForExitAsync(timeout.Token);
            }
            catch (ArgumentException) { }
            catch (OperationCanceledException) { throw new InvalidOperationException("CloseManually"); }
        }
    }
    [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CommandLineToArgvW(string commandLine, out int count);
    [DllImport("kernel32.dll")] private static extern IntPtr LocalFree(IntPtr memory);
    public static string[] SplitArguments(string commandLine)
    {
        if (string.IsNullOrEmpty(commandLine)) return [];
        var pointer = CommandLineToArgvW(commandLine, out var count);
        if (pointer == IntPtr.Zero) return [];
        try { return Enumerable.Range(0, count).Select(i => Marshal.PtrToStringUni(Marshal.ReadIntPtr(pointer, i * IntPtr.Size)) ?? "").ToArray(); }
        finally { LocalFree(pointer); }
    }
    [DllImport("iphlpapi.dll", SetLastError = true)]
    private static extern uint GetExtendedTcpTable(IntPtr table, ref int size, bool order, int family, int tableClass, uint reserved);
    public sealed record Connection(int Pid, IPAddress Remote, int Port);
    public static List<Connection> Connections(HashSet<int> family)
    {
        var result = new List<Connection>();
        foreach (int af in new[] { 2, 23 })
        {
            int size = 0;
            var status = GetExtendedTcpTable(IntPtr.Zero, ref size, false, af, 5, 0);
            if (status != 122 && status != 0) throw new InvalidOperationException("ConnectionsUnavailable");
            for (int retry = 0; retry < 3; retry++)
            {
                var buffer = Marshal.AllocHGlobal(size);
                try
                {
                    status = GetExtendedTcpTable(buffer, ref size, false, af, 5, 0);
                    if (status == 122) continue;
                    if (status != 0) throw new InvalidOperationException("ConnectionsUnavailable");
                    int count = Marshal.ReadInt32(buffer), stride = af == 2 ? 24 : 56;
                    for (int i = 0; i < count; i++)
                    {
                        int start = 4 + i * stride;
                        if (start + stride > size) throw new InvalidDataException("ConnectionsUnavailable");
                        int pid = Marshal.ReadInt32(buffer, start + (af == 2 ? 20 : 52));
                        int state = Marshal.ReadInt32(buffer, start + (af == 2 ? 0 : 48));
                        if (state != 5 || !family.Contains(pid)) continue;
                        var bytes = new byte[af == 2 ? 4 : 16];
                        Marshal.Copy(buffer + start + (af == 2 ? 12 : 24), bytes, 0, bytes.Length);
                        int portOffset = start + (af == 2 ? 16 : 44);
                        var port = (Marshal.ReadByte(buffer, portOffset) << 8) | Marshal.ReadByte(buffer, portOffset + 1);
                        result.Add(new(pid, af == 2 ? new IPAddress(bytes) : new IPAddress(bytes, (uint)Marshal.ReadInt32(buffer, start + 40)), port));
                    }
                    break;
                }
                finally { Marshal.FreeHGlobal(buffer); }
            }
            if (status != 0) throw new InvalidOperationException("ConnectionsUnavailable");
        }
        return result;
    }
}
