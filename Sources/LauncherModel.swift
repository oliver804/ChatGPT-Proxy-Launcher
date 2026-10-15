import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ApplicationControl {
    static func running(_ target: TargetApplication) -> [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: target.identifier).filter {
            $0.bundleURL?.standardizedFileURL.resolvingSymlinksInPath() == target.url && !$0.isTerminated
        }
    }

    @MainActor
    static func launch(_ target: TargetApplication, endpoint: ProxyEndpoint) async throws -> NSRunningApplication {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: target.identifier).isEmpty else {
            throw LauncherError("ChatGPT 已在运行。请先停止 ChatGPT，再启动，新的代理设置才能生效。")
        }
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = endpoint.launchArguments
        config.environment = endpoint.environment
        config.activates = true
        return try await withCheckedThrowingContinuation { continuation in
            NSWorkspace.shared.openApplication(at: target.url, configuration: config) { app, error in
                if let error { continuation.resume(throwing: error) }
                else if let app { continuation.resume(returning: app) }
                else { continuation.resume(throwing: LauncherError("macOS 未返回启动结果。")) }
            }
        }
    }
}

@MainActor
final class LauncherModel: ObservableObject {
    @Published private(set) var language: AppLanguage
    @Published var host: String { didSet { if host != oldValue { clearDiagnostics() } } }
    @Published var port: String { didSet { if port != oldValue { clearDiagnostics() } } }
    @Published var appPath: String
    @Published var running = false
    @Published var busy = false
    @Published var message = ""
    @Published var isError = false
    @Published var proxyStatus = ""
    @Published var parameterStatus = ""
    @Published var connectionStatus = ""
    @Published var proxyOK = false
    @Published var parameterOK = false
    @Published var connectionOK = false
    @Published var details = ""
    @Published var showDetails = false
    @Published var checkedAt: Date?

    private let previewVersion: String?
    private let defaults: UserDefaults
    private var runningPIDs: [pid_t] = []
    private var statusTimer: Timer?

