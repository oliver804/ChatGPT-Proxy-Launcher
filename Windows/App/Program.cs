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
        if (args.Length is 3 or 4 && args[0] == "--integration-test")
        {
            try { Integration.Run(args[1], args[2], args.Length == 4 ? args[3] : "chatgpt").GetAwaiter().GetResult(); return 0; }
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
                    foreach (var language in AppLanguages.Codes)
                    foreach (var theme in new[] { "light", "dark" })
                    {
                        windowApp.Preview(language, theme);
                        await Task.Delay(150);
                        windowApp.UpdateLayout();
                        Capture(windowApp, Path.Combine(args[1], $"windows-{language}-{theme}.png"), AppLanguages.IsRightToLeft(language));
                        windowApp.VerifyAuxiliaryPanels(args[1], language, theme);
                    }
                    windowApp.VerifyProfiles();
                    await windowApp.VerifyBusyControls();
                    windowApp.Close();
                    if (windowApp.IsVisible || windowApp.ShowInTaskbar) throw new InvalidOperationException("Close did not hide the window from the taskbar.");
                    windowApp.Reveal();
                    if (!windowApp.IsVisible || !windowApp.ShowInTaskbar) throw new InvalidOperationException("Reopen failed.");
                    File.WriteAllText(Path.Combine(args[1], "ui-result.txt"), "PASS: localized main/tray renders; update badge visibility and installer selection; busy controls; preference guards; draft preservation; close-to-tray; reopen.");
                    windowApp.Quit();
                }
                catch (Exception ex) { File.WriteAllText(Path.Combine(args[1], "ui-failure.txt"), ex.ToString()); app.Shutdown(1); }
            });
        }
        return app.Run();
    }
    internal static void Capture(Window window, string path, bool rtl)
    {
        var content = (FrameworkElement)window.Content;
        content.Measure(new Size(window.ActualWidth, double.PositiveInfinity));
        content.Arrange(new Rect(content.DesiredSize)); content.UpdateLayout();
        var width = (int)Math.Ceiling(content.ActualWidth) + 40;
        var height = (int)Math.Ceiling(content.ActualHeight) + 40;
        var visual = new System.Windows.Media.DrawingVisual();
        using (var drawing = visual.RenderOpen()) {
            if (rtl) drawing.PushTransform(new System.Windows.Media.ScaleTransform(-1, 1, width / 2.0, 0));
            drawing.DrawRectangle(window.Background, null, new Rect(0, 0, width, height));
            drawing.DrawRectangle(new System.Windows.Media.VisualBrush(content), null, new Rect(20, 20, content.ActualWidth, content.ActualHeight));
        }
        var bitmap = new RenderTargetBitmap(width, height, 96, 96, System.Windows.Media.PixelFormats.Pbgra32); bitmap.Render(visual);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
        using var file = File.Create(path); encoder.Save(file);
        content.InvalidateMeasure();
    }
    public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "1.4.0";
}
