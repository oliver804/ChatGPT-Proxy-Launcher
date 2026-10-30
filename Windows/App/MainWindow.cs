using System.ComponentModel;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Forms = System.Windows.Forms;

namespace LocalRouteLauncher;

public sealed partial class MainWindow : Window
{
    private Settings settings;
    private readonly bool smoke;
    private bool quitting, busy, rebuilding;
    private string notice = "Ready", report = "", transport = "", arguments = "", connections = "";
    private Action? translateReport;
    private TextBox host = null!, port = null!;
    private TextBlock status = null!, appPath = null!;
    private StackPanel panel = null!, options = null!;
    private readonly Style roundedButtonStyle = RoundedButtonStyle();
    private readonly List<Button> actions = [];
    private Button? startButton, stopButton;
    private Forms.NotifyIcon? tray;
    private Brush background = null!, card = null!, ink = null!, muted = null!, accent = null!, field = null!;
    private readonly Dictionary<string, (string Host, string Port)> drafts = [];
    private readonly Dictionary<string, string> runningSignatures = [];
    private readonly Dictionary<string, ProxyEndpoint> launchEndpoints = [];
    private readonly System.Windows.Threading.DispatcherTimer monitor = new() { Interval = TimeSpan.FromSeconds(4) };
    private bool polling;
    private TargetApp Target => TargetApp.Get(settings.SelectedApplication);
    private string T(string key) => Strings.Get(key, settings.ResolvedLanguage).Replace("ChatGPT.exe", Target.Executable).Replace("ChatGPT", Target.Name).Replace("OpenAI", "OpenAI / Google");
    private bool Running(string id) => runningSignatures.GetValueOrDefault(id, "").Length > 0;
    private string Route(string id, AppProfile profile) => Running(id) && launchEndpoints.TryGetValue(id, out var endpoint) ? endpoint.Authority : new ProxyEndpoint(profile.Host, profile.Port).Authority;
    private AppProfile Profile(string id) => id == settings.SelectedApplication ? new(settings.Host, settings.Port, settings.ApplicationPath) : settings.Profiles?.GetValueOrDefault(id) ?? new();
    private void SelectApp(string id)
    {
        if (busy || id == settings.SelectedApplication) return;
        drafts[settings.SelectedApplication] = (host.Text, port.Text);
        settings = settings.Select(id);
        if (!smoke) { try { settings.Save(); } catch { notice = "OperationFailed"; } }
        ClearResults();
        Build(); RestoreDraft(); SetupTray();
    }
    private void RestoreDraft()
    {
        if (drafts.TryGetValue(settings.SelectedApplication, out var draft)) { host.Text = draft.Host; port.Text = draft.Port; }
    }
    private async Task Poll()
    {
        if (busy || polling || smoke) return;
        polling = true;
        try
        {
            var rows = await WindowsPlatform.Processes();
            if (busy) return;
            bool changed = false;
            foreach (var target in TargetApp.All)
            {
                var path = Profile(target.Id).ApplicationPath;
                var signature = path.Length == 0 ? "" : string.Join(",", WindowsPlatform.Roots(path, rows).Select(p => p.Pid).Order());
                if (runningSignatures.GetValueOrDefault(target.Id, "") != signature)
                {
                    changed = true;
                    runningSignatures[target.Id] = signature;
                    if (signature.Length == 0) launchEndpoints.Remove(target.Id);
                    if (target.Id == settings.SelectedApplication) ClearResults();
                }
            }
            if (changed) { drafts[settings.SelectedApplication] = (host.Text, port.Text); Build(); RestoreDraft(); SetupTray(); }
        }
        catch { /* Keep last observed state; explicit checks report unavailable process access. */ }
        finally { polling = false; }
    }
    private async Task LaunchCurrent()
    {
        if (settings.ApplicationPath.Length == 0) await Detect();
        SaveDraft();
        var endpoint = new ProxyEndpoint(settings.Host, settings.Port);
        await WindowsPlatform.Launch(settings.ApplicationPath, endpoint, settings.SelectedApplication);
        launchEndpoints[settings.SelectedApplication] = endpoint;
    }
    private static SolidColorBrush Color(string hex) => new((System.Windows.Media.Color)ColorConverter.ConvertFromString(hex));
    public MainWindow(bool smokeMode = false)
    {
        smoke = smokeMode;
        try { settings = smoke ? new Settings { Language = "en" } : Settings.Load(); }
        catch { settings = new Settings(); notice = "InvalidSettings"; }
        Title = "Local Route Launcher"; Width = 1040; Height = 900; MinWidth = 940; MinHeight = 640;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        Icon = new BitmapImage(new Uri("pack://application:,,,/Brand.png"));
        FontFamily = new FontFamily("Segoe UI, Microsoft YaHei UI"); FontSize = 14;
        Build(); SetupTray();
        SourceInitialized += (_, _) => System.Windows.Interop.HwndSource.FromHwnd(new System.Windows.Interop.WindowInteropHelper(this).Handle)?.AddHook((IntPtr h, int m, IntPtr w, IntPtr l, ref bool handled) => { if (m == 0x8001) { Reveal(); handled = true; } return IntPtr.Zero; });
        Closing += OnClosing;
        if (!smoke) SystemEvents.UserPreferenceChanged += SystemAppearanceChanged;
        Closed += (_, _) => { SystemEvents.UserPreferenceChanged -= SystemAppearanceChanged; updateCancellation.Cancel(); trayWindow?.Close(); monitor.Stop(); tray?.Dispose(); };
        monitor.Tick += async (_, _) => await Poll();
        if (!smoke) { monitor.Start(); Loaded += async (_, _) => { if (settings.CheckUpdatesAtStartup) await CheckUpdates(); }; }
        if (!smoke) Loaded += async (_, _) => { if (string.IsNullOrEmpty(settings.ApplicationPath)) await Work(Detect, "Detected"); };
    }
    public void Preview(string language, string theme) { settings = settings with { Language = language, Theme = theme }; notice = "Ready"; Build(); }
    internal void VerifyProfiles()
    {
        if (!smoke) throw new InvalidOperationException("Smoke mode required.");
        host.Text = "localhost"; port.Text = "8080"; SaveDraft();
        SelectApp("antigravity");
        if (port.Text != "7890") throw new Exception("Cross-app settings leaked");
        host.Text = "127.0.0.1"; port.Text = "7891"; SaveDraft();
        port.Text = "7892"; // Unsaved edits survive selection and language changes.
        SelectApp("antigravityIDE");
        if (port.Text != "7890") throw new Exception("IDE defaults leaked");
        SelectApp("antigravity");
        if (port.Text != "7892" || settings.Port != "7891") throw new Exception("Draft was lost or saved implicitly");
        settings = settings with { Language = "ar" }; SavePreferences();
        if (port.Text != "7892" || FlowDirection != FlowDirection.RightToLeft) throw new Exception("Global language change lost draft or RTL");
        if (host.FlowDirection != FlowDirection.LeftToRight || port.FlowDirection != FlowDirection.LeftToRight) throw new Exception("Endpoint direction changed");
        var languageMenu = tray?.ContextMenuStrip?.Items.OfType<Forms.ToolStripMenuItem>().FirstOrDefault(item => item.Text?.EndsWith(" / Language", StringComparison.Ordinal) == true);
        if (languageMenu == null || languageMenu.DropDownItems.Count != 10 || languageMenu.DropDownItems.OfType<Forms.ToolStripMenuItem>().Count(item => item.Checked) != 1)
            throw new Exception("Tray language options do not match the global preference");
        foreach (var mode in new[] { "system", "light", "dark" })
        {
            var appearanceMenu = tray?.ContextMenuStrip?.Items.OfType<Forms.ToolStripMenuItem>().Single(item => item.Name == "appearance");
            var index = mode == "system" ? 0 : mode == "light" ? 1 : 2;
            ((Forms.ToolStripMenuItem)appearanceMenu!.DropDownItems[index]).PerformClick();
            if (settings.Theme != mode || port.Text != "7892") throw new Exception("Tray theme did not preserve draft and preference");
            var updated = tray!.ContextMenuStrip!.Items.OfType<Forms.ToolStripMenuItem>().Single(item => item.Name == "appearance");
            if (!((Forms.ToolStripMenuItem)updated.DropDownItems[index]).Checked) throw new Exception("Tray theme checkmark is stale");
        }
        if (tray!.ContextMenuStrip!.Items.OfType<Forms.ToolStripMenuItem>().All(item => item.Text != "GitHub")) throw new Exception("Missing GitHub tray entry");
        SelectApp("chatgpt");
        if (port.Text != "8080") throw new Exception("Legacy app profile lost");
        settings = settings with { Language = "en" }; SavePreferences();
        var saved = settings;
        host.Text = "http://invalid";
        try { SaveDraft("unexpected.exe"); throw new Exception("Invalid draft accepted"); }
        catch (ArgumentException) { }
        if (settings != saved) throw new Exception("Failed validation changed the saved profile");
        host.Text = saved.Host;
    }
    internal async Task VerifyBusyControls()
    {
        if (!smoke) throw new InvalidOperationException("Smoke mode required.");
        host.Text = "draft.local"; port.Text = "8080";
        var original = settings;
        var completion = new TaskCompletionSource();
        var operation = Work(() => completion.Task, "Ready");
        try
        {
            if (host.IsEnabled || port.IsEnabled || options.IsEnabled || actions.Any(button => button.IsEnabled))
                throw new InvalidOperationException("Controls remained editable during an operation.");
            SetLanguage(settings.Language == "en" ? "zh-CN" : "en");
            SetTheme(settings.Theme == "dark" ? "light" : "dark");
            if (settings != original) throw new InvalidOperationException("Preferences changed during an operation.");
        }
        finally { completion.SetResult(); await operation; }
        if (!host.IsEnabled || !port.IsEnabled || !options.IsEnabled || actions.Any(button => button != startButton && button != stopButton && !button.IsEnabled) || host.Text != "draft.local" || port.Text != "8080")
            throw new InvalidOperationException("Controls or unsaved input were not restored.");
        await Work(() => throw new InvalidOperationException("Test failure"), "Ready");
        if (!host.IsEnabled || !options.IsEnabled || host.Text != "draft.local")
            throw new InvalidOperationException("Failed operation lost input or left controls disabled.");
    }
    private void SystemAppearanceChanged(object sender, UserPreferenceChangedEventArgs e)
    {
        Dispatcher.BeginInvoke(() => {
            if (quitting || busy || settings.Theme != "system") return;
            var draftHost = host.Text; var draftPort = port.Text;
            Build(); host.Text = draftHost; port.Text = draftPort; RefreshAuxiliaryWindows();
        });
    }
    private bool IsDark()
    {
        if (settings.Theme != "system") return settings.Theme == "dark";
        try { return Registry.GetValue(@"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1) is int value && value == 0; }
        catch { return false; }
    }
    private void Build()
    {
        rebuilding = true; actions.Clear();
        bool dark = IsDark();
        background = Color(dark ? "#1F2725" : "#F3F7F5"); card = Color(dark ? "#202322" : "#FFFFFF");
        ink = Color(dark ? "#E6ECE9" : "#202D28"); muted = Color(dark ? "#A2AEA8" : "#63766C");
        accent = Color(dark ? "#66DBC0" : "#087F67"); field = Color(dark ? "#2A302D" : "#F0F5F2");
        Background = background; Foreground = ink;
        panel = new StackPanel { Margin = new Thickness(24) };
        var shell = new DockPanel();
        var sidebar = new Grid { Width = 200, Margin = new Thickness(16, 24, 0, 24) };
        sidebar.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        sidebar.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        var sidebarItems = new StackPanel(); sidebar.Children.Add(sidebarItems);
        DockPanel.SetDock(sidebar, Dock.Left); shell.Children.Add(sidebar);
        var contentArea = new DockPanel(); shell.Children.Add(contentArea);
        var footer = new StackPanel { Margin = new Thickness(24, 4, 24, 16) }; DockPanel.SetDock(footer, Dock.Bottom); contentArea.Children.Add(footer);
        contentArea.Children.Add(new ScrollViewer { Content = panel, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled });
        var brand = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 12, 0, 28) };
        brand.Children.Add(new Image { Source = Icon, Width = 32, Height = 32, Margin = new Thickness(0, 0, 10, 0) });
        brand.Children.Add(Text("Local Route\nLauncher", 14, true)); sidebarItems.Children.Add(brand);
        sidebarItems.Children.Add(Text(T("Apps"), 12, false, muted));
        foreach (var target in TargetApp.All)
        {
            var selector = Button(target.Name + "\n" + T(Running(target.Id) ? "Running" : "NotRunning"), () => SelectApp(target.Id));
            selector.HorizontalContentAlignment = HorizontalAlignment.Left;
            if (target.Id == settings.SelectedApplication) { selector.Background = Color(dark ? "#28473B" : "#DCEEE5"); selector.Foreground = accent; }
            sidebarItems.Children.Add(selector);
        }
        var sidebarFooter = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 24, 0, 0) };
        sidebarFooter.Children.Add(Text($"v{Program.Version}", 11, false, muted)); sidebarFooter.Children.Add(UpdateButton());
        Grid.SetRow(sidebarFooter, 1); sidebar.Children.Add(sidebarFooter);
        var root = new DockPanel();
        var toolbar = new DockPanel { Margin = new Thickness(16, 4, 18, 4) };
        options = Toolbar(); DockPanel.SetDock(options, Dock.Right); toolbar.Children.Add(options);
        DockPanel.SetDock(toolbar, Dock.Top); root.Children.Add(toolbar);
        root.Children.Add(shell);
        Content = root;
        FlowDirection = AppLanguages.IsRightToLeft(settings.ResolvedLanguage) ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        var header = new StackPanel { Margin = new Thickness(0, 0, 0, 14) };
        header.Children.Add(Text(Target.Name, 23, true)); header.Children.Add(Text(T("Tagline"), 12, false, muted)); panel.Children.Add(header);
        var launchCard = Card(); var launchHeader = new DockPanel();
        var badge = Text(T(Running(settings.SelectedApplication) ? "Running" : "NotRunning"), 11, false, accent); DockPanel.SetDock(badge, Dock.Right); launchHeader.Children.Add(badge);
        launchHeader.Children.Add(Text(T("Heading"), 20, true)); launchCard.Children.Add(launchHeader);
        launchCard.Children.Add(Text(T("ScopedSettings"), 12, false, muted));
        var route = new Border { Background = field, CornerRadius = new CornerRadius(10), Padding = new Thickness(12), Margin = new Thickness(0, 12, 0, 12) };
        var routeLabel = Text($"{Target.Name}   →   {Route(settings.SelectedApplication, Profile(settings.SelectedApplication))}   HTTP", 14, true, accent);
        routeLabel.FlowDirection = FlowDirection.LeftToRight;
        route.Child = routeLabel; launchCard.Children.Add(route);
        var launchActions = new UniformGridCompat();
        startButton = Button(T("Launch"), async () => await Work(LaunchCurrent, "Launched"), true); launchActions.Children.Add(startButton);
        stopButton = Button(T("Stop"), async () => await Work(async () => { RequireApp(); await WindowsPlatform.Stop(settings.ApplicationPath); ClearResults(); }, "Stopped")); launchActions.Children.Add(stopButton);
        launchCard.Children.Add(launchActions);
        var proxyCard = Card(); var proxyHeader = new DockPanel();
        var restart = Text(T("RestartHint"), 11, false, muted); DockPanel.SetDock(restart, Dock.Right); proxyHeader.Children.Add(restart); proxyHeader.Children.Add(Text(T("Settings"), 14, true)); proxyCard.Children.Add(proxyHeader);
        var inputs = new Grid { Margin = new Thickness(0, 10, 0, 0) }; inputs.ColumnDefinitions.Add(new() { Width = new GridLength(1, GridUnitType.Star) }); inputs.ColumnDefinitions.Add(new() { Width = new GridLength(96) }); inputs.ColumnDefinitions.Add(new() { Width = GridLength.Auto });
        var hostPanel = new StackPanel { Margin = new Thickness(0, 0, 12, 0) }; hostPanel.Children.Add(Text(T("Host"), 11, false, muted)); host = Input(settings.Host); hostPanel.Children.Add(host); inputs.Children.Add(hostPanel);
        var portPanel = new StackPanel(); portPanel.Children.Add(Text(T("Port"), 11, false, muted)); port = Input(settings.Port); portPanel.Children.Add(port); Grid.SetColumn(portPanel, 1); inputs.Children.Add(portPanel);
        var save = Button(T("Save"), async () => await Work(() => { SaveDraft(); return Task.CompletedTask; }, "Saved")); save.VerticalAlignment = VerticalAlignment.Bottom; save.Margin = new Thickness(12, 0, 0, 0); Grid.SetColumn(save, 2); inputs.Children.Add(save); proxyCard.Children.Add(inputs);
        var pathRow = new DockPanel { Margin = new Thickness(0, 8, 0, 0) };
        var choose = Button(T("Choose"), Choose); choose.FontSize = 11; choose.Background = Brushes.Transparent; DockPanel.SetDock(choose, Dock.Right); pathRow.Children.Add(choose);
        var detect = Button("↻", async () => await Work(Detect, "Detected")); detect.ToolTip = T("Detect"); System.Windows.Automation.AutomationProperties.SetName(detect, T("Detect")); detect.Background = Brushes.Transparent; DockPanel.SetDock(detect, Dock.Right); pathRow.Children.Add(detect);
        appPath = Text(settings.ApplicationPath.Length == 0 ? T("NoApp") : settings.ApplicationPath, 11, false, muted); appPath.FlowDirection = FlowDirection.LeftToRight; appPath.TextWrapping = TextWrapping.NoWrap; appPath.TextTrimming = TextTrimming.CharacterEllipsis; pathRow.Children.Add(appPath); proxyCard.Children.Add(pathRow);
        var checkCard = Card(); var checkHeader = new DockPanel(); var check = Button(T("Check"), Check); check.FontSize = 11; check.Background = Brushes.Transparent; DockPanel.SetDock(check, Dock.Right); checkHeader.Children.Add(check); checkHeader.Children.Add(Text(T("Checks"), 14, true)); checkCard.Children.Add(checkHeader);
        var results = new UniformGridCompat(3);
        foreach (var (label, value) in new[] { ("Transport", transport), ("Arguments", arguments), ("Connections", connections) })
        {
            var box = new StackPanel(); box.Children.Add(Text(T(label), 12, false, muted)); box.Children.Add(Text(string.IsNullOrEmpty(value) ? T("NotChecked") : value, 14, true));
            results.Children.Add(new Border { Background = field, CornerRadius = new CornerRadius(12), Padding = new Thickness(12), Margin = new Thickness(0, 10, 8, 8), Child = box });
        }
        checkCard.Children.Add(results); checkCard.Children.Add(Text(T("Snapshot"), 11, false, muted));
        var details = Button(T("Report"), () => MessageBox.Show(this, report.Length == 0 ? T("NoReport") : report, T("Report"), MessageBoxButton.OK, MessageBoxImage.Information)); details.HorizontalAlignment = HorizontalAlignment.Right; details.FontSize = 11; details.Background = Brushes.Transparent; checkCard.Children.Add(details);
        status = Text(T(notice), 12, false, accent); status.Margin = new Thickness(0, 4, 0, 8); status.Visibility = Visibility.Collapsed;
        footer.Children.Add(Text(T("Footer"), 11, false, muted));
        var legal = Text(T("CompactLegal"), 11, false, muted); legal.Margin = new Thickness(0, 6, 0, 0); footer.Children.Add(legal);
        foreach (var button in actions) button.IsEnabled = !busy;
        startButton.IsEnabled = !busy && !Running(settings.SelectedApplication); stopButton.IsEnabled = !busy && Running(settings.SelectedApplication);
        rebuilding = false;
    }
    private static Style RoundedButtonStyle()
    {
        // Native WPF disabled chrome otherwise becomes a bright rectangle in dark mode.
        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(8));
        border.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(Control.BackgroundProperty));
        border.SetValue(Border.PaddingProperty, new TemplateBindingExtension(Control.PaddingProperty));
        var content = new FrameworkElementFactory(typeof(ContentPresenter));
        content.SetValue(ContentPresenter.HorizontalAlignmentProperty, new TemplateBindingExtension(Control.HorizontalContentAlignmentProperty));
        content.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
        content.SetValue(ContentPresenter.RecognizesAccessKeyProperty, true);
        border.AppendChild(content);
        var style = new Style(typeof(Button));
        style.Setters.Add(new Setter(Control.TemplateProperty, new ControlTemplate(typeof(Button)) { VisualTree = border }));
        var hover = new Trigger { Property = UIElement.IsMouseOverProperty, Value = true }; hover.Setters.Add(new Setter(UIElement.OpacityProperty, 0.85)); style.Triggers.Add(hover);
        var disabled = new Trigger { Property = UIElement.IsEnabledProperty, Value = false }; disabled.Setters.Add(new Setter(UIElement.OpacityProperty, 0.38)); style.Triggers.Add(disabled);
        return style;
    }
    private TextBlock Text(string text, double size = 14, bool bold = false, Brush? color = null) => new() { Text = text, FontSize = size, FontWeight = bold ? FontWeights.SemiBold : FontWeights.Normal, Foreground = color ?? ink, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 2, 0, 3), VerticalAlignment = VerticalAlignment.Center };
    private TextBox Input(string text) => new() { Text = text, Background = field, Foreground = ink, BorderThickness = new Thickness(0), Padding = new Thickness(10), FontSize = 14, FlowDirection = FlowDirection.LeftToRight };
    private StackPanel Card()
    {
        var body = new StackPanel(); panel.Children.Add(new Border { Background = card, CornerRadius = new CornerRadius(18), Padding = new Thickness(20), Margin = new Thickness(0, 0, 0, 14), Child = body }); return body;
    }
    private Button Button(string title, Action action, bool primary = false)
    {
        var button = new Button { Style = roundedButtonStyle, Content = title, Background = primary ? Color("#087F67") : field, Foreground = primary ? Brushes.White : ink, BorderThickness = new Thickness(0), Padding = new Thickness(12, 9, 12, 9), Margin = new Thickness(0, 4, 8, 4), Cursor = System.Windows.Input.Cursors.Hand };
        button.Click += (_, _) => action(); actions.Add(button); return button;
    }
    private void ClearResults() { transport = arguments = connections = report = ""; translateReport = null; }
    private Settings Draft() => settings with { Host = host.Text.Trim(), Port = port.Text.Trim() };
    private void SaveDraft(string? applicationPath = null)
    {
        var draft = Draft();
        var endpoint = new ProxyEndpoint(draft.Host, draft.Port);
        draft = draft with { Host = endpoint.Host, Port = endpoint.Port.ToString(), ApplicationPath = applicationPath ?? draft.ApplicationPath };
        if (!smoke) draft.Save();
        settings = draft;
        drafts[settings.SelectedApplication] = (draft.Host, draft.Port);
        // Diagnostics describe a previous process/configuration snapshot, never a new launch.
        ClearResults();
    }
    private void SavePreferences()
    {
        var draftHost = host.Text; var draftPort = port.Text;
        try { _ = new ProxyEndpoint(settings.Host, settings.Port); if (!smoke) settings.Save(); notice = "Saved"; }
        catch (Exception ex) { notice = ex.Message; }
        translateReport?.Invoke(); Build(); host.Text = draftHost; port.Text = draftPort; SetupTray();
    }
    private void RequireApp() { if (!WindowsPlatform.IsCompatible(settings.ApplicationPath, settings.SelectedApplication)) throw new InvalidOperationException("InvalidApplication"); }
    private async Task Detect()
    {
        var found = await WindowsPlatform.Discover(settings.SelectedApplication); if (found.Length == 0) throw new InvalidOperationException("InvalidApplication");
        SaveDraft(found[0]);
    }
    private async void Choose()
    {
        var picker = new Microsoft.Win32.OpenFileDialog { Filter = Target.Name + " (*.exe)|*.exe", CheckFileExists = true, Title = T("Choose") };
        if (picker.ShowDialog(this) == true) await Work(() => { if (!WindowsPlatform.IsCompatible(picker.FileName, settings.SelectedApplication)) throw new InvalidOperationException("InvalidApplication"); SaveDraft(picker.FileName); return Task.CompletedTask; }, "Saved");
    }
    private async Task Work(Func<Task> action, string success)
    {
        if (busy) return;
        var draftHost = host.Text; var draftPort = port.Text;
        busy = true; status.Text = T("Working"); foreach (var button in actions) button.IsEnabled = false;
        options.IsEnabled = host.IsEnabled = port.IsEnabled = false;
        RefreshAuxiliaryWindows();
        try { await action(); notice = success; }
        catch (Exception ex) { notice = ex is Win32Exception ? "LaunchFailed" : ex.Message; if (!smoke) MessageBox.Show(this, T(notice), "Local Route Launcher"); }
        finally { busy = false; Build(); host.Text = draftHost; port.Text = draftPort; SetupTray(); await Poll(); RefreshAuxiliaryWindows(); }
    }
    private async void Check() => await Work(async () =>
    {
        SaveDraft(); RequireApp(); var endpoint = new ProxyEndpoint(settings.Host, settings.Port);
        var probeTask = ProxyProbe.Check(endpoint, CancellationToken.None, settings.SelectedApplication);
        var rows = await WindowsPlatform.Processes(); var roots = WindowsPlatform.Roots(settings.ApplicationPath, rows);
        bool configured = roots.Count > 0 && roots.All(r => endpoint.MatchesArguments(WindowsPlatform.SplitArguments(r.CommandLine)));
        List<WindowsPlatform.Connection>? active = null;
        var family = ProcessFamily.Collect(roots.Select(r => r.Pid), rows);
        var backends = rows.Where(r => family.Contains(r.Pid) && r.Path.Contains("language_server", StringComparison.OrdinalIgnoreCase)).Select(r => r.Pid).ToHashSet();
        try { active = WindowsPlatform.Connections(family); } catch { /* Report unavailable observations separately. */ }
        var probe = await probeTask;
        var checkedAt = DateTimeOffset.Now;
        translateReport = () =>
        {
            arguments = T(configured ? "Configured" : "Unconfirmed");
            transport = probe.Success ? probe.Detail : T(probe.Detail);
            connections = active == null ? T("Unconfirmed") : string.Format(T("Observed"), active.Count(c => endpoint.Matches(c.Remote, c.Port)), active.Count);
            var connectionDetail = active == null ? T("ConnectionsUnavailable") : string.Join("\n", active.Select(c => $"PID {c.Pid}: {c.Remote}:{c.Port}"));
            connectionDetail += "\n\n" + T("Backend") + ":\n" + (backends.Count == 0 || active == null ? T("Unconfirmed") : string.Join("\n", backends.Order().Select(pid => $"PID {pid}: {active.Count(c => c.Pid == pid && endpoint.Matches(c.Remote, c.Port))}"))) + "\n" + T("BackendLimit");
            report = $"Local Route Launcher {Program.Version} · {Target.Name}\n{checkedAt:g}\n{endpoint.Url}\n\n{T("Transport")}: {transport}\n{T("Arguments")}: {arguments}\n{T("Connections")}: {connections}\n{connectionDetail}\n\n{T("Snapshot")}\n{T("CheckDone")}";
        };
        translateReport();
    }, "CheckDone");
    private const string RepositoryUrl = "https://github.com/oliver804/Local-Route-Launcher";
    // GitHub mark from Primer Octicons (MIT); see THIRD_PARTY_NOTICES.md.
    private const string GitHubPath = "M6.766 11.328c-2.063-.25-3.516-1.734-3.516-3.656 0-.781.281-1.625.75-2.188-.203-.515-.172-1.609.063-2.062.625-.078 1.468.25 1.968.703.594-.187 1.219-.281 1.985-.281.765 0 1.39.094 1.953.265.484-.437 1.344-.765 1.969-.687.218.422.25 1.515.046 2.047.5.593.766 1.39.766 2.203 0 1.922-1.453 3.375-3.547 3.64.531.344.89 1.094.89 1.954v1.625c0 .468.391.734.86.547C13.781 14.359 16 11.53 16 8.03 16 3.61 12.406 0 7.984 0 3.563 0 0 3.61 0 8.031a7.88 7.88 0 0 0 5.172 7.422c.422.156.828-.125.828-.547v-1.25c-.219.094-.5.156-.75.156-1.031 0-1.64-.562-2.078-1.609-.172-.422-.36-.672-.719-.719-.187-.015-.25-.093-.25-.187 0-.188.313-.328.625-.328.453 0 .844.281 1.25.86.313.452.64.655 1.031.655s.641-.14 1-.5c.266-.265.47-.5.657-.656";
    private void OpenRepository()
    {
        try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(RepositoryUrl) { UseShellExecute = true }); }
        catch { notice = "OperationFailed"; status.Text = T(notice); }
    }
    private Button RepositoryButton()
    {
        var button = new Button {
            Style = roundedButtonStyle, Content = new System.Windows.Shapes.Path { Data = Geometry.Parse(GitHubPath), Fill = muted, Width = 17, Height = 17, Stretch = Stretch.Uniform },
            Padding = new Thickness(0), Width = 32, Height = 32, Background = Brushes.Transparent,
            BorderThickness = new Thickness(0), ToolTip = "GitHub"
        };
        System.Windows.Automation.AutomationProperties.SetName(button, "GitHub");
        button.Click += (_, _) => OpenRepository();
        return button;
    }
    private void SetupTray()
    {
        tray?.Dispose();
        using var iconStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Launcher.ico");
        tray = new Forms.NotifyIcon { Text = "Local Route Launcher", Icon = iconStream == null ? System.Drawing.SystemIcons.Application : new System.Drawing.Icon(iconStream), Visible = true };
        var menu = new Forms.ContextMenuStrip { RightToLeft = AppLanguages.IsRightToLeft(settings.ResolvedLanguage) ? Forms.RightToLeft.Yes : Forms.RightToLeft.No };
        menu.Items.Add(T("Show"), null, (_, _) => Reveal());
        foreach (var target in TargetApp.All)
        {
            var item = new Forms.ToolStripMenuItem(target.Name + " · " + T(Running(target.Id) ? "Running" : "NotRunning")) { Enabled = !busy };
            item.DropDownItems.Add(Route(target.Id, Profile(target.Id))).Enabled = false;
            item.DropDownItems.Add(Strings.Get("Launch", settings.ResolvedLanguage).Replace("ChatGPT", target.Name), null, async (_, _) => { if (busy) return; SelectApp(target.Id); await Work(LaunchCurrent, "Launched"); });
            item.DropDownItems.Add(Strings.Get("Stop", settings.ResolvedLanguage).Replace("ChatGPT", target.Name), null, async (_, _) => { if (busy) return; SelectApp(target.Id); await Work(async () => { RequireApp(); await WindowsPlatform.Stop(settings.ApplicationPath); }, "Stopped"); });
            menu.Items.Add(item);
        }
        menu.Items.Add(new Forms.ToolStripSeparator());
        var languages = new Forms.ToolStripMenuItem(T("Language") + " / Language") { Enabled = !busy };
        foreach (var code in new[] { "system" }.Concat(AppLanguages.Codes))
        {
            var label = code == "system" ? T("System") : AppLanguages.Labels[Array.IndexOf(AppLanguages.Codes, code)];
            var item = new Forms.ToolStripMenuItem(label) { Checked = settings.Language == code };
            item.Click += (_, _) => { if (busy) return; settings = settings with { Language = code }; SavePreferences(); };
            languages.DropDownItems.Add(item);
        }
        menu.Items.Add(languages);
        var appearance = new Forms.ToolStripMenuItem(T("Appearance")) { Name = "appearance", Enabled = !busy };
        foreach (var mode in new[] { "system", "light", "dark" })
        {
            var label = T(mode == "system" ? "System" : mode == "light" ? "Light" : "Dark");
            var item = new Forms.ToolStripMenuItem(label) { Checked = settings.Theme == mode };
            item.Click += (_, _) => { if (busy) return; settings = settings with { Theme = mode }; SavePreferences(); };
            appearance.DropDownItems.Add(item);
        }
        menu.Items.Add(appearance);
        menu.Items.Add("GitHub", null, (_, _) => OpenRepository());
        menu.Items.Add(T("Check"), null, (_, _) => { Reveal(); Check(); });
        menu.Items.Add(T("Quit"), null, (_, _) => { if (!busy) Quit(); });
        if (UpdateAvailable) menu.Items.Add(T("UpdateAvailable"), null, (_, _) => DownloadUpdate());
        tray.ContextMenuStrip = menu; tray.DoubleClick += (_, _) => Reveal();
        tray.MouseClick += (_, e) => { if (e.Button == Forms.MouseButtons.Left) ShowTrayPanel(); };
    }
    private void OnClosing(object? sender, CancelEventArgs e) { if (quitting) return; e.Cancel = true; ShowInTaskbar = false; Hide(); }
    public void Reveal() { ShowInTaskbar = true; Show(); WindowState = WindowState.Normal; Activate(); }
    public void Quit() { quitting = true; tray?.Dispose(); Close(); Application.Current.Shutdown(); }
    private sealed class UniformGridCompat : System.Windows.Controls.Primitives.UniformGrid { public UniformGridCompat(int columns = 2) { Columns = columns; Rows = 1; } }
}
