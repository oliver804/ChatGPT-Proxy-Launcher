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
    static let tool = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 161/255, green: 177/255, blue: 168/255, alpha: 1)
            : NSColor(calibratedRed: 93/255, green: 112/255, blue: 102/255, alpha: 1)
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
        .alert(model.message, isPresented: $model.isError) { Button(model.text("完成"), role: .cancel) {} }
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

// Lucide languages / sun-moon, ISC. Exact 24-unit vectors from the approved mockup.
private enum HeaderIconKind { case languages, sunMoon }
private struct HeaderIcon: View {
    let kind: HeaderIconKind
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        // Native macOS Menu labels accept images, not an arbitrary Shape hierarchy.
        Image(nsImage: artwork).renderingMode(.original).frame(width: 32, height: 32)
    }
    private var artwork: NSImage {
        let ink = scheme == .dark ? NSColor(calibratedRed: 161/255, green: 177/255, blue: 168/255, alpha: 1)
            : NSColor(calibratedRed: 93/255, green: 112/255, blue: 102/255, alpha: 1)
        return NSImage(size: NSSize(width: 17, height: 17), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.addPath(HeaderGlyph(kind: kind).path(in: rect).cgPath)
            context.setStrokeColor(ink.cgColor)
            context.setLineWidth(17 * 2 / 24); context.setLineCap(.round); context.setLineJoin(.round)
            context.strokePath()
            return true
        }
    }
}
private struct HeaderGlyph: Shape {
    let kind: HeaderIconKind
    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch kind {
        case .languages:
            for points: [CGPoint] in [
                [CGPoint(x: 5, y: 8), CGPoint(x: 11, y: 14)],
                [CGPoint(x: 4, y: 14), CGPoint(x: 10, y: 8), CGPoint(x: 12, y: 5)],
                [CGPoint(x: 2, y: 5), CGPoint(x: 14, y: 5)],
                [CGPoint(x: 7, y: 2), CGPoint(x: 8, y: 2)],
                [CGPoint(x: 22, y: 22), CGPoint(x: 17, y: 12), CGPoint(x: 12, y: 22)],
                [CGPoint(x: 14, y: 18), CGPoint(x: 20, y: 18)]
            ] { path.move(to: points[0]); points.dropFirst().forEach { path.addLine(to: $0) } }
        case .sunMoon:
            path.move(to: CGPoint(x: 12, y: 2))
            path.addLine(to: CGPoint(x: 12, y: 4))
            path.move(to: CGPoint(x: 14.837, y: 16.385))
            path.addCurve(to: CGPoint(x: 8.534021207, y: 20.982978148), control1: CGPoint(x: 14.155249457, y: 19.260877945), control2: CGPoint(x: 11.480721058, y: 21.211927368))
            path.addCurve(to: CGPoint(x: 3.016894582, y: 15.466615351), control1: CGPoint(x: 5.587321357, y: 20.754028929), control2: CGPoint(x: 3.246251788, y: 18.413283474))
            path.addCurve(to: CGPoint(x: 7.614000000, y: 9.163000000), control1: CGPoint(x: 2.787537376, y: 12.519947228), control2: CGPoint(x: 4.738216476, y: 9.845148719))
            path.addCurve(to: CGPoint(x: 8.329000000, y: 10.411000000), control1: CGPoint(x: 8.238000000, y: 9.016000000), control2: CGPoint(x: 8.584000000, y: 9.823000000))
            path.addCurve(to: CGPoint(x: 9.172095199, y: 14.827744581), control1: CGPoint(x: 7.677633904, y: 11.916829253), control2: CGPoint(x: 8.011855714, y: 13.667725673))
            path.addCurve(to: CGPoint(x: 13.589000000, y: 15.670000000), control1: CGPoint(x: 10.332334685, y: 15.987763489), control2: CGPoint(x: 12.083294620, y: 16.321652391))
            path.addCurve(to: CGPoint(x: 14.837000000, y: 16.385000000), control1: CGPoint(x: 14.178000000, y: 15.415000000), control2: CGPoint(x: 14.985000000, y: 15.760000000))
            path.move(to: CGPoint(x: 16, y: 12))
            path.addCurve(to: CGPoint(x: 12.000000000, y: 8.000000000), control1: CGPoint(x: 16.000000000, y: 9.790861001), control2: CGPoint(x: 14.209138999, y: 8.000000000))
            path.move(to: CGPoint(x: 19, y: 5))
            path.addLine(to: CGPoint(x: 17.744, y: 6.256))
            path.move(to: CGPoint(x: 20, y: 12))
            path.addLine(to: CGPoint(x: 22, y: 12))
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24).concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
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
        } label: { HeaderIcon(kind: .languages) }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().frame(width: 32, height: 32)
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
        } label: { HeaderIcon(kind: .sunMoon) }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().frame(width: 32, height: 32)
        .help(store.current.text("外观") + " · " + store.current.text(store.theme.label))
        .accessibilityLabel(store.current.text("外观"))
    }
}

