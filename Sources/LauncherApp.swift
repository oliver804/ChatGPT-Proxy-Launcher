import SwiftUI
import AppKit

// Dynamic colors keep both the window and menu panel legible in Light and Dark Mode.
private enum Palette {
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 0.34, green: 0.83, blue: 0.68, alpha: 1)
            : NSColor(calibratedRed: 0.04, green: 0.44, blue: 0.34, alpha: 1)
    })
    static let canvas = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 0.095, green: 0.11, blue: 0.105, alpha: 1)
            : NSColor(calibratedRed: 0.956, green: 0.963, blue: 0.95, alpha: 1)
    })
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let border = Color.primary.opacity(0.065)
}

private struct Surface: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.border))
    }
}

private struct ActionStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(prominent ? Color(red: 0.055, green: 0.44, blue: 0.34) : Color.primary.opacity(0.055),
                        in: RoundedRectangle(cornerRadius: 11))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.36)
            .contentShape(RoundedRectangle(cornerRadius: 11))
    }
}

private struct RunningBadge: View {
    var running: Bool
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(running ? Palette.accent : Color.secondary).frame(width: 6, height: 6)
            Text(running ? "ChatGPT 运行中" : "ChatGPT 未运行").font(.system(size: 11, weight: .medium))
        }.foregroundStyle(running ? Palette.accent : .secondary)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background((running ? Palette.accent : Color.secondary).opacity(0.08), in: Capsule())
    }
}

