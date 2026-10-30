import AppKit
import SwiftUI

@main
enum RenderPreviews {
    @MainActor
    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let defaults = UserDefaults(suiteName: "local.chatgpt-proxy-launcher.preview")!
        defer { defaults.removePersistentDomain(forName: "local.chatgpt-proxy-launcher.preview") }
        for language in AppLanguage.allCases {
            defaults.set(language.rawValue, forKey: "interfaceLanguage")
            let store = LauncherStore(defaults: defaults, monitor: false, previewVersion: try String(contentsOfFile: "VERSION").trimmingCharacters(in: .whitespacesAndNewlines))
            store.selected = .antigravity
            let model = store.current
            model.running = true
            model.checkedAt = Date(timeIntervalSince1970: 1_760_000_000)
            model.proxyOK = true; model.parameterOK = true; model.connectionOK = true
            model.proxyStatus = model.text("隧道与 TLS 连通")
            model.parameterStatus = model.text("当前地址已传入")
            model.connectionStatus = model.text("观察到 %@ 条连接", "4")
            model.message = model.text("检查完成。连接情况是此刻的快照，可在 ChatGPT 请求后再次检查。")
            for dark in [false, true] {
                let suffix = "\(language.rawValue)-\(dark ? "dark" : "light")"
                try render(LauncherWindow(store: store).frame(width: 865, height: 780), name: "window-" + suffix, dark: dark)
                try render(MenuPanel(store: store), name: "menu-" + suffix, dark: dark)
            }
        }
        print("PASS: rendered nine language options in light/dark windows and menus")
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