private struct RepositoryLink: View {
    var body: some View {
        Button { NSWorkspace.shared.open(BrandIdentity.repositoryURL) } label: {
            GitHubMark().fill(Palette.tool).frame(width: 17, height: 17)
                .frame(width: 32, height: 32).contentShape(Rectangle())
        }
            .buttonStyle(.plain).help("GitHub").accessibilityLabel("GitHub")
    }
}

private struct WindowTools: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        HStack(spacing: 4) {
            SharedLanguagePicker(store: store)
            SharedThemePicker(store: store)
            RepositoryLink()
        }.foregroundStyle(Palette.tool).tint(Palette.tool)
    }
}

private struct UpdateIndicator: View {
    @ObservedObject var store: LauncherStore
    var compact = false
    var body: some View {
        HStack(spacing: 7) {
            Text("v\(store.updates.version)").font(.system(size: 10)).foregroundStyle(.secondary)
            if let release = store.updates.release, let download = release.availableDownload {
                Button { NSWorkspace.shared.open(download) } label: {
                    Label(store.current.text("有更新"), systemImage: "arrow.up.circle")
                        .font(.system(size: 10)).padding(.horizontal, 6).padding(.vertical, 4)
                        .background(Palette.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 6))
                }.buttonStyle(.plain).foregroundStyle(Palette.accent)
                    .help(store.current.text("有更新") + " · " + release.version)
                    .accessibilityLabel(store.current.text("有更新"))
            }
        }
    }
}

struct LauncherWindow: View {
    @ObservedObject var store: LauncherStore
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Local Route Launcher").font(.system(size: 12)).foregroundStyle(.secondary)
                HStack { Spacer(); WindowTools(store: store) }.padding(.trailing, 16)
            }.frame(height: 48).environment(\.layoutDirection, .leftToRight)
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
            .ignoresSafeArea(.container, edges: .top)
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
                Button(store.current.text("退出")) { NSApp.terminate(nil) }.disabled(store.busy)
            }.buttonStyle(.plain).font(.system(size: 12))
        }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14).frame(width: 340).background(Palette.canvas).tint(Palette.accent)
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
        window.styleMask.formUnion([.resizable, .fullSizeContentView])
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.standardWindowButton(.zoomButton)?.isEnabled = true
        prepareToShow()
        alignWindowControls(window)
        for name in [NSWindow.didResizeNotification, NSWindow.didExitFullScreenNotification, NSWindow.didBecomeKeyNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self, weak window] _ in
                DispatchQueue.main.async { if let window { self?.alignWindowControls(window) } }
            })
        }
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

    private func alignWindowControls(_ window: NSWindow) {
        guard !window.styleMask.contains(.fullScreen) else { return }
        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            guard let button = window.standardWindowButton(type), let parent = button.superview else { continue }
            // Keep the native controls/actions, centered in the single 48-point header.
            let center = parent.convert(NSPoint(x: 0, y: window.frame.height - 24), from: nil)
            let origin = NSPoint(x: button.frame.minX, y: center.y - button.frame.height / 2)
            if button.frame.origin != origin { button.setFrameOrigin(origin) }
        }
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
