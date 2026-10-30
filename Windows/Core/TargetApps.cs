namespace LocalRouteLauncher;

public sealed record TargetApp(string Id, string Name, string Folder, string Executable, string ProbeUrl)
{
    public static readonly TargetApp[] All = [
        new("chatgpt", "ChatGPT", "ChatGPT", "ChatGPT.exe", "https://chatgpt.com/"),
        new("antigravity", "Antigravity App", "Antigravity", "Antigravity.exe", "https://antigravity.google/"),
        new("antigravityIDE", "Antigravity IDE", "Antigravity IDE", "Antigravity IDE.exe", "https://antigravity.google/")
    ];
    public static TargetApp Get(string id) => All.FirstOrDefault(a => a.Id == id) ?? throw new InvalidDataException("InvalidSettings");
}
public sealed record AppProfile(string Host = "127.0.0.1", string Port = "7890", string ApplicationPath = "");
