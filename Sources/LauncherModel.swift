import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Combine

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
    let kind: ApplicationKind
    @Published private(set) var language: AppLanguage
    @Published private(set) var followsSystem: Bool
    @Published private(set) var launchedEndpoint: ProxyEndpoint?
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
    @Published var backendStatus = ""
    @Published var backendOK = false
    @Published var details = ""
    @Published var showDetails = false
    @Published var checkedAt: Date?

    private let previewVersion: String?
    private let defaults: UserDefaults
    private var runningPIDs: [pid_t] = []
    private var lastSnapshot: DiagnosticSnapshot?
    private var lastProbe: ProxyProbe?
    private var statusTimer: Timer?

    init(defaults: UserDefaults = .standard, monitor: Bool = true, previewVersion: String? = nil, kind: ApplicationKind = .chatgpt) {
        self.kind = kind
        followsSystem = defaults.string(forKey: "interfaceLanguage") == nil || defaults.string(forKey: "interfaceLanguage") == "system"
        self.previewVersion = previewVersion
        self.defaults = defaults
        language = AppLanguage.resolve(saved: defaults.string(forKey: "interfaceLanguage"))
        host = defaults.string(forKey: kind.key("proxyHost")) ?? "127.0.0.1"
        port = defaults.string(forKey: kind.key("proxyPort")) ?? "7890"
        appPath = defaults.string(forKey: kind.key("targetPath")) ?? kind.defaultPath
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
        L10n.text(key, language: language, arguments: arguments).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name).replacingOccurrences(of: "OpenAI", with: "OpenAI / Google")
    }

    func setLanguage(_ value: AppLanguage) {
        guard !busy else { return }
        let previousSnapshot = lastSnapshot, previousProbe = lastProbe, previousDate = checkedAt
        followsSystem = false
        language = value
        defaults.set(value.rawValue, forKey: "interfaceLanguage")
        clearDiagnostics()
        if let snapshot = previousSnapshot, let probe = previousProbe, let date = previousDate,
           let endpoint = try? ProxyEndpoint(host: host, port: port) {
            apply(snapshot: snapshot, probe: probe.localized(in: language, kind: kind), endpoint: endpoint, at: date)
        }
        message = text("语言已切换，网络设置保持不变。")
        isError = false
    }

    func followSystemLanguage() {
        guard !busy else { return }
        setLanguage(AppLanguage.resolve(saved: nil))
        followsSystem = true
        defaults.set("system", forKey: "interfaceLanguage")
    }

    deinit { statusTimer?.invalidate() }

    var version: String { (try? TargetApplication(path: appPath, language: language, kind: kind).version) ?? text("未找到兼容应用") }
    var endpointLabel: String { (running ? launchedEndpoint?.authority : nil) ?? (try? ProxyEndpoint(host: host, port: port).authority) ?? text("请检查代理设置") }
    var launcherVersion: String { previewVersion ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }

    func updateRunning() {
        guard previewVersion == nil else { return }
        let pids = (try? TargetApplication(path: appPath, language: language, kind: kind)).map(ApplicationControl.running)?.map(\.processIdentifier).sorted() ?? []
        if pids != runningPIDs {
            clearDiagnostics()
            launchedEndpoint = nil
            runningPIDs = pids
        }
        running = !pids.isEmpty
        if !running { launchedEndpoint = nil }
    }

    func clearDiagnostics() {
        lastSnapshot = nil; lastProbe = nil
        checkedAt = nil
        proxyStatus = text("尚未检查"); parameterStatus = text("尚未检查"); connectionStatus = text("尚未检查")
        proxyOK = false; parameterOK = false; connectionOK = false
        backendOK = false; backendStatus = text("尚未检查")
        details = text("配置或运行进程已变化，请重新查看代理情况。")
    }

    private func notify(_ text: String, error: Bool = false) {
        message = text; isError = error
    }

    @discardableResult
    private func persist() throws -> ProxyEndpoint {
        let endpoint = try ProxyEndpoint(host: host, port: port)
        host = endpoint.host; port = String(endpoint.port)
        defaults.set(host, forKey: kind.key("proxyHost"))
        defaults.set(port, forKey: kind.key("proxyPort"))
        defaults.set(appPath, forKey: kind.key("targetPath"))
        return endpoint
    }

    func save() {
        do {
            _ = try persist()
            notify(running ? text("设置已保存。停止并重新启动 ChatGPT 后生效。") : text("设置已保存，下次启动 ChatGPT 时生效。"))
        } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
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
            let target = try TargetApplication(path: url.path, language: language, kind: kind)
            appPath = target.url.path
            defaults.set(appPath, forKey: kind.key("targetPath"))
            clearDiagnostics(); updateRunning()
            notify(text("已选择 ChatGPT %@。" , String(target.version)))
        } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
    }

    func start() {
        guard !busy else { return }
        do {
            let endpoint = try persist()
            let target = try TargetApplication(path: appPath, language: language, kind: kind)
            guard NSRunningApplication.runningApplications(withBundleIdentifier: target.identifier).isEmpty else {
                notify(text("ChatGPT 已在运行。请先停止 ChatGPT，再通过此工具启动。"), error: true)
                return
            }
            busy = true
            notify(text("正在测试代理连接…"))
            let selectedLanguage = language
            Task {
                defer { busy = false; updateRunning() }
                let probe = await Task.detached { ProxyProbe.check(endpoint, language: selectedLanguage, kind: target.kind) }.value
                guard probe.usable else { notify(probe.description, error: true); return }
                do {
                    _ = try await ApplicationControl.launch(target, endpoint: endpoint)
                    updateRunning()
                    launchedEndpoint = endpoint
                    notify(text("已携带代理设置启动 ChatGPT。可点击“查看代理情况”确认实际连接。"))
                } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
            }
        } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
    }

    func stop() {
        guard !busy else { return }
        do {
            let target = try TargetApplication(path: appPath, language: language, kind: kind)
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
        } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
    }

    private func apply(snapshot: DiagnosticSnapshot, probe: ProxyProbe, endpoint: ProxyEndpoint, at date: Date) {
        lastSnapshot = snapshot; lastProbe = probe
        proxyOK = probe.usable
        proxyStatus = probe.usable ? text("隧道与 TLS 连通") : text("连接未通过")
        parameterOK = snapshot.configured
        parameterStatus = snapshot.mainPIDs.isEmpty ? text("ChatGPT 未运行") : (snapshot.configured ? text("当前地址已传入") : text("未确认 / 需重启"))
        let count = snapshot.connections.filter { endpoint.matches(remote: $0.remote) }.count
        let backendCount = snapshot.connections.filter { snapshot.backendPIDs.contains($0.pid) && endpoint.matches(remote: $0.remote) }.count
        backendOK = backendCount > 0
        backendStatus = backendCount > 0 ? text("观察到 %@ 条连接", String(backendCount)) : text("尚未观察到")
        connectionOK = count > 0
        connectionStatus = count > 0 ? text("观察到 %@ 条连接" , String(count)) : text("尚未观察到")
        details = snapshot.report(endpoint: endpoint, probe: probe, language: language, kind: kind, checkedAt: date)
        checkedAt = date
    }

    func refresh() {
        guard !busy else { return }
        do {
            let endpoint = try ProxyEndpoint(host: host, port: port)
            let target = try TargetApplication(path: appPath, language: language, kind: kind)
            busy = true
            notify(text("正在检查代理、启动参数和应用连接…"))
            let selectedLanguage = language
            Task {
                defer { busy = false }
                let probeTask = Task.detached { ProxyProbe.check(endpoint, language: selectedLanguage, kind: target.kind) }
                let snapshotTask = Task.detached { try DiagnosticSnapshot.collect(target: target, endpoint: endpoint, language: selectedLanguage) }
                let probe = await probeTask.value
                do {
                    let snapshot = try await snapshotTask.value
                    updateRunning()
                    apply(snapshot: snapshot, probe: probe, endpoint: endpoint, at: Date())
                    notify(snapshot.warnings.isEmpty ? text("检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。") : text("检查完成，部分连接信息无法读取，请查看详细报告。"))
                } catch {
                    clearDiagnostics()
                    details = text("代理探测：%@\n状态读取失败：%@" , String(probe.description), L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name))
                    notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true)
                }
            }
        } catch { notify(L10n.error(error, language: language).replacingOccurrences(of: "ChatGPT.app", with: kind.bundleName + ".app").replacingOccurrences(of: "ChatGPT", with: kind.name), error: true) }
    }
}

