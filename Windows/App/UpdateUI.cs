using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Automation;

namespace LocalRouteLauncher;

public sealed partial class MainWindow
{
    private ReleaseUpdate? updateRelease;
    private bool updateChecking, updateFailed;
    private readonly CancellationTokenSource updateCancellation = new();
    private Window? updateWindow, trayWindow;
    private readonly List<Button> updateButtons = [];
    private void SetLanguage(string value) { if (busy || rebuilding) return; settings = settings with { Language = value }; SavePreferences(); }
    private void SetTheme(string value) { if (busy || rebuilding) return; settings = settings with { Theme = value }; SavePreferences(); }
    private StackPanel Toolbar()
    {
        var bar = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, IsEnabled = !busy };
        bar.Children.Add(IconMenu("\uE774", T("Language"), () => new[] { "system" }.Concat(AppLanguages.Codes).Select(code =>
            (code == "system" ? T("System") : AppLanguages.Labels[Array.IndexOf(AppLanguages.Codes, code)], code == settings.Language, (Action)(() => SetLanguage(code))))));
        bar.Children.Add(IconMenu("\uE706", T("Appearance"), () => new[] { "system", "light", "dark" }.Select(mode =>
            (T(mode == "system" ? "System" : mode == "light" ? "Light" : "Dark"), mode == settings.Theme, (Action)(() => SetTheme(mode))))));
        bar.Children.Add(RepositoryButton());
        return bar;
    }
    private Button IconMenu(string glyph, string title, Func<IEnumerable<(string Label, bool Selected, Action Action)>> choices)
    {
        var button = new Button { Style = roundedButtonStyle, Content = new TextBlock { Text = glyph, FontFamily = new FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets"), FontSize = 16 },
            ToolTip = title, Foreground = muted, Background = Brushes.Transparent, BorderThickness = new Thickness(0), Padding = new Thickness(8), MinWidth = 32 };
        AutomationProperties.SetName(button, title);
        button.Click += (_, _) => {
            var menu = new ContextMenu { PlacementTarget = button, FlowDirection = FlowDirection, Background = card, Foreground = ink };
            foreach (var choice in choices()) { var item = new MenuItem { Header = choice.Label, IsCheckable = true, IsChecked = choice.Selected }; item.Click += (_, _) => { choice.Action(); RefreshAuxiliaryWindows(); }; menu.Items.Add(item); }
            button.ContextMenu = menu; menu.IsOpen = true;
        };
        return button;
    }
    private string UpdateLabel => T(updateChecking ? "UpdateChecking" : updateFailed ? "UpdateFailed" : updateRelease?.IsNewer == true ? "UpdateAvailable" : "CheckUpdates");
    private Button UpdateButton()
    {
        var button = new Button { Style = roundedButtonStyle, Content = UpdateLabel, ToolTip = UpdateLabel, Foreground = accent, Background = field, BorderThickness = new Thickness(0),
            FontSize = 10, Padding = new Thickness(6, 4, 6, 4), Margin = new Thickness(6, 0, 0, 0), MaxWidth = 125 };
        AutomationProperties.SetName(button, UpdateLabel);
        button.Click += (_, _) => ShowUpdates();
        updateButtons.RemoveAll(b => !b.IsLoaded);
        updateButtons.Add(button); return button;
    }
    private async Task CheckUpdates()
    {
        if (updateChecking || smoke) return;
        updateChecking = true; updateFailed = false; RefreshUpdateUI();
        try { updateRelease = await ReleaseUpdate.Fetch(Program.Version, updateCancellation.Token); }
        catch (OperationCanceledException) when (updateCancellation.IsCancellationRequested) { return; }
        catch { updateRelease = null; updateFailed = true; }
        finally { updateChecking = false; if (!quitting) RefreshUpdateUI(); }
    }
    private void RefreshUpdateUI()
    {
        foreach (var button in updateButtons) { button.Content = UpdateLabel; button.ToolTip = UpdateLabel; AutomationProperties.SetName(button, UpdateLabel); }
        if (updateWindow != null) PopulateUpdateWindow();
        SetupTray();
    }
    private void OpenRelease()
    {
        try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(updateRelease?.Url ?? ReleaseUpdate.ReleasesUrl) { UseShellExecute = true }); }
        catch { updateFailed = true; RefreshUpdateUI(); }
    }
    private Button AuxiliaryButton(string label, Action action)
    {
        var button = new Button { Style = roundedButtonStyle, Content = label, Padding = new Thickness(10, 7, 10, 7), Margin = new Thickness(0, 4, 8, 4), Background = field, Foreground = accent, BorderThickness = new Thickness(0) };
        button.Click += (_, _) => action(); return button;
    }
    private void ShowUpdates()
    {
        trayWindow?.Hide();
        if (updateWindow == null) {
            updateWindow = new Window { Title = "Local Route Launcher", Width = 410, SizeToContent = SizeToContent.Height, ResizeMode = ResizeMode.NoResize, ShowInTaskbar = false,
                WindowStartupLocation = WindowStartupLocation.CenterScreen, Icon = Icon };
            updateWindow.Closed += (_, _) => updateWindow = null;
        }
        PopulateUpdateWindow(); updateWindow.Show(); updateWindow.Activate();
    }
    private void PopulateUpdateWindow()
    {
        if (updateWindow == null) return;
        updateWindow.Background = background; updateWindow.Foreground = ink; updateWindow.FlowDirection = FlowDirection;
        var body = new StackPanel { Margin = new Thickness(22) };
        body.Children.Add(Text(T(updateChecking ? "UpdateChecking" : updateFailed ? "UpdateFailed" : updateRelease == null ? "CheckUpdates" : updateRelease.IsNewer ? "UpdateFound" : "UpdateLatest"), 19, true));
        body.Children.Add(Text("Local Route Launcher", 12, false, muted));
        body.Children.Add(Text(T("UpdateCurrent") + " · v" + Program.Version, 13));
        if (updateRelease != null) body.Children.Add(Text(T("UpdateStable") + " · " + updateRelease.Version, 13, false, accent));
        var auto = new CheckBox { Content = T("UpdateAutomatic"), IsChecked = settings.CheckUpdatesAtStartup, Foreground = ink, Margin = new Thickness(0, 18, 0, 12) };
        auto.Click += (_, _) => {
            var previous = settings; settings = settings with { CheckUpdatesAtStartup = auto.IsChecked == true };
            try { if (!smoke) settings.Save(); }
            catch { settings = previous; auto.IsChecked = previous.CheckUpdatesAtStartup; MessageBox.Show(updateWindow, T("OperationFailed")); }
        };
        body.Children.Add(auto); body.Children.Add(Text(T("UpdatePrivacy"), 12, false, muted));
        if (updateFailed) body.Children.Add(Text(T("UpdateOffline"), 12, false, muted));
        var check = AuxiliaryButton(T(updateFailed ? "UpdateRetry" : "CheckUpdates"), async () => await CheckUpdates()); check.IsEnabled = !updateChecking;
        body.Children.Add(check); body.Children.Add(AuxiliaryButton(T(updateRelease?.IsNewer == true ? "UpdateDownload" : "UpdatePage"), OpenRelease));
        updateWindow.Content = body;
    }
    private void RefreshAuxiliaryWindows()
    {
        if (updateWindow != null) PopulateUpdateWindow();
        if (trayWindow?.IsVisible == true) PopulateTrayPanel();
    }
    internal void VerifyAuxiliaryPanels(string output, string language, string theme)
    {
        if (!smoke) throw new InvalidOperationException("Smoke mode required");
        if (Toolbar().Children.Count != 3) throw new InvalidOperationException("Toolbar must contain three icons");
        ShowTrayPanel(); trayWindow!.UpdateLayout();
        Program.Capture(trayWindow, System.IO.Path.Combine(output, $"tray-{language}-{theme}.png"), AppLanguages.IsRightToLeft(language));
        trayWindow.Hide();
        ShowUpdates(); updateWindow!.UpdateLayout();
        Program.Capture(updateWindow, System.IO.Path.Combine(output, $"updates-{language}-{theme}.png"), AppLanguages.IsRightToLeft(language));
        updateRelease = new ReleaseUpdate("v99.0.0", ReleaseUpdate.ReleasesUrl, true); RefreshUpdateUI();
        if (UpdateLabel != T("UpdateAvailable")) throw new InvalidOperationException("Update badge missing");
        updateRelease = null; updateFailed = true; RefreshUpdateUI();
        if (UpdateLabel != T("UpdateFailed")) throw new InvalidOperationException("Update failure missing");
        updateChecking = true; RefreshUpdateUI();
        if (UpdateLabel != T("UpdateChecking")) throw new InvalidOperationException("Update progress missing");
        updateChecking = updateFailed = false; updateWindow.Close();
    }
    private void ShowTrayPanel()
    {
        if (trayWindow?.IsVisible == true) { trayWindow.Hide(); return; }
        if (trayWindow == null) {
            trayWindow = new Window { Width = 420, SizeToContent = SizeToContent.Height, WindowStyle = WindowStyle.None, ResizeMode = ResizeMode.NoResize,
                ShowInTaskbar = false, Topmost = true, Icon = Icon };
            trayWindow.Deactivated += (_, _) => { if (!trayWindow!.IsKeyboardFocusWithin) trayWindow.Hide(); };
        }
        PopulateTrayPanel(); trayWindow.Show(); trayWindow.UpdateLayout();
        var area = SystemParameters.WorkArea;
        trayWindow.Left = area.Right - trayWindow.ActualWidth - 12; trayWindow.Top = area.Bottom - trayWindow.ActualHeight - 12; trayWindow.Activate();
    }
    private void PopulateTrayPanel()
    {
        if (trayWindow == null) return;
        trayWindow.Background = background; trayWindow.Foreground = ink; trayWindow.FlowDirection = FlowDirection;
        var body = new StackPanel { Margin = new Thickness(18) };
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
