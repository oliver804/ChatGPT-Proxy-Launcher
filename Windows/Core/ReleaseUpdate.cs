using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace LocalRouteLauncher;

public sealed record ReleaseUpdate(string Version, string Url, bool IsNewer, string? DownloadUrl = null)
{
    public string? AvailableDownload => IsNewer ? DownloadUrl : null;
    public const string Repository = "https://github.com/oliver804/Local-Route-Launcher";
    public const string ReleasesUrl = Repository + "/releases";
    public const string ApiUrl = "https://api.github.com/repos/oliver804/Local-Route-Launcher/releases/latest";
    public static Version StableVersion(string text)
    {
        var value = text.StartsWith('v') ? text[1..] : text;
        if (!Regex.IsMatch(value, @"\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\z") || !System.Version.TryParse(value, out var version))
            throw new InvalidDataException("Invalid release version");
        return version;
    }
    public static ReleaseUpdate Parse(string json, string current)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        var tag = root.GetProperty("tag_name").GetString() ?? "";
        var url = root.GetProperty("html_url").GetString() ?? "";
        if (root.GetProperty("draft").GetBoolean() || root.GetProperty("prerelease").GetBoolean() || url != Repository + "/releases/tag/" + tag)
            throw new InvalidDataException("Invalid stable release");
        var latest = StableVersion(tag);
        var name = $"Local-Route-Launcher-{latest}-windows-x64-setup.exe";
        var expected = Repository + "/releases/download/" + tag + "/" + name;
        string? download = null;
        if (root.TryGetProperty("assets", out var assets) && assets.ValueKind == JsonValueKind.Array)
            foreach (var asset in assets.EnumerateArray())
                if (asset.GetProperty("name").GetString() == name && asset.GetProperty("browser_download_url").GetString() == expected) download = expected;
        return new(tag, url, latest > StableVersion(current), download);
    }
    public static async Task<ReleaseUpdate> Fetch(string current, CancellationToken cancellationToken)
    {
        using var handler = new HttpClientHandler { UseCookies = false };
        using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(20), MaxResponseContentBufferSize = 1_048_576 };
        client.DefaultRequestHeaders.UserAgent.ParseAdd("Local-Route-Launcher/" + current);
        client.DefaultRequestHeaders.Accept.ParseAdd("application/vnd.github+json");
        using var response = await client.GetAsync(ApiUrl, cancellationToken);
        if (response.StatusCode != HttpStatusCode.OK) throw new HttpRequestException("Update check failed");
        return Parse(await response.Content.ReadAsStringAsync(cancellationToken), current);
    }
}
