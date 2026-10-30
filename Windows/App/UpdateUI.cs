using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Automation;

namespace LocalRouteLauncher;

public sealed partial class MainWindow
{
    private ReleaseUpdate? updateRelease;
    private bool updateChecking;
    private readonly CancellationTokenSource updateCancellation = new();
    private Window? trayWindow;
    private readonly List<Button> updateButtons = [];
    private void SetLanguage(string value) { if (busy || rebuilding) return; settings = settings with { Language = value }; SavePreferences(); }
    private void SetTheme(string value) { if (busy || rebuilding) return; settings = settings with { Theme = value }; SavePreferences(); }
    private StackPanel Toolbar()
    {
        var bar = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, IsEnabled = !busy };
        bar.Children.Add(IconMenu("languages", T("Language"), () => new[] { "system" }.Concat(AppLanguages.Codes).Select(code =>
            (code == "system" ? T("System") : AppLanguages.Labels[Array.IndexOf(AppLanguages.Codes, code)], code == settings.Language, (Action)(() => SetLanguage(code))))));
        bar.Children.Add(IconMenu("sun-moon", T("Appearance"), () => new[] { "system", "light", "dark" }.Select(mode =>
            (T(mode == "system" ? "System" : mode == "light" ? "Light" : "Dark"), mode == settings.Theme, (Action)(() => SetTheme(mode))))));
        bar.Children.Add(RepositoryButton());
        return bar;
    }
    private Button IconMenu(string glyph, string title, Func<IEnumerable<(string Label, bool Selected, Action Action)>> choices)
    {
        var button = new Button { Style = roundedButtonStyle, Content = HeaderIcon(glyph),
            ToolTip = title, Foreground = muted, Background = Brushes.Transparent, BorderThickness = new Thickness(0), Padding = new Thickness(0), Width = 32, Height = 32, Margin = new Thickness(0, 0, 4, 0) };
        AutomationProperties.SetName(button, title);
        button.Click += (_, _) => {
            var menu = new ContextMenu { PlacementTarget = button, FlowDirection = FlowDirection, Background = card, Foreground = ink };
            foreach (var choice in choices()) { var item = new MenuItem { Header = choice.Label, IsCheckable = true, IsChecked = choice.Selected }; item.Click += (_, _) => { choice.Action(); RefreshAuxiliaryWindows(); }; menu.Items.Add(item); }
            button.ContextMenu = menu; menu.IsOpen = true;
        };
        return button;
    }
    // Lucide languages / sun-moon, ISC. Same vectors, size and hit target as macOS.
    private FrameworkElement HeaderIcon(string name)
    {
        var data = name == "languages" ? "M5 8L11 14 M4 14L10 8 12 5 M2 5H14 M7 2H8 M22 22L17 12 12 22 M14 18H20" :
            "M12 2V4 M14.837 16.385a6 6 0 1 1-7.223-7.222c.624-.147.97.66.715 1.248a4 4 0 0 0 5.26 5.259c.589-.255 1.396.09 1.248.715 M16 12a4 4 0 0 0-4-4 M19 5l-1.256 1.256 M20 12h2";
        var canvas = new Canvas { Width = 24, Height = 24 };
        canvas.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse(data), Stroke = muted, StrokeThickness = 2,
            StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round, StrokeLineJoin = PenLineJoin.Round });
        return new Viewbox { Width = 17, Height = 17, Child = canvas };
    }
    private bool UpdateAvailable => updateRelease?.AvailableDownload != null;
    private Button UpdateButton()
    {
        var label = new StackPanel { Orientation = Orientation.Horizontal };
        var glyph = new Canvas { Width = 24, Height = 24 };
        glyph.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M12 16V8 M8 12l4-4 4 4 M22 12A10 10 0 1 1 2 12A10 10 0 1 1 22 12"),
            Stroke = accent, StrokeThickness = 2, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round, StrokeLineJoin = PenLineJoin.Round });
        label.Children.Add(new Viewbox { Width = 12, Height = 12, Child = glyph, Margin = new Thickness(0, 0, 4, 0) });
        label.Children.Add(new TextBlock { Text = T("UpdateAvailable") });
        var button = new Button { Style = roundedButtonStyle, Content = label, ToolTip = T("UpdateAvailable"), Foreground = accent, Background = field, BorderThickness = new Thickness(0),
            FontSize = 10, Padding = new Thickness(6, 4, 6, 4), Margin = new Thickness(6, 0, 0, 0), Visibility = UpdateAvailable ? Visibility.Visible : Visibility.Collapsed };
        AutomationProperties.SetName(button, T("UpdateAvailable"));
        button.Click += (_, _) => DownloadUpdate();
        updateButtons.RemoveAll(b => !b.IsLoaded);
        updateButtons.Add(button); return button;
    }
    private async Task CheckUpdates()
    {
        if (updateChecking || smoke) return;
        updateChecking = true; RefreshUpdateUI();
        try { updateRelease = await ReleaseUpdate.Fetch(Program.Version, updateCancellation.Token); }
        catch (OperationCanceledException) when (updateCancellation.IsCancellationRequested) { return; }
        catch { updateRelease = null; }
        finally { updateChecking = false; if (!quitting) RefreshUpdateUI(); }
    }
    private void RefreshUpdateUI()
    {
        foreach (var button in updateButtons) button.Visibility = UpdateAvailable ? Visibility.Visible : Visibility.Collapsed;
        SetupTray();
    }
    private void DownloadUpdate()
    {
        if (updateRelease?.AvailableDownload is not string url) return;
        try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url) { UseShellExecute = true }); }
        catch { MessageBox.Show(T("OperationFailed"), "Local Route Launcher"); }
    }
    private Button AuxiliaryButton(string label, Action action)
    {
        var button = new Button { Style = roundedButtonStyle, Content = label, Padding = new Thickness(10, 7, 10, 7), Margin = new Thickness(0, 4, 8, 4), Background = field, Foreground = accent, BorderThickness = new Thickness(0) };
        button.Click += (_, _) => action(); return button;
    }
    private void RefreshAuxiliaryWindows()
    {
        if (trayWindow?.IsVisible == true) PopulateTrayPanel();
    }
    internal void VerifyAuxiliaryPanels(string output, string language, string theme)
    {
        if (!smoke) throw new InvalidOperationException("Smoke mode required");
        if (Toolbar().Children.Count != 3) throw new InvalidOperationException("Toolbar must contain three icons");
        if (UpdateButton().Visibility != Visibility.Collapsed) throw new InvalidOperationException("Idle update button must be hidden");
        ShowTrayPanel(); trayWindow!.UpdateLayout();
        if (trayWindow.ActualWidth != 380) throw new InvalidOperationException("Tray width must follow mockup");
        Program.Capture(trayWindow, System.IO.Path.Combine(output, $"tray-{language}-{theme}.png"), AppLanguages.IsRightToLeft(language));
        trayWindow.Hide();
        updateRelease = new ReleaseUpdate("v99.0.0", ReleaseUpdate.ReleasesUrl, true);
        if (UpdateButton().Visibility != Visibility.Collapsed) throw new InvalidOperationException("Release without installer must stay hidden");
        updateRelease = updateRelease with { DownloadUrl = ReleaseUpdate.Repository + "/releases/download/v99.0.0/Local-Route-Launcher-99.0.0-windows-x64-setup.exe" };
        if (UpdateButton().Visibility != Visibility.Visible) throw new InvalidOperationException("Downloadable update badge missing");
        updateRelease = null;
        updateChecking = true;
        if (UpdateButton().Visibility != Visibility.Collapsed) throw new InvalidOperationException("Checking must stay quiet");
        updateChecking = false;
    }
    private void ShowTrayPanel()
    {
        if (trayWindow?.IsVisible == true) { trayWindow.Hide(); return; }
        if (trayWindow == null) {
            trayWindow = new Window { Width = 380, SizeToContent = SizeToContent.Height, WindowStyle = WindowStyle.None, ResizeMode = ResizeMode.NoResize,
                ShowInTaskbar = false, Topmost = true, Icon = Icon };
            trayWindow.Deactivated += (_, _) => { if (!quitting && trayWindow?.IsVisible == true && !trayWindow.IsKeyboardFocusWithin) trayWindow.Hide(); };
        }
        PopulateTrayPanel(); trayWindow.Show(); trayWindow.UpdateLayout();
        var area = SystemParameters.WorkArea;
        trayWindow.Left = area.Right - trayWindow.ActualWidth - 12; trayWindow.Top = area.Bottom - trayWindow.ActualHeight - 12; trayWindow.Activate();
    }
    private void PopulateTrayPanel()
    {
        if (trayWindow == null) return;
        trayWindow.Background = background; trayWindow.Foreground = ink; trayWindow.FlowDirection = FlowDirection;
        var body = new StackPanel { Margin = new Thickness(20, 18, 20, 14) };
        var header = new DockPanel(); var tools = Toolbar(); DockPanel.SetDock(tools, Dock.Right); header.Children.Add(tools);
        var brand = new StackPanel { Orientation = Orientation.Horizontal };
        brand.Children.Add(new Image { Source = Icon, Width = 30, Height = 30, Margin = new Thickness(0, 0, 8, 0) });
        brand.Children.Add(Text("Local Route\nLauncher", 12, true)); header.Children.Add(brand); body.Children.Add(header);
        foreach (var target in TargetApp.All) {
            body.Children.Add(new Separator { Margin = new Thickness(0, 14, 0, 12), Background = muted });
            var row = new DockPanel(); var right = new StackPanel { HorizontalAlignment = HorizontalAlignment.Right }; DockPanel.SetDock(right, Dock.Right); row.Children.Add(right);
            right.Children.Add(Text(T(Running(target.Id) ? "Running" : "NotRunning"), 11, false, Running(target.Id) ? accent : muted));
            var action = AuxiliaryButton(Strings.Get(Running(target.Id) ? "Stop" : "Launch", settings.ResolvedLanguage).Replace("ChatGPT", target.Name), async () => {
                if (busy) return; var wasRunning = Running(target.Id); SelectApp(target.Id);
                await Work(async () => { if (wasRunning) { RequireApp(); await WindowsPlatform.Stop(settings.ApplicationPath); } else await LaunchCurrent(); }, wasRunning ? "Stopped" : "Launched");
                RefreshAuxiliaryWindows();
            }); action.IsEnabled = !busy; action.MaxWidth = 180; right.Children.Add(action);
            var left = new StackPanel(); left.Children.Add(Text(target.Name, 13, true));
            var endpoint = Text(Route(target.Id, Profile(target.Id)), 11, false, muted); endpoint.FlowDirection = FlowDirection.LeftToRight; left.Children.Add(endpoint); row.Children.Add(left); body.Children.Add(row);
        }
        body.Children.Add(new Separator { Margin = new Thickness(0, 12, 0, 12) });
        var footer = new WrapPanel(); footer.Children.Add(Text("v" + Program.Version, 10, false, muted)); footer.Children.Add(UpdateButton());
        footer.Children.Add(AuxiliaryButton(T("Show"), () => { trayWindow.Hide(); Reveal(); }));
        footer.Children.Add(AuxiliaryButton(T("Quit"), () => { if (!busy) Quit(); })); body.Children.Add(footer);
        if (notice != "Ready") body.Children.Add(Text(T(notice), 11, false, muted));
        trayWindow.Content = new Border { BorderBrush = muted, BorderThickness = new Thickness(1), Child = body };
    }
}
