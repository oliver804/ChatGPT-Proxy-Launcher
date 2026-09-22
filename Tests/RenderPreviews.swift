import AppKit
import SwiftUI

@main
enum RenderPreviews {
    @MainActor
    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let defaults = UserDefaults(suiteName: "local.chatgpt-proxy-launcher.preview")!
        let model = LauncherModel(defaults: defaults, monitor: false)
        model.running = true
        model.checkedAt = Date()
        model.proxyOK = true; model.parameterOK = true; model.connectionOK = true
        model.proxyStatus = "隧道与 TLS 连通"; model.parameterStatus = "当前地址已传入"; model.connectionStatus = "观察到 4 条连接"
        model.message = "检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。"
        try render(LauncherView(model: model), name: "window-light", dark: false)
        try render(LauncherView(model: model), name: "window-dark", dark: true)
        model.clearDiagnostics()
        model.running = false
        try render(MenuPanel(model: model), name: "menu-light", dark: false)
        try render(MenuPanel(model: model), name: "menu-dark", dark: true)
        print("PASS: rendered window and menu in light/dark modes")
    }

    @MainActor
    static func render<V: View>(_ view: V, name: String, dark: Bool) throws {
        NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let host = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        let size = host.fittingSize
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSApp.appearance
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("render failed") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let data = bitmap.representation(using: .png, properties: [:])!
        try data.write(to: URL(fileURLWithPath: "build/\(name).png"))
        print("\(name): \(Int(size.width)) x \(Int(size.height))")
    }
}
