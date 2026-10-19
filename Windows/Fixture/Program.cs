using System.IO;
using System.Net.Sockets;
using System.Text.Json;
using System.Windows;

internal static class Program
{
    [STAThread] private static int Main(string[] args)
    {
        var path = Environment.GetEnvironmentVariable("LRL_FIXTURE_REPORT") ?? throw new InvalidOperationException("Missing test report path");
        var host = Environment.GetEnvironmentVariable("HTTP_PROXY") ?? "";
        var endpoint = new Uri(host);
        using var tcp = new TcpClient(); tcp.Connect(endpoint.Host, endpoint.Port);
        File.WriteAllText(path, JsonSerializer.Serialize(new { Arguments = args, Proxy = host, HttpsProxy = Environment.GetEnvironmentVariable("HTTPS_PROXY"), AllProxy = Environment.GetEnvironmentVariable("ALL_PROXY"), NoProxy = Environment.GetEnvironmentVariable("NO_PROXY"), NodeProxy = Environment.GetEnvironmentVariable("NODE_USE_ENV_PROXY"), Pid = Environment.ProcessId }));
        var app = new Application();
        return app.Run(new Window { Title = "Local Route Launcher integration fixture", Width = 400, Height = 160, Content = "Test fixture — not ChatGPT" });
    }
}
