using System.Text.Json;
using System.Globalization;

namespace LocalRouteLauncher;

public sealed record Settings
{
    public string Host { get; init; } = "127.0.0.1";
    public string Port { get; init; } = "7890";
    public string ApplicationPath { get; init; } = "";
    public string Language { get; init; } = AppLanguages.Resolve(CultureInfo.CurrentUICulture.Name);
    public string Theme { get; init; } = "system";
    public static string DefaultPath => Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData), "LocalRouteLauncher", "settings.json");
    public static Settings Load() => Load(DefaultPath);
    public void Save() => Save(DefaultPath);
    public static Settings Load(string path)
    {
        if (!File.Exists(path)) return new();
        var result = JsonSerializer.Deserialize<Settings>(File.ReadAllText(path)) ?? throw new InvalidDataException("InvalidSettings");
        if (result.Host is null || result.Port is null) throw new InvalidDataException("InvalidSettings");
        _ = new ProxyEndpoint(result.Host, result.Port);
        if (!AppLanguages.Codes.Contains(result.Language) || result.Theme is not ("system" or "light" or "dark") || result.ApplicationPath is null)
            throw new InvalidDataException("InvalidSettings");
        return result;
    }
    public void Save(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        var temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        try
        {
            File.WriteAllText(temporary, JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true }));
            File.Move(temporary, path, true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
}

public sealed record ProcessRow(int Pid, int ParentPid, string Path, string CommandLine);
public static class ProcessFamily
{
    public static HashSet<int> Collect(IEnumerable<int> roots, IEnumerable<ProcessRow> rows)
    {
        var result = roots.ToHashSet();
        var list = rows.ToArray();
        bool changed;
        do
        {
            changed = false;
            foreach (var row in list)
                if (row.Pid > 0 && result.Contains(row.ParentPid)) changed |= result.Add(row.Pid);
        } while (changed);
        return result;
    }
}
