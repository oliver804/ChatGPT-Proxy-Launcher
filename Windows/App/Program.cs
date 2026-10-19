using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Media.Imaging;

namespace LocalRouteLauncher;

public static class Program
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern IntPtr FindWindow(string? className, string title);
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr window, uint message, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr window);
    [STAThread]
    public static int Main(string[] args)
    {
        if (args.Length == 3 && args[0] == "--integration-test")
        {
            try { Integration.Run(args[1], args[2]).GetAwaiter().GetResult(); return 0; }
            catch (Exception ex) { File.WriteAllText(args[2], ex.ToString()); return 1; }
        }
        using var mutex = new Mutex(true, "Local\\LocalRouteLauncher", out var first);
        if (!first)
        {
            var window = FindWindow(null, "Local Route Launcher");
            if (window != IntPtr.Zero) { PostMessage(window, 0x8001, IntPtr.Zero, IntPtr.Zero); SetForegroundWindow(window); }
            return 0;
        }
        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        bool smoke = args.Length == 2 && args[0] == "--smoke-test";
        var windowApp = new MainWindow(smoke);
        app.MainWindow = windowApp;
        windowApp.Show();
        if (smoke)
        {
            windowApp.Dispatcher.BeginInvoke(async () =>
            {
                try
                {
                    Directory.CreateDirectory(args[1]);
                    foreach (var language in new[] { "en", "zh-CN" })
                    foreach (var theme in new[] { "light", "dark" })
                    {
                        windowApp.Preview(language, theme);
                        await Task.Delay(150);
                        windowApp.UpdateLayout();
                        var bitmap = new RenderTargetBitmap((int)windowApp.ActualWidth, (int)windowApp.ActualHeight, 96, 96, System.Windows.Media.PixelFormats.Pbgra32);
                        bitmap.Render(windowApp);
                        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
                        using var file = File.Create(Path.Combine(args[1], $"windows-{language}-{theme}.png")); encoder.Save(file);
                    }
                    windowApp.Close();
                    if (windowApp.IsVisible || windowApp.ShowInTaskbar) throw new InvalidOperationException("Close did not hide the window from the taskbar.");
                    windowApp.Reveal();
                    if (!windowApp.IsVisible || !windowApp.ShowInTaskbar) throw new InvalidOperationException("Reopen failed.");
                    File.WriteAllText(Path.Combine(args[1], "ui-result.txt"), "PASS: four localized theme renders; close-to-tray; reopen.");
                    windowApp.Quit();
                }
                catch (Exception ex) { File.WriteAllText(Path.Combine(args[1], "ui-failure.txt"), ex.ToString()); app.Shutdown(1); }
            });
        }
        return app.Run();
    }
    public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "1.2.0";
}
