namespace LocalRouteLauncher;

public static class Strings
{
    public static string Get(string key, string language)
    {
        if (language == "zh-CN") return Items.TryGetValue(key, out var chinese) ? chinese.Zh : Items["OperationFailed"].Zh;
        if (language != "en" && AdditionalStrings.Values.TryGetValue(language, out var translated) && translated.TryGetValue(key, out var value)) return value;
        return Items.TryGetValue(key, out var english) ? english.En : Items["OperationFailed"].En;
    }
    public static IReadOnlyCollection<string> Keys => Items.Keys;
    private static readonly Dictionary<string, (string En, string Zh)> Items = new()
    {
        ["Appearance"] = ("Appearance", "外观"),
        ["Language"] = ("Language", "界面语言"),
        ["Apps"] = ("My apps", "我的应用"),
        ["Backend"] = ("Background services", "后台服务"),
        ["BackendLimit"] = ("Background connections require a real request to verify; no observation does not mean no proxy use.", "后台连接尚需实际请求验证；未观察到不等于未使用代理。"),
        ["Running"] = ("Running", "运行中"),
        ["NotRunning"] = ("Stopped", "未运行"),
        ["Tagline"] = ("A dedicated route. A simpler start.", "独立连接，轻松启动"),
        ["Heading"] = ("Your app. Your connection.", "连接，从这里开始。"),
        ["Subtitle"] = ("Launch ChatGPT with your existing HTTP proxy.", "通过已有的 HTTP 代理启动 ChatGPT。"),
        ["Launch"] = ("Launch ChatGPT", "启动 ChatGPT"), ["Stop"] = ("Stop ChatGPT", "停止 ChatGPT"),
        ["Settings"] = ("Proxy settings", "代理设置"), ["Host"] = ("Proxy address", "代理地址"), ["Port"] = ("Port", "端口"),
        ["Save"] = ("Save settings", "保存设置"), ["Choose"] = ("Choose app", "选择应用"), ["Detect"] = ("Find installed app", "查找已安装应用"),
        ["RestartHint"] = ("Changes apply the next time you launch ChatGPT.", "更改后需重新启动 ChatGPT。"),
        ["NoApp"] = ("Select an installed Electron-based ChatGPT.exe.", "请选择已安装的 Electron 版 ChatGPT.exe。"),
        ["Check"] = ("Check connection", "查看代理情况"), ["Checks"] = ("Connection checks", "连接检查"),
        ["Transport"] = ("Proxy & TLS", "代理与 TLS"), ["Arguments"] = ("Launch arguments", "启动参数"), ["Connections"] = ("Active connections", "实际连接"),
        ["NotChecked"] = ("Not checked", "尚未检查"), ["Configured"] = ("Current proxy passed", "当前地址已传入"), ["Unconfirmed"] = ("Not confirmed", "尚未确认"),
        ["Observed"] = ("{0} to proxy / {1} total", "代理 {0} 条 / 共 {1} 条"),
        ["Report"] = ("Details", "详细报告"), ["Snapshot"] = ("A connection snapshot, not proof that every request uses the proxy. Hostname endpoints cannot be matched by IP.", "连接结果仅为此刻快照，不代表全部流量均通过代理。域名代理地址无法按 IP 匹配。"),
        ["Footer"] = ("Closing this window keeps the launcher in the system tray.", "关闭窗口后，仍可从系统托盘访问。"),
        ["Show"] = ("Open launcher", "打开启动器"), ["Quit"] = ("Quit launcher", "退出启动器"),
        ["Ready"] = ("Ready. Your system proxy and DNS stay unchanged.", "已就绪。不会修改系统代理或 DNS。"),
        ["Saved"] = ("Settings saved. Restart ChatGPT to apply them.", "设置已保存，重新启动 ChatGPT 后生效。"),
        ["Launched"] = ("Launch requested with proxy settings. Use Check connection to inspect the running app.", "已携带代理设置请求启动，请查看代理情况确认运行状态。"),
        ["Stopped"] = ("ChatGPT closed.", "ChatGPT 已关闭。"), ["Working"] = ("Working…", "正在处理…"),
        ["InvalidHost"] = ("Enter a host or IP address, without a scheme, path or credentials.", "请输入域名或 IP 地址，不包含协议、路径或账号密码。"),
        ["InvalidPort"] = ("Port must be a number from 1 to 65535.", "端口必须为 1 至 65535 的数字。"),
        ["InvalidApplication"] = ("Choose a supported Electron-based ChatGPT.exe. Older native or restricted Store packages may not support direct launch.", "请选择受支持的 Electron 版 ChatGPT.exe。旧原生版本或受限制的商店安装包可能无法直接启动。"),
        ["AlreadyRunning"] = ("ChatGPT is already running. Close it first so the new proxy settings can take effect.", "ChatGPT 已在运行，请先退出再启动，以便代理设置生效。"),
        ["LaunchFailed"] = ("Windows could not launch this package directly. Check the selected app and installation permissions.", "Windows 无法直接启动此安装包，请检查所选应用及安装权限。"),
        ["CloseManually"] = ("Please close ChatGPT from its own menu. The launcher will not force-stop it.", "请从 ChatGPT 自身菜单退出，启动器不会强制结束进程。"),
        ["ProcessReadFailed"] = ("Windows process information is unavailable. Try again or check local security policies.", "无法读取 Windows 进程信息，请重试或检查本机安全策略。"),
        ["ConnectionsUnavailable"] = ("Windows connection information is unavailable.", "无法读取 Windows 网络连接信息。"),
        ["ConnectionFailed"] = ("Connection failed", "连接失败"), ["Timeout"] = ("Connection timed out", "连接超时"),
        ["InvalidSettings"] = ("Saved settings could not be read. Defaults are shown; save to replace them.", "无法读取原有设置。已显示默认值，保存后将替换原设置。"),
        ["OperationFailed"] = ("The operation could not be completed. Check app access, proxy settings and local permissions.", "操作未能完成，请检查应用访问权限、代理设置和本机权限。"),
        ["NoReport"] = ("Run Check connection first.", "请先查看代理情况。"),
        ["Legal"] = ("Independent tool; not affiliated with OpenAI. No proxy service included. Follow applicable laws and service terms.", "独立工具，与 OpenAI 无关联。不提供代理服务，请遵守适用法律和服务条款。"),
        ["Dark"] = ("Dark", "深色"), ["Light"] = ("Light", "浅色"), ["System"] = ("System", "跟随系统"),
        ["Detected"] = ("Installed app selected.", "已选择检测到的应用。"),
        ["CheckDone"] = ("Checks complete. HTTP status indicates transport reachability, not account access.", "检查完成。HTTP 状态仅表示传输可达性，不代表账号可用。")
    };
}
