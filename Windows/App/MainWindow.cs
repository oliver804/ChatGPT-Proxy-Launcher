using System.ComponentModel;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Forms = System.Windows.Forms;

namespace LocalRouteLauncher;

public sealed class MainWindow : Window
{
    private Settings settings;
    private readonly bool smoke;
    private bool quitting, busy, rebuilding;
    private string notice = "Ready", report = "", transport = "", arguments = "", connections = "";
    private Action? translateReport;
    private TextBox host = null!, port = null!;
    private TextBlock status = null!, appPath = null!;
    private StackPanel panel = null!, options = null!;
    private readonly List<Button> actions = [];
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
        Closed += (_, _) => { monitor.Stop(); tray?.Dispose(); };
        monitor.Tick += async (_, _) => await Poll();
        if (!smoke) monitor.Start();
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
        SelectApp("chatgpt");
        if (port.Text != "8080") throw new Exception("Legacy app profile lost");
        settings = settings with { Language = "en" }; SavePreferences();
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
            ((ComboBox)options.Children[0]).SelectedIndex = settings.Language == "en" ? 1 : 0;
            ((ComboBox)options.Children[1]).SelectedIndex = settings.Theme == "dark" ? 1 : 2;
            if (settings != original) throw new InvalidOperationException("Preferences changed during an operation.");
        }
        finally { completion.SetResult(); await operation; }
        if (!host.IsEnabled || !port.IsEnabled || !options.IsEnabled || actions.Any(button => !button.IsEnabled) || host.Text != "draft.local" || port.Text != "8080")
            throw new InvalidOperationException("Controls or unsaved input were not restored.");
        await Work(() => throw new InvalidOperationException("Test failure"), "Ready");
        if (!host.IsEnabled || !options.IsEnabled || host.Text != "draft.local")
            throw new InvalidOperationException("Failed operation lost input or left controls disabled.");
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
        var sidebar = new StackPanel { Width = 200, Margin = new Thickness(16, 24, 0, 24) };
        DockPanel.SetDock(sidebar, Dock.Left); shell.Children.Add(sidebar); shell.Children.Add(panel);
        sidebar.Children.Add(Text(T("Apps"), 12, false, muted));
        foreach (var target in TargetApp.All)
        {
            var selector = Button(target.Name + "\n" + T(Running(target.Id) ? "Running" : "NotRunning"), () => SelectApp(target.Id));
            selector.HorizontalContentAlignment = HorizontalAlignment.Left;
            if (target.Id == settings.SelectedApplication) selector.Background = field;
            sidebar.Children.Add(selector);
        }
        Content = new ScrollViewer { Content = shell, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled };
        FlowDirection = AppLanguages.IsRightToLeft(settings.ResolvedLanguage) ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        var header = new DockPanel { Margin = new Thickness(0, 0, 0, 24) };
        options = new StackPanel { HorizontalAlignment = HorizontalAlignment.Right, IsEnabled = !busy };
        DockPanel.SetDock(options, Dock.Right); header.Children.Add(options);
        var language = new ComboBox { Width = 154, Margin = new Thickness(0, 0, 0, 8), ItemsSource = new[] { T("System") }.Concat(AppLanguages.Labels).ToArray(), SelectedIndex = settings.Language == "system" ? 0 : Array.IndexOf(AppLanguages.Codes, settings.Language) + 1 };
        language.SelectionChanged += (_, _) => { if (rebuilding || busy || language.SelectedIndex < 0) return; settings = settings with { Language = language.SelectedIndex == 0 ? "system" : AppLanguages.Codes[language.SelectedIndex - 1] }; SavePreferences(); };
        var theme = new ComboBox { Width = 126, ItemsSource = new[] { T("System"), T("Light"), T("Dark") }, SelectedIndex = settings.Theme == "dark" ? 2 : settings.Theme == "light" ? 1 : 0 };
        theme.SelectionChanged += (_, _) => { if (rebuilding || busy) return; settings = settings with { Theme = theme.SelectedIndex == 2 ? "dark" : theme.SelectedIndex == 1 ? "light" : "system" }; SavePreferences(); };
        options.Children.Add(language); options.Children.Add(theme);
        header.Children.Add(new Image { Source = Icon, Width = 58, Height = 58, Margin = new Thickness(0, 0, 16, 0) });
        var title = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        title.Children.Add(Text("Local Route Launcher", 23, true)); title.Children.Add(Text(T("Tagline"), 13, false, muted)); header.Children.Add(title); panel.Children.Add(header);
        var launchCard = Card(); launchCard.Children.Add(Text(Target.Name, 26, true)); launchCard.Children.Add(Text(T(Running(settings.SelectedApplication) ? "Running" : "NotRunning"), 12, false, accent)); launchCard.Children.Add(Text(T("Subtitle"), 14, false, muted));
        var route = new Border { Background = field, CornerRadius = new CornerRadius(12), Padding = new Thickness(15), Margin = new Thickness(0, 18, 0, 16) };
        var routeLabel = Text($"{Target.Name}   →   {Route(settings.SelectedApplication, Profile(settings.SelectedApplication))}   HTTP", 17, true, accent);
        routeLabel.FlowDirection = FlowDirection.LeftToRight;
        route.Child = routeLabel; launchCard.Children.Add(route);
        var launchActions = new UniformGridCompat();
        launchActions.Children.Add(Button(T("Launch"), async () => await Work(LaunchCurrent, "Launched"), true));
        launchActions.Children.Add(Button(T("Stop"), async () => await Work(async () => { RequireApp(); await WindowsPlatform.Stop(settings.ApplicationPath); ClearResults(); }, "Stopped")));
        launchCard.Children.Add(launchActions);
        var proxyCard = Card(); proxyCard.Children.Add(Text(T("Settings"), 18, true)); proxyCard.Children.Add(Text(T("RestartHint"), 12, false, muted));
        var inputs = new Grid { Margin = new Thickness(0, 14, 0, 0) }; inputs.ColumnDefinitions.Add(new() { Width = new GridLength(1, GridUnitType.Star) }); inputs.ColumnDefinitions.Add(new() { Width = new GridLength(120) });
        var hostPanel = new StackPanel { Margin = new Thickness(0, 0, 12, 0) }; hostPanel.Children.Add(Text(T("Host"), 12, false, muted)); host = Input(settings.Host); hostPanel.Children.Add(host); inputs.Children.Add(hostPanel);
        var portPanel = new StackPanel(); portPanel.Children.Add(Text(T("Port"), 12, false, muted)); port = Input(settings.Port); portPanel.Children.Add(port); Grid.SetColumn(portPanel, 1); inputs.Children.Add(portPanel); proxyCard.Children.Add(inputs);
        appPath = Text(settings.ApplicationPath.Length == 0 ? T("NoApp") : settings.ApplicationPath, 12, false, muted); appPath.FlowDirection = FlowDirection.LeftToRight; appPath.Margin = new Thickness(0, 12, 0, 8); proxyCard.Children.Add(appPath);
        var settingsActions = new WrapPanel(); settingsActions.Children.Add(Button(T("Save"), async () => await Work(() => { SaveDraft(); return Task.CompletedTask; }, "Saved")));
        settingsActions.Children.Add(Button(T("Choose"), Choose)); settingsActions.Children.Add(Button(T("Detect"), async () => await Work(Detect, "Detected"))); proxyCard.Children.Add(settingsActions);
        var checkCard = Card(); var checkHeader = new DockPanel(); var check = Button(T("Check"), Check); DockPanel.SetDock(check, Dock.Right); checkHeader.Children.Add(check); checkHeader.Children.Add(Text(T("Checks"), 18, true)); checkCard.Children.Add(checkHeader);
        var results = new UniformGridCompat(3);
        foreach (var (label, value) in new[] { ("Transport", transport), ("Arguments", arguments), ("Connections", connections) })
        {
            var box = new StackPanel(); box.Children.Add(Text(T(label), 12, false, muted)); box.Children.Add(Text(string.IsNullOrEmpty(value) ? T("NotChecked") : value, 14, true));
            results.Children.Add(new Border { Background = field, CornerRadius = new CornerRadius(12), Padding = new Thickness(12), Margin = new Thickness(0, 10, 8, 8), Child = box });
        }
        checkCard.Children.Add(results); checkCard.Children.Add(Text(T("Snapshot"), 12, false, muted));
        checkCard.Children.Add(Button(T("Report"), () => MessageBox.Show(this, report.Length == 0 ? T("NoReport") : report, T("Report"), MessageBoxButton.OK, MessageBoxImage.Information)));
        status = Text(T(notice), 13, false, accent); status.Margin = new Thickness(0, 4, 0, 14); panel.Children.Add(status);
        panel.Children.Add(Text(T("Footer") + $"    v{Program.Version}", 12, false, muted));
        var legal = Text(T("Legal"), 11, false, muted); legal.Margin = new Thickness(0, 12, 0, 0); panel.Children.Add(legal);
        foreach (var button in actions) button.IsEnabled = !busy;
        rebuilding = false;
    }
    private TextBlock Text(string text, double size = 14, bool bold = false, Brush? color = null) => new() { Text = text, FontSize = size, FontWeight = bold ? FontWeights.SemiBold : FontWeights.Normal, Foreground = color ?? ink, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 2, 0, 3), VerticalAlignment = VerticalAlignment.Center };
    private TextBox Input(string text) => new() { Text = text, Background = field, Foreground = ink, BorderThickness = new Thickness(0), Padding = new Thickness(12), FontSize = 17, FlowDirection = FlowDirection.LeftToRight };
    private StackPanel Card()
    {
        var body = new StackPanel(); panel.Children.Add(new Border { Background = card, CornerRadius = new CornerRadius(20), Padding = new Thickness(22), Margin = new Thickness(0, 0, 0, 18), Child = body }); return body;
    }
    private Button Button(string title, Action action, bool primary = false)
    {
        var button = new Button { Content = title, Background = primary ? Color("#087F67") : field, Foreground = primary ? Brushes.White : ink, BorderThickness = new Thickness(0), Padding = new Thickness(14, 10, 14, 10), Margin = new Thickness(0, 4, 8, 4), Cursor = System.Windows.Input.Cursors.Hand };
        button.Click += (_, _) => action(); actions.Add(button); return button;
    }
    private void ClearResults() { transport = arguments = connections = report = ""; translateReport = null; }
    private Settings Draft() => settings with { Host = host.Text.Trim(), Port = port.Text.Trim() };
    private void SaveDraft()
    {
        var draft = Draft(); _ = new ProxyEndpoint(draft.Host, draft.Port);
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
        settings = Draft() with { ApplicationPath = found[0] }; SaveDraft();
    }
    private async void Choose()
    {
        var picker = new Microsoft.Win32.OpenFileDialog { Filter = Target.Name + " (*.exe)|*.exe", CheckFileExists = true, Title = T("Choose") };
        if (picker.ShowDialog(this) == true) await Work(() => { if (!WindowsPlatform.IsCompatible(picker.FileName, settings.SelectedApplication)) throw new InvalidOperationException("InvalidApplication"); settings = Draft() with { ApplicationPath = picker.FileName }; SaveDraft(); return Task.CompletedTask; }, "Saved");
    }
    private async Task Work(Func<Task> action, string success)
    {
        if (busy) return;
        var draftHost = host.Text; var draftPort = port.Text;
        busy = true; status.Text = T("Working"); foreach (var button in actions) button.IsEnabled = false;
        options.IsEnabled = host.IsEnabled = port.IsEnabled = false;
        try { await action(); notice = success; }
        catch (Exception ex) { notice = ex is Win32Exception ? "LaunchFailed" : ex.Message; }
        finally { busy = false; Build(); host.Text = draftHost; port.Text = draftPort; SetupTray(); await Poll(); }
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
        menu.Items.Add(T("Check"), null, (_, _) => { Reveal(); Check(); });
        menu.Items.Add(T("Quit"), null, (_, _) => { if (!busy) Quit(); });
        tray.ContextMenuStrip = menu; tray.DoubleClick += (_, _) => Reveal();
    }
    private void OnClosing(object? sender, CancelEventArgs e) { if (quitting) return; e.Cancel = true; ShowInTaskbar = false; Hide(); }
    public void Reveal() { ShowInTaskbar = true; Show(); WindowState = WindowState.Normal; Activate(); }
    public void Quit() { quitting = true; tray?.Dispose(); Close(); Application.Current.Shutdown(); }
    private sealed class UniformGridCompat : System.Windows.Controls.Primitives.UniformGrid { public UniformGridCompat(int columns = 2) { Columns = columns; Rows = 1; } }
}