private struct StatusTile: View {
    var title: String
    var value: String
    var success: Bool
    var checked: Bool
    var symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: success ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 13)).foregroundStyle(success ? Palette.accent : Color.secondary.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 12, weight: .medium)).lineLimit(1).minimumScaleFactor(0.85)
            }
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(success && checked ? Palette.accent.opacity(0.065) : Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LauncherView: View {
    @ObservedObject var model: LauncherModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            controlCard
            settingsCard
            diagnosticsCard
            footer
        }
        .padding(.horizontal, 28).padding(.top, 34).padding(.bottom, 20)
        .frame(width: 720)
        .background(Palette.canvas)
        .background(MainWindowPresence())
        .tint(Palette.accent)
        .sheet(isPresented: $model.showDetails) { reportSheet }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BrandMark()
            VStack(alignment: .leading, spacing: 4) {
                Text("ChatGPT 代理").font(.system(size: 23, weight: .semibold))
                Text("独立连接，轻松启动").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("PROXY LAUNCHER").font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(1.5).foregroundStyle(.tertiary)
        }.padding(.bottom, 2)
    }

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.running ? "连接，从这里开始。" : "为 ChatGPT 准备就绪。")
                        .font(.system(size: 20, weight: .semibold))
                    Text("使用专属代理入口，无需开启 TUN。")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                RunningBadge(running: model.running)
            }
            HStack(spacing: 12) {
                Label("ChatGPT", systemImage: "bubble.left.and.bubble.right")
                    .font(.system(size: 12, weight: .medium))
                Rectangle().fill(Palette.accent.opacity(0.2)).frame(height: 1)
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.accent)
                Text(model.endpointLabel).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(Palette.accent)
                Text("HTTP 代理").font(.system(size: 10)).foregroundStyle(.secondary)
            }.padding(13).background(Palette.accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 10) {
                Button(action: model.start) { Label("启动 ChatGPT", systemImage: "play.fill") }
                    .buttonStyle(ActionStyle(prominent: true)).disabled(model.busy || model.running)
                Button(action: model.stop) { Label("停止 ChatGPT", systemImage: "stop.fill") }
                    .buttonStyle(ActionStyle()).disabled(model.busy || !model.running)
            }
        }.modifier(Surface())
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("代理设置", systemImage: "slider.horizontal.3").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("更改后需重新启动 ChatGPT").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 12) {
                proxyField("代理地址", placeholder: "127.0.0.1", text: $model.host)
                proxyField("混合端口", placeholder: "7890", text: $model.port).frame(width: 95)
                Button("保存设置", action: model.save).controlSize(.large).frame(height: 36)
            }
            HStack(spacing: 7) {
                Image(systemName: "app").foregroundStyle(.tertiary)
                Text(model.appPath).lineLimit(1).truncationMode(.middle).help("ChatGPT 版本：\(model.version)")
                Spacer(minLength: 12)
                Button("选择应用", action: model.chooseApplication).buttonStyle(.link)
            }.font(.system(size: 11)).foregroundStyle(.secondary)
        }.modifier(Surface()).disabled(model.busy)
    }

    private func proxyField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            TextField(placeholder, text: text).textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 11).frame(height: 36)
                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.border))
                .accessibilityLabel(title)
        }
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("连接检查", systemImage: "waveform.path.ecg").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: model.refresh) { Label("查看代理情况", systemImage: "arrow.clockwise") }
                    .buttonStyle(.link).font(.system(size: 11)).disabled(model.busy)
            }
            HStack(spacing: 10) {
                StatusTile(title: "代理连通", value: model.proxyStatus, success: model.proxyOK, checked: model.checkedAt != nil, symbol: "network")
                StatusTile(title: "启动参数", value: model.parameterStatus, success: model.parameterOK, checked: model.checkedAt != nil, symbol: "slider.horizontal.3")
                StatusTile(title: "实际连接", value: model.connectionStatus, success: model.connectionOK, checked: model.checkedAt != nil, symbol: "arrow.left.arrow.right")
            }
            HStack {
                Text(model.checkedAt.map { "最近检查 " + $0.formatted(date: .omitted, time: .standard) } ?? "检查代理连通性、启动配置与实际连接")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button("详细报告") { model.showDetails = true }.buttonStyle(.link).font(.system(size: 11))
            }
        }.modifier(Surface())
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 8) {
                if model.busy { ProgressView().controlSize(.small) }
                else { Image(systemName: model.isError ? "exclamationmark.circle.fill" : "info.circle").font(.system(size: 12)) }
                Text(model.message).font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
            }.foregroundStyle(model.isError ? Color.orange : Color.secondary)
                .frame(minHeight: 27, alignment: .topLeading)
            HStack(spacing: 5) {
                Image(systemName: "menubar.rectangle")
                Text("关闭窗口后，仍可从菜单栏访问")
                Spacer()
                Text("v\(model.launcherVersion)")
            }.font(.system(size: 10)).foregroundStyle(.secondary)
        }.padding(.horizontal, 3)
    }

    private var reportSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("代理检查报告", systemImage: "doc.text.magnifyingglass").font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("完成") { model.showDetails = false }.keyboardShortcut(.defaultAction)
            }
            ScrollView {
                Text(model.details).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            }.background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
            Button { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(model.details, forType: .string) }
                label: { Label("复制报告", systemImage: "doc.on.doc") }
        }.padding(24).frame(width: 650, height: 470)
    }
}

struct MenuPanel: View {
    @ObservedObject var model: LauncherModel
    @Environment(\.openWindow) private var openWindow

