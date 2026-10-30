using LocalRouteLauncher;
using System.Net;

int assertions = 0;
void Check(bool ok, string message) { assertions++; if (!ok) throw new Exception(message); }
void Reject(Action action, string message) { try { action(); } catch (Exception e) when (e is ArgumentException or System.Text.Json.JsonException or InvalidDataException) { assertions++; return; } throw new Exception(message); }
string ReleaseJson(string tag, bool draft = false, bool prerelease = false, string? url = null) => System.Text.Json.JsonSerializer.Serialize(new { tag_name = tag, draft, prerelease, html_url = url ?? ReleaseUpdate.Repository + "/releases/tag/" + tag });
Check(ReleaseUpdate.Parse(ReleaseJson("v1.10.0"), "1.9.9").IsNewer, "Numeric version ordering");
Check(!ReleaseUpdate.Parse(ReleaseJson("v1.4.0"), "1.4.0").IsNewer, "Equal version");
Check(!ReleaseUpdate.Parse(ReleaseJson("v1.3.0"), "1.4.0").IsNewer, "Do not offer downgrade");
foreach (var tag in new[] { "1.4", "1.04.0", "1.4.1-beta", "1.4.1+build", "１.4.1", "1.2.3.4", "1.2.999999999999999999" }) Reject(() => ReleaseUpdate.StableVersion(tag), "Invalid stable version accepted");
Reject(() => ReleaseUpdate.Parse(ReleaseJson("v1.4.1", draft: true), "1.4.0"), "Draft accepted");
Reject(() => ReleaseUpdate.Parse(ReleaseJson("v1.4.1", prerelease: true), "1.4.0"), "Prerelease accepted");
Reject(() => ReleaseUpdate.Parse(ReleaseJson("v1.4.1", url: "https://example.com"), "1.4.0"), "External download accepted");
Check(new Settings().CheckUpdatesAtStartup, "Startup check default");
var endpoint = new ProxyEndpoint(" 127.0.0.1 ", " 7890 ");
Check(endpoint.Url == "http://127.0.0.1:7890", "IPv4 normalization");
Check(new ProxyEndpoint("[::1]", "1").Url == "http://[::1]:1", "IPv6 brackets");
Check(new ProxyEndpoint("LOCALHOST", "65535").Host == "localhost", "Case normalization");
foreach (var host in new[] { "", "https://example.com", "user:pass@host", "a/b", "a b", "a\n--no-proxy-server", "a&b", "-host", "a..b", "::1%3" }) Reject(() => new ProxyEndpoint(host, "7890"), "Accepted malformed host");
foreach (var port in new[] { "", "0", "65536", "1;exit", "12.3", "-1", "１２", "99999999999999" }) Reject(() => new ProxyEndpoint("localhost", port), "Accepted malformed port");
Check(endpoint.MatchesArguments(endpoint.Arguments), "Proxy flag missing");
Check(!endpoint.MatchesArguments(endpoint.Arguments.Append("--proxy-server=http://evil:80")), "Duplicate proxy accepted");
Check(!endpoint.MatchesArguments(endpoint.Arguments.Append("--no-proxy-server")), "Direct flag accepted");
Check(!endpoint.MatchesArguments(["--proxy-server=http://127.0.0.1:78900"]), "Substring proxy match");
Check(endpoint.Environment["http_proxy"] == endpoint.Url && endpoint.Environment.Count == 5, "Windows env case handling");
Check(endpoint.Matches(IPAddress.Loopback, 7890) && !endpoint.Matches(IPAddress.Loopback, 7891), "TCP endpoint match");
Check(new ProxyEndpoint("localhost", "7890").Matches(IPAddress.IPv6Loopback, 7890), "IPv6 localhost match");
ProcessRow[] rows = [new(10, 0, "target", ""), new(11, 10, "target", ""), new(13, 12, "helper", ""), new(12, 11, "helper", ""), new(20, 0, "other", ""), new(21, 20, "other", "")];
Check(ProcessFamily.Collect([10], rows).SetEquals([10, 11, 12, 13]), "Process-family isolation");
Check(ProcessFamily.Collect([], rows).Count == 0, "No root should not match PID 0 descendants");
Check(AppLanguages.Codes.Length == 9 && AppLanguages.Codes.Distinct().Count() == 9, "Nine distinct interface languages");
Check(AppLanguages.Resolve("zh-Hant-HK") == "zh-TW" && AppLanguages.Resolve("zh-CN") == "zh-CN", "Chinese script fallback");
Check(AppLanguages.Resolve("zh-Hans-HK") == "zh-CN", "Explicit Simplified script overrides region");
Check(AppLanguages.Resolve("zh-Hant-CN") == "zh-TW", "Explicit Traditional script overrides region");
Check(AppLanguages.Resolve("zh_Hans_TW") == "zh-CN", "Underscore locale identifiers");
Check(AppLanguages.Resolve("fa-IR") == "fa" && AppLanguages.Resolve("ar-SA") == "ar", "RTL system languages");
Check(AppLanguages.IsRightToLeft("fa") && AppLanguages.IsRightToLeft("ar") && !AppLanguages.IsRightToLeft("en"), "RTL directions");
var folder = Path.Combine(Path.GetTempPath(), "lrl-core-" + Guid.NewGuid().ToString("N")); Directory.CreateDirectory(folder);
try
{
    var file = Path.Combine(folder, "settings.json"); var settings = new Settings { Language = "en", Theme = "dark", ApplicationPath = "C:\\Example Folder\\ChatGPT.exe" }; settings.Save(file);
    Check(Settings.Load(file) == settings, "Round-trip settings");
    settings = settings with { CheckUpdatesAtStartup = false }; settings.Save(file); Check(!Settings.Load(file).CheckUpdatesAtStartup, "Persist update opt-out");
    settings = settings with { Language = "zh-CN" }; settings.Save(file); Check(Settings.Load(file).Language == "zh-CN", "Atomic replace");
    foreach (var language in AppLanguages.Codes)
    {
        settings = settings with { Language = language }; settings.Save(file);
        Check(Settings.Load(file).Language == language, "Language setting round trip: " + language);
    }
    File.WriteAllText(file, "{\"Host\":null}"); Reject(() => Settings.Load(file), "Null host accepted");
    File.WriteAllText(file, "{broken"); Reject(() => Settings.Load(file), "Corrupt settings accepted");
    File.WriteAllText(file, "{\"Language\":\"unknown\"}"); Reject(() => Settings.Load(file), "Unknown language accepted");
    var legacy = new Settings { Host = "localhost", Port = "8080", ApplicationPath = "ChatGPT.exe" };
    var app = legacy.Select("antigravity");
    Check(app.Host == "127.0.0.1" && app.Port == "7890" && app.ApplicationPath == "", "Fresh target defaults independent of legacy");
    app = app with { Port = "7891", ApplicationPath = "Antigravity.exe" };
    var ide = app.Select("antigravityIDE") with { Port = "7892" };
    var back = ide.Select("chatgpt");
    Check(back.Host == legacy.Host && back.Port == "8080" && back.ApplicationPath == "ChatGPT.exe", "Legacy target retained");
    Check(back.Select("antigravity").Port == "7891" && back.Select("antigravityIDE").Port == "7892", "Per-target profiles preserved");
    back.Save(file);
    var loaded = Settings.Load(file);
    Check(loaded.Select("antigravity").Port == "7891", "Profile serialization round trip");
    Check(loaded.Language == "system" && AppLanguages.Codes.Contains(loaded.ResolvedLanguage), "System language resolves to supported language");
    Check(TargetApp.Get("antigravityIDE").ProbeUrl != TargetApp.Get("chatgpt").ProbeUrl, "Independent probe targets");
    Reject(() => back.Select("unknown"), "Unknown target accepted");
    File.WriteAllText(file, "{\"Profiles\":{\"antigravity\":{\"Port\":\"0\"}}}"); Reject(() => Settings.Load(file), "Invalid profile accepted");
    Check(Directory.GetFiles(folder).Length == 1, "Temporary settings leaked");
}
finally { Directory.Delete(folder, true); }
Console.WriteLine($"PASS: {assertions} core assertions.");
