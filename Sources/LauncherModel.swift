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
    @Published var host: String { didSet { if host != oldValue { clearDiagnostics() } } }
    @Published var port: String { didSet { if port != oldValue { clearDiagnostics() } } }
    @Published var appPath: String
    @Published var running = false
    @Published var busy = false
    @Published var message = "保留 Clash Verge 运行，使用它的混合代理端口。"
    @Published var isError = false
    @Published var proxyStatus = "尚未检查"
    @Published var parameterStatus = "尚未检查"
    @Published var connectionStatus = "尚未检查"
    @Published var proxyOK = false
    @Published var parameterOK = false
    @Published var connectionOK = false
    @Published var details = "点击“查看代理情况”，检查代理连通性、启动参数和当前连接。"
    @Published var showDetails = false
    @Published var checkedAt: Date?

    private let defaults: UserDefaults
    private var runningPIDs: [pid_t] = []
    private var statusTimer: Timer?

    init(defaults: UserDefaults = .standard, monitor: Bool = true) {
        self.defaults = defaults
        host = defaults.string(forKey: "proxyHost") ?? "127.0.0.1"
        port = defaults.string(forKey: "proxyPort") ?? "7890"
        appPath = defaults.string(forKey: "targetPath") ?? "/Applications/ChatGPT.app"
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

    deinit { statusTimer?.invalidate() }

    var version: String { (try? TargetApplication(path: appPath).version) ?? "未找到兼容应用" }
    var endpointLabel: String { (try? ProxyEndpoint(host: host, port: port).authority) ?? "请检查代理设置" }
    var launcherVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }

    func updateRunning() {
        let pids = (try? TargetApplication(path: appPath)).map(ApplicationControl.running)?.map(\.processIdentifier).sorted() ?? []
        if pids != runningPIDs {
            clearDiagnostics()
            runningPIDs = pids
        }
        running = !pids.isEmpty
    }

    func clearDiagnostics() {
        checkedAt = nil
        proxyStatus = "尚未检查"; parameterStatus = "尚未检查"; connectionStatus = "尚未检查"
        proxyOK = false; parameterOK = false; connectionOK = false
        details = "配置或运行进程已变化，请重新查看代理情况。"
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
            notify(running ? "设置已保存。停止并重新启动 ChatGPT 后生效。" : "设置已保存，下次启动 ChatGPT 时生效。")
        } catch { notify(error.localizedDescription, error: true) }
    }

    func chooseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "选择已安装的 ChatGPT.app（Electron 版本）"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let target = try TargetApplication(path: url.path)
            appPath = target.url.path
            defaults.set(appPath, forKey: "targetPath")
            clearDiagnostics(); updateRunning()
            notify("已选择 ChatGPT \(target.version)。")
        } catch { notify(error.localizedDescription, error: true) }
    }

    func start() {
        guard !busy else { return }
        do {
            let endpoint = try persist()
            let target = try TargetApplication(path: appPath)
            guard NSRunningApplication.runningApplications(withBundleIdentifier: target.identifier).isEmpty else {
                notify("ChatGPT 已在运行。请先停止 ChatGPT，再通过此工具启动。", error: true)
                return
            }
            busy = true
            notify("正在测试代理连接…")
            Task {
                defer { busy = false; updateRunning() }
                let probe = await Task.detached { ProxyProbe.check(endpoint) }.value
                guard probe.usable else { notify(probe.description, error: true); return }
                do {
                    _ = try await ApplicationControl.launch(target, endpoint: endpoint)
                    updateRunning()
                    notify("已携带代理设置启动 ChatGPT。可点击“查看代理情况”确认实际连接。")
                } catch { notify(error.localizedDescription, error: true) }
            }
        } catch { notify(error.localizedDescription, error: true) }
    }

    func stop() {
        guard !busy else { return }
        do {
            let target = try TargetApplication(path: appPath)
            let apps = ApplicationControl.running(target)
            guard !apps.isEmpty else { updateRunning(); notify("ChatGPT 已停止。"); return }
            busy = true
            let accepted = apps.map { $0.terminate() }.allSatisfy { $0 }
            notify("已请求 ChatGPT 正常退出，正在等待…")
            Task {
                defer { busy = false; updateRunning() }
                for _ in 0..<30 {
                    if ApplicationControl.running(target).isEmpty {
                        notify("ChatGPT 已停止。")
                        return
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                notify(accepted ? "ChatGPT 尚未退出，请检查它的确认窗口或手动退出后重试。" : "ChatGPT 未接受退出请求，请在 ChatGPT 中选择“退出”。", error: true)
            }
        } catch { notify(error.localizedDescription, error: true) }
    }

    func refresh() {
        guard !busy else { return }
        do {
            let endpoint = try ProxyEndpoint(host: host, port: port)
            let target = try TargetApplication(path: appPath)
            busy = true
            notify("正在检查代理、启动参数和应用连接…")
            Task {
                defer { busy = false }
                let probeTask = Task.detached { ProxyProbe.check(endpoint) }
                let snapshotTask = Task.detached { try DiagnosticSnapshot.collect(target: target, endpoint: endpoint) }
                let probe = await probeTask.value
                do {
                    let snapshot = try await snapshotTask.value
                    updateRunning()
                    proxyOK = probe.usable
                    proxyStatus = probe.usable ? "隧道与 TLS 连通" : "连接未通过"
                    parameterOK = snapshot.configured
                    parameterStatus = snapshot.mainPIDs.isEmpty ? "ChatGPT 未运行" : (snapshot.configured ? "当前地址已传入" : "未确认 / 需重启")
                    let count = snapshot.connections.filter { endpoint.matches(remote: $0.remote) }.count
                    connectionOK = count > 0
                    connectionStatus = count > 0 ? "观察到 \(count) 条连接" : "尚未观察到"
                    details = snapshot.report(endpoint: endpoint, probe: probe)
                    checkedAt = Date()
                    notify(snapshot.warnings.isEmpty ? "检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。" : "检查完成，部分连接信息无法读取，请查看详细报告。")
                } catch {
                    clearDiagnostics()
                    details = "代理探测：\(probe.description)\n状态读取失败：\(error.localizedDescription)"
                    notify(error.localizedDescription, error: true)
                }
            }
        } catch { notify(error.localizedDescription, error: true) }
    }
}