    private func showMain() {
        DockPresence.shared.prepareToShow()
        openWindow(id: "main")
        DockPresence.shared.activateMainWindow()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                BrandMark(size: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text("ChatGPT 代理").font(.system(size: 14, weight: .semibold))
                    Text(model.endpointLabel).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            RunningBadge(running: model.running)
            HStack(spacing: 8) {
                Button(action: model.start) { Label("启动", systemImage: "play.fill") }
                    .buttonStyle(ActionStyle(prominent: true)).disabled(model.busy || model.running)
                Button(action: model.stop) { Label("停止", systemImage: "stop.fill") }
                    .buttonStyle(ActionStyle()).disabled(model.busy || !model.running)
            }
            VStack(spacing: 9) {
                menuStatus("代理连通", model.proxyStatus, model.proxyOK)
                menuStatus("启动参数", model.parameterStatus, model.parameterOK)
                menuStatus("实际连接", model.connectionStatus, model.connectionOK)
            }.padding(12).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
            Button(action: model.refresh) { Label(model.busy ? "正在处理…" : "查看代理情况", systemImage: "arrow.clockwise").frame(maxWidth: .infinity) }
                .disabled(model.busy).controlSize(.large)
            if model.busy || model.isError {
                Text(model.message).font(.system(size: 11)).foregroundStyle(model.isError ? Color.orange : .secondary)
                    .lineLimit(3).help(model.message)
            } else if let date = model.checkedAt {
                Text("检查于 " + date.formatted(date: .omitted, time: .standard))
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Button(action: showMain) { Label("打开主窗口", systemImage: "macwindow") }.buttonStyle(.plain)
                Spacer()
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .buttonStyle(.plain).help("退出启动器，ChatGPT 继续运行")
                    .accessibilityLabel("退出启动器").disabled(model.busy)
            }.font(.system(size: 12)).foregroundStyle(.secondary)
        }.padding(20).frame(width: 320).background(Palette.canvas).tint(Palette.accent)
            .onAppear { model.updateRunning() }
    }

    private func menuStatus(_ title: String, _ value: String, _ success: Bool) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(success ? Palette.accent : .secondary)
        }.font(.system(size: 11))
    }
}

@MainActor
final class DockPresence {
    static let shared = DockPresence()
    private weak var mainWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []

    func track(_ window: NSWindow) {
        guard mainWindow !== window else { return }
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        mainWindow = window
        prepareToShow()
        // Observe only the main window: dismissing the menu panel or a sheet must not hide the Dock icon.
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.mainWindow?.isVisible != true else { return }
                NSApp.setActivationPolicy(.accessory)
            }
        })
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.mainWindow?.isVisible == true else { return }
                self.prepareToShow()
            }
        })
    }

    func prepareToShow() {
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
    }

    func activateMainWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.mainWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

private struct MainWindowPresence: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowObserverView { WindowObserverView() }
    func updateNSView(_ nsView: WindowObserverView, context: Context) {}

    final class WindowObserverView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { DockPresence.shared.track(window) }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { NSApp.activate(ignoringOtherApps: true) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

private struct LauncherCommands: SwiftUI.Commands {
    @Environment(\.openWindow) private var openWindow
    var body: some SwiftUI.Commands {
        CommandGroup(replacing: .newItem) {
            Button("显示主窗口") {
                DockPresence.shared.prepareToShow()
                openWindow(id: "main")
                DockPresence.shared.activateMainWindow()
            }.keyboardShortcut("0", modifiers: .command)
        }
    }
}

struct LauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = LauncherModel()
    var body: some Scene {
        Window("ChatGPT 代理启动器", id: "main") { LauncherView(model: model) }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .commands { LauncherCommands() }
        MenuBarExtra {
            MenuPanel(model: model)
        } label: {
            Image(systemName: BrandIdentity.symbolName)
                .accessibilityLabel(model.running ? "ChatGPT 代理：运行中" : "ChatGPT 代理：未运行")
        }.menuBarExtraStyle(.window)
    }
}

#if !RENDER_PREVIEWS
@main
enum EntryPoint {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--diagnose") {
            do {
                let endpoint = try ProxyEndpoint(host: "127.0.0.1", port: "7890")
                let target = try TargetApplication(path: "/Applications/ChatGPT.app")
                let snapshot = try DiagnosticSnapshot.collect(target: target, endpoint: endpoint)
                print(snapshot.report(endpoint: endpoint, probe: ProxyProbe.check(endpoint)))
            } catch { print(error.localizedDescription); exit(1) }
        } else { LauncherApp.main() }
    }
}
#endif
