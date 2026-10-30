import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case russian = "ru"
    case persian = "fa"
    case belarusian = "be"
    case spanish = "es"
    case arabic = "ar"
    case portuguese = "pt"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .chinese: "简体中文"
        case .english: "English"
        case .traditionalChinese: "繁體中文"
        case .russian: "Русский"
        case .persian: "فارسی"
        case .belarusian: "Беларуская"
        case .spanish: "Español"
        case .arabic: "العربية"
        case .portuguese: "Português"
        }
    }
    var isRightToLeft: Bool { self == .persian || self == .arabic }
    var locale: Locale { Locale(identifier: rawValue) }
    static func resolve(saved: String?, preferred: [String] = Locale.preferredLanguages) -> AppLanguage {
        if let saved, let language = AppLanguage(rawValue: saved) { return language }
        for preference in preferred {
            let code = preference.lowercased().replacingOccurrences(of: "_", with: "-")
            let subtags = code.split(separator: "-")
            if subtags.first == "zh" {
                if subtags.contains("hans") { return .chinese }
                if subtags.contains("hant") { return .traditionalChinese }
                return subtags.contains(where: { ["tw", "hk", "mo"].contains($0) }) ? .traditionalChinese : .chinese
            }
            if let language = AppLanguage.allCases.first(where: { code == $0.rawValue.lowercased() || code.hasPrefix($0.rawValue.lowercased() + "-") }) { return language }
        }
        return .english
    }
    static var current: AppLanguage { resolve(saved: UserDefaults.standard.string(forKey: "interfaceLanguage")) }
}