/// Owns one independent model per app. Language is shared; draft configuration and
/// asynchronous results never move to another app when the selection changes.
@MainActor
final class LauncherStore: ObservableObject {
    @Published var selected: ApplicationKind { didSet { defaults.set(selected.rawValue, forKey: "selectedApplication") } }
    let models: [ApplicationKind: LauncherModel]
    private let defaults: UserDefaults
    private var subscriptions: Set<AnyCancellable> = []
    var current: LauncherModel { models[selected]! }
    var busy: Bool { models.values.contains { $0.busy } }
    var anyRunning: Bool { models.values.contains { $0.running } }

    init(defaults: UserDefaults = .standard, monitor: Bool = true, previewVersion: String? = nil) {
        self.defaults = defaults
        selected = ApplicationKind(rawValue: defaults.string(forKey: "selectedApplication") ?? "") ?? .chatgpt
        models = Dictionary(uniqueKeysWithValues: ApplicationKind.allCases.map {
            ($0, LauncherModel(defaults: defaults, monitor: monitor, previewVersion: previewVersion, kind: $0))
        })
        for model in models.values {
            model.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        }
    }
    func setLanguage(_ language: AppLanguage?) {
        guard !busy else { return }
        for model in models.values {
            if let language { model.setLanguage(language) } else { model.followSystemLanguage() }
        }
    }
}
