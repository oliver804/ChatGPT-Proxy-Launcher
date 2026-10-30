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
    @ObservedObject var model: LauncherModel
    var running: Bool { model.running }
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(running ? Palette.accent : Color.secondary).frame(width: 6, height: 6)
            Text(running ? model.text("ChatGPT 运行中") : model.text("ChatGPT 未运行")).font(.system(size: 11, weight: .medium))
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
        VStack(spacing: 0) {
        ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            header
            controlCard
            settingsCard
            diagnosticsCard
        }
        .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 14)
        }
        footer.padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 14)
        }
        .frame(minWidth: 660, maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
        .background(MainWindowPresence())
        .tint(Palette.accent)
        .environment(\.locale, model.language.locale)
        .environment(\.layoutDirection, model.language.isRightToLeft ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $model.showDetails) { reportSheet }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.kind.name).font(.system(size: 23, weight: .semibold))
                Text(model.text("独立连接，轻松启动")).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(model.version).font(.system(size: 11)).foregroundStyle(.secondary)
        }.padding(.bottom, 2)
    }

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.text("连接，从这里开始。"))
                        .font(.system(size: 20, weight: .semibold))
                    Text(model.text("仅为兼容应用传入设置，不修改系统网络。"))
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                RunningBadge(model: model)
            }
            HStack(spacing: 12) {
                Label(model.kind.name, systemImage: model.kind.symbol)
                    .font(.system(size: 12, weight: .medium))
                Rectangle().fill(Palette.accent.opacity(0.2)).frame(height: 1)
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.accent)
                Text(model.endpointLabel).environment(\.layoutDirection, .leftToRight).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(Palette.accent)
                Text(model.text("HTTP 代理")).font(.system(size: 10)).foregroundStyle(.secondary)
            }.environment(\.layoutDirection, .leftToRight).padding(13).background(Palette.accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 10) {
                Button(action: model.start) { Label(model.text("启动 ChatGPT"), systemImage: "play.fill") }
                    .buttonStyle(ActionStyle(prominent: true)).disabled(model.busy || model.running)
                Button(action: model.stop) { Label(model.text("停止 ChatGPT"), systemImage: "stop.fill") }
                    .buttonStyle(ActionStyle()).disabled(model.busy || !model.running)
            }
        }.modifier(Surface())
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(model.text("代理设置"), systemImage: "slider.horizontal.3").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(model.text("更改后需重新启动 ChatGPT")).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 12) {
                proxyField(model.text("代理地址"), placeholder: "127.0.0.1", text: $model.host)
                proxyField(model.text("端口"), placeholder: "7890", text: $model.port).frame(width: 95)
                Button(model.text("保存设置"), action: model.save).controlSize(.large).frame(height: 36)
            }
            HStack(spacing: 7) {
                Image(systemName: "app").foregroundStyle(.tertiary)
                Text(model.appPath).environment(\.layoutDirection, .leftToRight).lineLimit(1).truncationMode(.middle).help(model.text("ChatGPT 版本：%@" , String(model.version)))
                Spacer(minLength: 12)
                Button(model.text("选择应用"), action: model.chooseApplication).buttonStyle(.link)
            }.font(.system(size: 11)).foregroundStyle(.secondary)
        }.modifier(Surface()).disabled(model.busy)
    }

    private func proxyField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            TextField(placeholder, text: text).textFieldStyle(.plain)
                .environment(\.layoutDirection, .leftToRight)
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
                Label(model.text("连接检查"), systemImage: "waveform.path.ecg").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: model.refresh) { Label(model.text("查看代理情况"), systemImage: "arrow.clockwise") }
                    .buttonStyle(.link).font(.system(size: 11)).disabled(model.busy)
            }
            HStack(spacing: 10) {
                StatusTile(title: model.text("代理连通"), value: model.proxyStatus, success: model.proxyOK, checked: model.checkedAt != nil, symbol: "network")
                StatusTile(title: model.text("启动参数"), value: model.parameterStatus, success: model.parameterOK, checked: model.checkedAt != nil, symbol: "slider.horizontal.3")
                StatusTile(title: model.text("实际连接"), value: model.connectionStatus, success: model.connectionOK, checked: model.checkedAt != nil, symbol: "arrow.left.arrow.right")
            }
            if model.kind != .chatgpt {
                HStack {
                    Label(model.text("后台服务"), systemImage: "server.rack")
                    Spacer()
                    Text(model.backendStatus).foregroundStyle(model.backendOK ? Palette.accent : .secondary)
                }.font(.system(size: 11))
                Text(model.text("后台连接尚需实际请求验证；未观察到不等于未使用代理。")).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            HStack {
                Text(model.checkedAt.map { model.text("最近检查 ") + $0.formatted(date: .omitted, time: .standard) } ?? model.text("检查代理连通性、启动配置与实际连接"))
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button(model.text("详细报告")) { model.showDetails = true }.buttonStyle(.link).font(.system(size: 11))
            }
        }.modifier(Surface())
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.busy || model.isError || model.message != model.text("保持你有权使用的本地代理运行，再启动兼容应用。") {
            HStack(alignment: .top, spacing: 8) {
                if model.busy { ProgressView().controlSize(.small) }
                else { Image(systemName: model.isError ? "exclamationmark.circle.fill" : "info.circle").font(.system(size: 12)) }
                Text(model.message).font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
            }.foregroundStyle(model.isError ? Color.orange : Color.secondary)
                .padding(.bottom, 4)
            }
            HStack(spacing: 5) {
                Image(systemName: "menubar.rectangle")
                Text(model.text("关闭窗口后，仍可从菜单栏访问"))
                Spacer()
            }.font(.system(size: 10)).foregroundStyle(.secondary)
            Text(model.text("独立项目，与 OpenAI 无隶属或背书关系；商标归各自权利人所有。"))
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }.padding(.horizontal, 3)
    }

    private var reportSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(model.text("代理检查报告"), systemImage: "doc.text.magnifyingglass").font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(model.text("完成")) { model.showDetails = false }.keyboardShortcut(.defaultAction)
            }
            ScrollView {
                Text(model.details).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            }.background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
            Button { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(model.details, forType: .string) }
                label: { Label(model.text("复制报告"), systemImage: "doc.on.doc") }
        }.padding(24).frame(width: 650, height: 470)
    }
}