    init(defaults: UserDefaults = .standard, monitor: Bool = true, previewVersion: String? = nil) {
        self.previewVersion = previewVersion
        self.defaults = defaults
        language = AppLanguage.resolve(saved: defaults.string(forKey: "interfaceLanguage"))
        host = defaults.string(forKey: "proxyHost") ?? "127.0.0.1"
        port = defaults.string(forKey: "proxyPort") ?? "7890"
        appPath = defaults.string(forKey: "targetPath") ?? "/Applications/ChatGPT.app"
        clearDiagnostics()
        message = text("保持你有权使用的本地代理运行，再启动兼容应用。")
        updateRunning()
        if monitor {
            let timer = Timer(timeInterval: 3, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, !self.busy else { return }
                    self.updateRunning()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            statusTimer = timer
        }
    }

    func text(_ key: String, _ arguments: String...) -> String {
        L10n.text(key, language: language, arguments: arguments)
    }

    func setLanguage(_ value: AppLanguage) {
        guard !busy, language != value else { return }
        language = value
        defaults.set(value.rawValue, forKey: "interfaceLanguage")
        clearDiagnostics()
        message = text("语言已切换，网络设置保持不变。")
        isError = false
    }

    deinit { statusTimer?.invalidate() }

    var version: String { (try? TargetApplication(path: appPath, language: language).version) ?? text("未找到兼容应用") }
    var endpointLabel: String { (try? ProxyEndpoint(host: host, port: port).authority) ?? text("请检查代理设置") }
    var launcherVersion: String { previewVersion ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }

    func updateRunning() {
        guard previewVersion == nil else { return }
        let pids = (try? TargetApplication(path: appPath, language: language)).map(ApplicationControl.running)?.map(\.processIdentifier).sorted() ?? []
        if pids != runningPIDs {
            clearDiagnostics()
            runningPIDs = pids
        }
        running = !pids.isEmpty
    }

    func clearDiagnostics() {
        checkedAt = nil
        proxyStatus = text("尚未检查"); parameterStatus = text("尚未检查"); connectionStatus = text("尚未检查")
        proxyOK = false; parameterOK = false; connectionOK = false
        details = text("配置或运行进程已变化，请重新查看代理情况。")
    }

    private func notify(_ text: String, error: Bool = false) {
        message = text; isError = error
    }

    @discardableResult
    private func persist() throws -> ProxyEndpoint {
        let endpoint = try ProxyEndpoint(host: host, port: port)
        host = endpoint.host; port = String(endpoint.port)
        defaults.set(host, forKey: "proxyHost")
        defaults.set(port, forKey: "proxyPort")
        defaults.set(appPath, forKey: "targetPath")
        return endpoint
    }

    func save() {
        do {
            _ = try persist()
            notify(running ? text("设置已保存。停止并重新启动 ChatGPT 后生效。") : text("设置已保存，下次启动 ChatGPT 时生效。"))
        } catch { notify(L10n.error(error, language: language), error: true) }
    }

    func chooseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.title = "Local Route Launcher"
        panel.prompt = text("选择")
        panel.message = text("选择已安装的 ChatGPT.app（Electron 版本）")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let target = try TargetApplication(path: url.path, language: language)
            appPath = target.url.path
            defaults.set(appPath, forKey: "targetPath")
            clearDiagnostics(); updateRunning()
            notify(text("已选择 ChatGPT %@。" , String(target.version)))
        } catch { notify(L10n.error(error, language: language), error: true) }
    }

    func start() {
        guard !busy else { return }
        do {
            let endpoint = try persist()
            let target = try TargetApplication(path: appPath, language: language)
            guard NSRunningApplication.runningApplications(withBundleIdentifier: target.identifier).isEmpty else {
                notify(text("ChatGPT 已在运行。请先停止 ChatGPT，再通过此工具启动。"), error: true)
                return
            }
            busy = true
            notify(text("正在测试代理连接…"))
            let selectedLanguage = language
            Task {
                defer { busy = false; updateRunning() }
                let probe = await Task.detached { ProxyProbe.check(endpoint, language: selectedLanguage) }.value
                guard probe.usable else { notify(probe.description, error: true); return }
                do {
                    _ = try await ApplicationControl.launch(target, endpoint: endpoint)
                    updateRunning()
                    notify(text("已携带代理设置启动 ChatGPT。可点击“查看代理情况”确认实际连接。"))
                } catch { notify(L10n.error(error, language: language), error: true) }
            }
        } catch { notify(L10n.error(error, language: language), error: true) }
    }

    func stop() {
        guard !busy else { return }
        do {
            let target = try TargetApplication(path: appPath, language: language)
            let apps = ApplicationControl.running(target)
            guard !apps.isEmpty else { updateRunning(); notify(text("ChatGPT 已停止。")); return }
            busy = true
            let accepted = apps.map { $0.terminate() }.allSatisfy { $0 }
            notify(text("已请求 ChatGPT 正常退出，正在等待…"))
            Task {
                defer { busy = false; updateRunning() }
                for _ in 0..<30 {
                    if ApplicationControl.running(target).isEmpty {
                        notify(text("ChatGPT 已停止。"))
                        return
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                notify(accepted ? text("ChatGPT 尚未退出，请检查它的确认窗口或手动退出后重试。") : text("ChatGPT 未接受退出请求，请在 ChatGPT 中选择“退出”。"), error: true)
            }
        } catch { notify(L10n.error(error, language: language), error: true) }
    }

    func refresh() {
        guard !busy else { return }
        do {
            let endpoint = try ProxyEndpoint(host: host, port: port)
            let target = try TargetApplication(path: appPath, language: language)
            busy = true
            notify(text("正在检查代理、启动参数和应用连接…"))
            let selectedLanguage = language
            Task {
                defer { busy = false }
                let probeTask = Task.detached { ProxyProbe.check(endpoint, language: selectedLanguage) }
                let snapshotTask = Task.detached { try DiagnosticSnapshot.collect(target: target, endpoint: endpoint, language: selectedLanguage) }
                let probe = await probeTask.value
                do {
                    let snapshot = try await snapshotTask.value
                    updateRunning()
                    proxyOK = probe.usable
                    proxyStatus = probe.usable ? text("隧道与 TLS 连通") : text("连接未通过")
                    parameterOK = snapshot.configured
                    parameterStatus = snapshot.mainPIDs.isEmpty ? text("ChatGPT 未运行") : (snapshot.configured ? text("当前地址已传入") : text("未确认 / 需重启"))
                    let count = snapshot.connections.filter { endpoint.matches(remote: $0.remote) }.count
                    connectionOK = count > 0
                    connectionStatus = count > 0 ? text("观察到 %@ 条连接" , String(count)) : text("尚未观察到")
                    details = snapshot.report(endpoint: endpoint, probe: probe, language: language)
                    checkedAt = Date()
                    notify(snapshot.warnings.isEmpty ? text("检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。") : text("检查完成，部分连接信息无法读取，请查看详细报告。"))
                } catch {
                    clearDiagnostics()
                    details = text("代理探测：%@\n状态读取失败：%@" , String(probe.description), L10n.error(error, language: language))
                    notify(L10n.error(error, language: language), error: true)
                }
            }
        } catch { notify(L10n.error(error, language: language), error: true) }
    }
}