enum L10n {
    // Chinese keys are also the source-language text. Arguments use positional replacement,
    // never printf parsing, so paths and command output containing percent signs stay literal.
    static let english: [String: String] = [
        "检查更新": "Check for updates",
        "有更新": "Update available",
        "发现新版本": "A new version is available",
        "已是最新版本": "You are up to date",
        "暂时无法检查更新": "Unable to check for updates",
        "正在检查更新…": "Checking for updates…",
        "启动时自动检查": "Check automatically at startup",
        "从 GitHub Releases 检查稳定版本，不自动下载或安装。": "Checks stable GitHub Releases. No automatic download or installation.",
        "查看发布说明与下载": "Release notes & download",
        "打开发布页面": "Open releases",
        "重试": "Retry",
        "可继续使用当前版本，稍后重试。": "You can keep using this version and try again later.",
        "当前版本": "Installed version",
        "最新稳定版": "Latest stable version",
        "独立项目，与 OpenAI 无隶属或背书关系；商标归各自权利人所有。": "Independent project; not affiliated with or endorsed by OpenAI. Trademarks belong to their owners.",
        "外观": "Appearance",
        "浅色": "Light",
        "深色": "Dark",
        "运行中": "Running",
        "跟随系统": "Follow system",
        "我的应用": "My apps",
        "后台服务": "Background services",
        "后台连接尚需实际请求验证；未观察到不等于未使用代理。": "Background connections require a real request to verify; no observation does not mean no proxy use.",

        "ChatGPT 运行中": "ChatGPT running",
        "ChatGPT 未运行": "ChatGPT stopped",
        "独立连接，轻松启动": "App-specific network settings",
        "连接，从这里开始。": "Your connection, in one place.",
        "为 ChatGPT 准备就绪。": "Ready to launch ChatGPT.",
        "仅为兼容应用传入设置，不修改系统网络。": "Launch settings for compatible apps. System networking stays unchanged.",
        "HTTP 代理": "HTTP proxy",
        "启动 ChatGPT": "Start ChatGPT",
        "停止 ChatGPT": "Stop ChatGPT",
        "代理设置": "Proxy settings",
        "更改后需重新启动 ChatGPT": "Restart ChatGPT to apply changes",
        "代理地址": "Proxy host",
        "端口": "Port",
        "保存设置": "Save settings",
        "ChatGPT 版本：%@": "ChatGPT version: %@",
        "选择应用": "Choose app",
        "连接检查": "Connection checks",
        "查看代理情况": "Check connection",
        "代理连通": "Proxy connectivity",
        "启动参数": "Launch arguments",
        "实际连接": "Observed connections",
        "最近检查 ": "Last checked ",
        "检查代理连通性、启动配置与实际连接": "Check connectivity, launch settings, and TCP connections",
        "详细报告": "Detailed report",
        "关闭窗口后，仍可从菜单栏访问": "Available in the menu bar after closing this window",
        "代理检查报告": "Connection report",
        "完成": "Done",
        "复制报告": "Copy report",
        "启动": "Start",
        "停止": "Stop",
        "正在处理…": "Working…",
        "检查于 ": "Checked at ",
        "打开主窗口": "Open window",
        "退出启动器，ChatGPT 继续运行": "Quit launcher; ChatGPT keeps running",
        "退出": "Quit",
        "显示主窗口": "Show main window",
        "Local Route Launcher：运行中": "Local Route Launcher: target running",
        "Local Route Launcher：未运行": "Local Route Launcher: target stopped",
        "界面语言": "Language",
        "语言已切换，网络设置保持不变。": "Language changed. Network settings are unchanged.",
        "保持你有权使用的本地代理运行，再启动兼容应用。": "Keep an authorized local proxy running, then launch a compatible app.",
        "尚未检查": "Not checked",
        "点击“查看代理情况”，检查代理连通性、启动参数和当前连接。": "Choose Check connection to inspect connectivity, launch arguments, and TCP connections.",
        "未找到兼容应用": "No compatible app found",
        "请检查代理设置": "Check proxy settings",
        "配置或运行进程已变化，请重新查看代理情况。": "Settings or running processes changed. Run the connection check again.",
        "设置已保存。停止并重新启动 ChatGPT 后生效。": "Settings saved. Stop and relaunch ChatGPT to apply them.",
        "设置已保存，下次启动 ChatGPT 时生效。": "Settings saved for the next launch of ChatGPT.",
        "选择已安装的 ChatGPT.app（Electron 版本）": "Choose an installed ChatGPT.app (Electron build)",
        "选择": "Choose",
        "取消": "Cancel",
        "已选择 ChatGPT %@。": "Selected ChatGPT %@.",
        "ChatGPT 已在运行。请先停止 ChatGPT，再通过此工具启动。": "ChatGPT is already running. Stop it before launching it with this tool.",
        "ChatGPT 已在运行。请先停止 ChatGPT，再启动，新的代理设置才能生效。": "ChatGPT is already running. Stop and relaunch it to apply the new proxy settings.",
        "macOS 未返回启动结果。": "macOS did not return a launch result.",
        "正在测试代理连接…": "Testing proxy connectivity…",
        "已携带代理设置启动 ChatGPT。可点击“查看代理情况”确认实际连接。": "Launched ChatGPT with proxy settings. Choose Check connection to inspect observed connections.",
        "ChatGPT 已停止。": "ChatGPT has stopped.",
        "已请求 ChatGPT 正常退出，正在等待…": "Requested a graceful quit. Waiting for ChatGPT…",
        "ChatGPT 尚未退出，请检查它的确认窗口或手动退出后重试。": "ChatGPT has not quit. Check for a confirmation dialog or quit it manually.",
        "ChatGPT 未接受退出请求，请在 ChatGPT 中选择“退出”。": "ChatGPT did not accept the quit request. Choose Quit in ChatGPT.",
        "正在检查代理、启动参数和应用连接…": "Checking the proxy, launch arguments, and app connections…",
        "隧道与 TLS 连通": "Tunnel and TLS reachable",
        "连接未通过": "Connection failed",
        "当前地址已传入": "Current address passed",
        "未确认 / 需重启": "Unconfirmed / restart",
        "观察到 %@ 条连接": "%@ connections observed",
        "尚未观察到": "None observed yet",
        "检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。": "Check complete. This is a snapshot; check again after making a request in ChatGPT.",
        "检查完成，部分连接信息无法读取，请查看详细报告。": "Check complete. Some connection details were unavailable; see the report.",
        "代理探测：%@\n状态读取失败：%@": "Proxy probe: %@\nCould not read status: %@",
        "请填写代理地址，例如 127.0.0.1。": "Enter a proxy host, such as 127.0.0.1.",
        "地址只填写 IP 或域名，不要包含 http://、端口、路径或账号密码。": "Enter only an IP address or hostname, without a scheme, port, path, or credentials.",
        "端口必须是 1～65535 之间的整数。": "The port must be an integer between 1 and 65535.",
        "找不到有效的 ChatGPT.app，请重新选择应用。": "No valid ChatGPT.app found. Choose the application again.",
        "所选应用不是可识别的 Electron 版本。本工具不能给旧版原生 ChatGPT 强制设置代理。": "This is not a detectable Electron build. This tool cannot force proxy settings on older native ChatGPT apps.",
        "请选择 ChatGPT 应用。": "Choose a ChatGPT application.",
        "未知版本": "Unknown version",
        "连接读取提示：": "Connection inspection notice: ",
        "连接读取未完成（状态 %@）。": "Connection inspection did not finish (status %@).",
        "HTTP 代理隧道和 TLS 已连通；chatgpt.com 返回 HTTP %@。": "HTTP proxy tunnel and TLS succeeded; chatgpt.com returned HTTP %@. ",
        "网站拒绝了此探测请求，不代表账号或聊天可用。": "The website rejected this probe. This does not establish account or chat access.",
        "代理要求认证。请使用无需账号密码的本地代理端口。": "The proxy requires authentication. Use a local proxy port without credentials.",
        "代理测试未通过。请确认本地代理正在运行、端口正确且服务可用。\n": "Proxy check failed. Confirm that your local proxy is running and its port and service are available.\n",
        "无法读取进程列表：%@": "Could not read the process list: %@",
        "无法读取 PID %@ 的启动参数。": "Could not read launch arguments for PID %@.",
        "检查时间：%@": "Checked at: %@",
        "检查地址：%@": "Endpoint: %@",
        "未运行": "Stopped",
        "运行中（PID %@）": "Running (PID %@)",
        "启动参数：%@": "Launch arguments: %@",
        "与当前代理地址匹配": "Match the current proxy address",
        "未确认匹配": "Match not confirmed",
        "代理探测：%@": "Proxy probe: %@",
        "实际连接：%@": "Observed connections: %@",
        "本次快照未观察到到该代理的 TCP 连接": "No TCP connections to this proxy observed in this snapshot",
        "观察到 %@ 条到该代理的 TCP 连接": "Observed %@ TCP connections to this proxy",
        "ChatGPT 及其子进程的当前 TCP 连接：": "Current TCP connections of ChatGPT and its child processes:",
        "无可见的已建立连接": "No established connections visible",
        "连接快照不证明全部流量均经过代理；域名代理地址与数字 IP 可能无法直接匹配。其他连接也可能来自本地工具或子进程。": "A snapshot does not prove all traffic uses the proxy. Proxy hostnames may not match numeric IP addresses. Other connections may belong to local tools or child processes.",
        "代理探测由启动器独立发起，不等于 ChatGPT 已使用代理。语音 / WebRTC / UDP 与不支持代理环境变量的子进程不在保证范围内。": "The launcher runs the probe independently; it does not prove ChatGPT used the proxy. Voice, WebRTC, UDP, and child processes that ignore proxy environment variables are not guaranteed to use it.",
        "独立开源工具，与 OpenAI 无隶属或背书关系。": "Independent open-source tool. Not affiliated with or endorsed by OpenAI.",
    ]
    static func text(_ key: String, language: AppLanguage = .current, arguments: [String] = []) -> String {
        let template = language == .chinese ? key : (AdditionalTranslations.values[language]?[key] ?? english[key] ?? key)
        let parts = template.components(separatedBy: "%@")
        guard parts.count == arguments.count + 1 else { return template }
        return zip(arguments, parts.dropFirst()).reduce(parts[0]) { $0 + $1.0 + $1.1 }
    }
    static func error(_ error: Error, language: AppLanguage) -> String {
        if let error = error as? LauncherError { return error.localized(in: language) }
        // macOS-owned errors retain the language chosen by the operating system.
        return error.localizedDescription
    }
}