private struct SharedLanguagePicker: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        Menu {
            Button { store.setLanguage(nil) } label: {
                if store.current.followsSystem { Label(store.current.text("跟随系统"), systemImage: "checkmark") }
                else { Text(store.current.text("跟随系统")) }
            }
            Divider()
            ForEach(AppLanguage.allCases) { language in
                Button { store.setLanguage(language) } label: {
                    if !store.current.followsSystem && store.current.language == language { Label(language.label, systemImage: "checkmark") }
                    else { Text(language.label) }
                }
            }
        } label: { Image(systemName: "character.bubble").frame(width: 24, height: 24) }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .help(store.current.text("界面语言") + " · " + (store.current.followsSystem ? store.current.text("跟随系统") : store.current.language.label))
        .accessibilityLabel(store.current.text("界面语言"))
        .disabled(store.busy)
    }
}

private struct SharedThemePicker: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        Menu {
            ForEach(AppTheme.allCases) { theme in
                Button { store.theme = theme } label: {
                    if store.theme == theme { Label(store.current.text(theme.label), systemImage: "checkmark") }
                    else { Text(store.current.text(theme.label)) }
                }
            }
        } label: { Image(systemName: store.theme.symbol).frame(width: 24, height: 24) }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .help(store.current.text("外观") + " · " + store.current.text(store.theme.label))
        .accessibilityLabel(store.current.text("外观"))
    }
}

private struct RepositoryLink: View {
    var body: some View {
        Link(destination: BrandIdentity.repositoryURL) { GitHubMark().fill(Color.primary).frame(width: 16, height: 16).padding(4) }
            .buttonStyle(.plain).help("GitHub").accessibilityLabel("GitHub")
    }
}

