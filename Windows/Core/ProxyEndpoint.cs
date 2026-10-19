using System.Net;
using System.Net.Sockets;
using System.Globalization;

namespace LocalRouteLauncher;

public sealed record ProxyEndpoint
{
    public string Host { get; }
    public int Port { get; }
    public string Authority => Host.Contains(':') ? $"[{Host}]:{Port}" : $"{Host}:{Port}";
    public string Url => "http://" + Authority;
    public ProxyEndpoint(string host, string port)
    {
        host = host.Trim();
        if (host.StartsWith('[') && host.EndsWith(']')) host = host[1..^1];
        var ipv6 = IPAddress.TryParse(host, out var ip) && ip.AddressFamily == AddressFamily.InterNetworkV6 && !host.Contains('%');
        var hostname = host.Length is > 0 and <= 253 && host.Split('.').All(label =>
            label.Length is > 0 and <= 63 && label[0] != '-' && label[^1] != '-' &&
            label.All(c => char.IsAsciiLetterOrDigit(c) || c == '-'));
        if (!ipv6 && !hostname) throw new ArgumentException("InvalidHost");
        port = port.Trim();
        if (port.Length == 0 || !port.All(char.IsAsciiDigit) ||
            !int.TryParse(port, NumberStyles.None, CultureInfo.InvariantCulture, out var number) || number is < 1 or > 65535)
            throw new ArgumentException("InvalidPort");
        Host = host.ToLowerInvariant(); Port = number;
    }
    public string[] Arguments => [$"--proxy-server={Url}", "--proxy-bypass-list=localhost;127.0.0.1;[::1]", "--disable-quic"];
    // Windows environment names are case-insensitive; never insert duplicate upper/lowercase keys.
    public Dictionary<string, string> Environment => new(StringComparer.OrdinalIgnoreCase)
    {
        ["HTTP_PROXY"] = Url, ["HTTPS_PROXY"] = Url, ["ALL_PROXY"] = Url,
        ["NO_PROXY"] = "localhost,127.0.0.1,::1", ["NODE_USE_ENV_PROXY"] = "1"
    };
    public bool Matches(IPAddress address, int port) => port == Port &&
        (Host == "localhost" ? IPAddress.IsLoopback(address) : IPAddress.TryParse(Host, out var ip) && ip.Equals(address));
    public bool MatchesArguments(IEnumerable<string> arguments)
    {
        var a = arguments.ToArray();
        return a.Count(x => x.StartsWith("--proxy-server=", StringComparison.Ordinal)) == 1 &&
               a.Contains($"--proxy-server={Url}") && !a.Contains("--no-proxy-server");
    }
}
