using System.Net;

namespace LocalRouteLauncher;
public sealed record ProbeResult(bool Success, string Detail);
public static class ProxyProbe
{
    public static async Task<ProbeResult> Check(ProxyEndpoint endpoint, CancellationToken cancellation = default)
    {
        using var handler = new HttpClientHandler
        {
            Proxy = new WebProxy(endpoint.Url) { BypassProxyOnLocal = false },
            UseProxy = true, AllowAutoRedirect = false, UseCookies = false
        };
        using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(12) };
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Head, "https://chatgpt.com/");
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellation);
            return new(true, $"HTTP {(int)response.StatusCode}");
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        { return new(false, ex is TaskCanceledException ? "Timeout" : "ConnectionFailed"); }
    }
}