private struct WindowTools: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        HStack(spacing: 10) {
            SharedLanguagePicker(store: store)
            SharedThemePicker(store: store)
            RepositoryLink()
        }.foregroundStyle(.secondary)
    }
}

@MainActor private final class UpdatePresentation: ObservableObject { @Published var show = false }

private struct UpdateIndicator: View {
    @ObservedObject var store: LauncherStore
    var compact = false
    @StateObject private var presentation = UpdatePresentation()
    private var update: UpdateModel { store.updates }
    private var label: String {
        if update.checking { return "正在检查更新…" }
        if update.failed { return "暂时无法检查更新" }
        return update.release?.isNewer == true ? "有更新" : "检查更新"
    }
    var body: some View {
        HStack(spacing: 7) {
            Text("v\(update.version)").font(.system(size: 10)).foregroundStyle(.secondary)
            Button { presentation.show.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: update.release?.isNewer == true ? "arrow.up.circle" : "arrow.clockwise")
                    if !compact || update.release?.isNewer == true { Text(store.current.text(label)).lineLimit(1) }
                }.font(.system(size: 10)).padding(.horizontal, 6).padding(.vertical, 4)
                    .background(Palette.accent.opacity(0.09), in: Capsule())
            }.buttonStyle(.plain).foregroundStyle(Palette.accent)
                .help(store.current.text(label)).accessibilityLabel(store.current.text(label))
                .popover(isPresented: $presentation.show, arrowEdge: .bottom) { UpdatePanel(store: store) }
        }
    }
}

struct UpdatePanel: View {
    @ObservedObject var store: LauncherStore
    private var update: UpdateModel { store.updates }
    private func t(_ key: String) -> String { store.current.text(key) }
    private var title: String {
        if update.checking { return "正在检查更新…" }
        if update.failed { return "暂时无法检查更新" }
        if let release = update.release { return release.isNewer ? "发现新版本" : "已是最新版本" }
        return "检查更新"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t(title)).font(.system(size: 16, weight: .semibold))
            Text("Local Route Launcher").font(.system(size: 12)).foregroundStyle(.secondary)
            HStack { Text(t("当前版本")); Spacer(); Text("v" + update.version) }
            if let release = update.release {
                HStack { Text(t("最新稳定版")); Spacer(); Text(release.version).foregroundStyle(Palette.accent) }
            }
            Divider()
            Toggle(t("启动时自动检查"), isOn: Binding(get: { update.automatic }, set: { update.automatic = $0 }))
            Text(t("从 GitHub Releases 检查稳定版本，不自动下载或安装。")).foregroundStyle(.secondary)
            if update.failed { Text(t("可继续使用当前版本，稍后重试。")).foregroundStyle(.secondary) }
            HStack {
                Button(t(update.failed ? "重试" : "检查更新")) { Task { await update.check() } }.disabled(update.checking)
                Spacer()
                Link(t(update.release?.isNewer == true ? "查看发布说明与下载" : "打开发布页面"), destination: update.release?.url ?? ReleaseUpdate.releasesURL)
            }
        }.font(.system(size: 11)).padding(20).frame(width: 330).background(Palette.canvas)
            .tint(Palette.accent).environment(\.layoutDirection, store.current.language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}

struct LauncherWindow: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Local Route Launcher").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                WindowTools(store: store)
            }.padding(.leading, 110).padding(.trailing, 18).frame(height: 38)
            Divider()
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 10) {
                    BrandMark(size: 34)
                    Text("Local Route\nLauncher").font(.system(size: 14, weight: .semibold))
                }
                Text(store.current.text("我的应用")).font(.system(size: 11)).foregroundStyle(.secondary)
                VStack(spacing: 8) {
                    ForEach(ApplicationKind.allCases) { kind in
                        Button { store.selected = kind } label: {
                            HStack(spacing: 10) {
                                Image(systemName: kind.symbol).frame(width: 22)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(kind.name).font(.system(size: 12, weight: .medium))
                                    Text(store.models[kind]!.text(store.models[kind]!.running ? "运行中" : "未运行"))
                                        .font(.system(size: 11)).foregroundStyle(store.models[kind]!.running ? Palette.accent : .secondary)
                                }
                                Spacer(minLength: 0)
                            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(store.selected == kind ? Palette.accent.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel(kind.name)
                    }
                }
                Spacer()
                UpdateIndicator(store: store)
            }.padding(16).padding(.top, 22).frame(width: 204)
            Divider()
            LauncherView(model: store.current).id(store.selected)
        }
        }.frame(minWidth: 865, minHeight: 600)
            .background(Palette.canvas).tint(Palette.accent)
            .environment(\.layoutDirection, store.current.language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}

