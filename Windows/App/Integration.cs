using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text.Json;

namespace LocalRouteLauncher;

internal static class Integration
{
    public static async Task Run(string fixture, string resultPath)
    {
        fixture = Path.GetFullPath(fixture); Directory.CreateDirectory(Path.GetDirectoryName(resultPath)!);
        var report = resultPath + ".fixture.json";
        var previous = Environment.GetEnvironmentVariable("LRL_FIXTURE_REPORT");
        var originalProxy = Environment.GetEnvironmentVariable("HTTP_PROXY");
        using var listener = new TcpListener(IPAddress.Loopback, 0); listener.Start();
        var endpoint = new ProxyEndpoint("127.0.0.1", ((IPEndPoint)listener.LocalEndpoint).Port.ToString());
        int pid = 0;
        try
        {
            Environment.SetEnvironmentVariable("LRL_FIXTURE_REPORT", report);
            if (!WindowsPlatform.IsCompatible(fixture)) throw new Exception("Fixture compatibility markers not found");
            pid = await WindowsPlatform.Launch(fixture, endpoint);
            using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(30));
            using var connection = await listener.AcceptTcpClientAsync(deadline.Token);
            while (!File.Exists(report)) await Task.Delay(100, deadline.Token);
            using var data = JsonDocument.Parse(await File.ReadAllTextAsync(report, deadline.Token));
            var json = data.RootElement;
            if (!endpoint.MatchesArguments(json.GetProperty("Arguments").EnumerateArray().Select(a => a.GetString()!))) throw new Exception("Arguments lost");
            foreach (var key in new[] { "Proxy", "HttpsProxy", "AllProxy" }) if (json.GetProperty(key).GetString() != endpoint.Url) throw new Exception("Environment lost");
            if (json.GetProperty("NodeProxy").GetString() != "1" || json.GetProperty("NoProxy").GetString() != endpoint.Environment["NO_PROXY"]) throw new Exception("Environment incomplete");
            if (Environment.GetEnvironmentVariable("HTTP_PROXY") != originalProxy) throw new Exception("Parent environment changed");
            var rows = await WindowsPlatform.Processes(); var roots = WindowsPlatform.Roots(fixture, rows);
            if (!roots.Any(r => r.Pid == pid && endpoint.MatchesArguments(WindowsPlatform.SplitArguments(r.CommandLine)))) throw new Exception("Actual launch arguments could not be verified");
            var family = ProcessFamily.Collect(roots.Select(r => r.Pid), rows);
            if (!WindowsPlatform.Connections(family).Any(c => c.Pid == pid && endpoint.Matches(c.Remote, c.Port))) throw new Exception("PID-scoped TCP connection not found");
            if (WindowsPlatform.Connections([]).Count != 0) throw new Exception("Unrelated connection exposed");
            bool duplicateRejected = false;
            try { await WindowsPlatform.Launch(fixture, endpoint); } catch (InvalidOperationException ex) when (ex.Message == "AlreadyRunning") { duplicateRejected = true; }
            if (!duplicateRejected) throw new Exception("Duplicate launch allowed");
            await WindowsPlatform.Stop(fixture);
            if (WindowsPlatform.Roots(fixture, await WindowsPlatform.Processes()).Count != 0) throw new Exception("Graceful stop failed");
            File.WriteAllText(resultPath, "PASS: self-contained launch; argv/env propagation; parent environment unchanged; CIM arguments; PID-scoped TCP; duplicate rejection; graceful close. Fixture only, not an authenticated ChatGPT session.");
        }
        finally
        {
            Environment.SetEnvironmentVariable("LRL_FIXTURE_REPORT", previous);
            // Only the test-owned fixture may be killed on failure; production Stop never does this.
            if (pid != 0) try { using var process = Process.GetProcessById(pid); if (!process.HasExited && string.Equals(process.MainModule?.FileName, fixture, StringComparison.OrdinalIgnoreCase)) process.Kill(); } catch (ArgumentException) { }
            if (File.Exists(report)) File.Delete(report);
        }
    }
}