private struct MenuApplicationRow: View {
    @ObservedObject var model: LauncherModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: model.kind.symbol).foregroundStyle(.secondary).frame(width: 22)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.kind.name).font(.system(size: 12, weight: .semibold))
                    Text(model.endpointLabel).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).environment(\.layoutDirection, .leftToRight)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(model.text(model.running ? "运行中" : "未运行")).font(.system(size: 10)).foregroundStyle(model.running ? Palette.accent : .secondary)
                    Button(model.text(model.running ? "停止" : "启动")) { model.running ? model.stop() : model.start() }.disabled(model.busy).controlSize(.small)
                }
            }
            if model.busy || model.isError {
                Text(model.message).font(.system(size: 11)).foregroundStyle(model.isError ? .orange : .secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MenuPanel: View {
    @ObservedObject var store: LauncherStore
    @Environment(\.openWindow) private var openWindow
    private func showMain() {
        DockPresence.shared.prepareToShow()
        openWindow(id: "main")
        DockPresence.shared.activateMainWindow()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                BrandMark(size: 30)
                Text("Local Route\nLauncher").font(.system(size: 12, weight: .semibold)).fixedSize(horizontal: true, vertical: true)
                Spacer()
                WindowTools(store: store)
            }
            ForEach(ApplicationKind.allCases) { kind in
                Divider()
                MenuApplicationRow(model: store.models[kind]!)
            }
            Divider()
            HStack(spacing: 8) {
                UpdateIndicator(store: store, compact: true)
                Spacer(minLength: 4)
                Button(store.current.text("打开主窗口"), action: showMain)
                Button(store.current.text("退出启动器")) { NSApp.terminate(nil) }.disabled(store.busy)
            }.buttonStyle(.plain).font(.system(size: 12))
        }.padding(18).frame(width: 400).background(Palette.canvas).tint(Palette.accent)
            .environment(\.locale, store.current.language.locale)
            .environment(\.layoutDirection, store.current.language.isRightToLeft ? .rightToLeft : .leftToRight)
            .onAppear { store.models.values.forEach { $0.updateRunning() } }
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
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.standardWindowButton(.zoomButton)?.isEnabled = true
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
    @ObservedObject var model: LauncherModel
    @Environment(\.openWindow) private var openWindow
    var body: some SwiftUI.Commands {
        CommandGroup(replacing: .newItem) {
            Button(model.text("显示主窗口")) {
                DockPresence.shared.prepareToShow()
                openWindow(id: "main")
                DockPresence.shared.activateMainWindow()
            }.keyboardShortcut("0", modifiers: .command)
        }
    }
}

struct LauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = LauncherStore()
    var body: some Scene {
        Window("Local Route Launcher", id: "main") {
            LauncherWindow(store: store).onAppear { NSApp.appearance = store.theme.appearance }
        }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentMinSize)
            .defaultSize(width: 1024, height: min(860, max(600, (NSScreen.main?.visibleFrame.height ?? 880) - 100)))
            .defaultPosition(.center)
            .commands { LauncherCommands(model: store.current) }
        MenuBarExtra {
            MenuPanel(store: store)
        } label: {
            Image(systemName: BrandIdentity.menuSymbolName)
                .accessibilityLabel(store.anyRunning ? store.current.text("Local Route Launcher：运行中") : store.current.text("Local Route Launcher：未运行"))
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
