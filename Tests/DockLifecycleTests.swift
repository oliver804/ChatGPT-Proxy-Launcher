import AppKit

@MainActor
final class FullScreenObserver: NSObject, NSWindowDelegate {
    var entered = false
    var exited = false
    func windowDidEnterFullScreen(_ notification: Notification) { entered = true }
    func windowDidExitFullScreen(_ notification: Notification) { exited = true }
}

@main
enum DockLifecycleTests {
    @MainActor
    static func main() async throws {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        let main = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 865, height: 560),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        main.title = "Dock lifecycle test"
        main.isReleasedWhenClosed = false
        DockPresence.shared.track(main)
        guard main.styleMask.contains(.resizable), main.collectionBehavior.contains(.fullScreenPrimary),
              main.standardWindowButton(.zoomButton)?.isEnabled == true else { fatalError("Green button must support resizing and full screen") }
        let defaults = UserDefaults(suiteName: "local.route.ui-test")!
        defer { defaults.removePersistentDomain(forName: "local.route.ui-test"); app.appearance = nil }
        let store = LauncherStore(defaults: defaults, monitor: false)
        store.theme = .dark
        guard app.appearance?.name == .darkAqua else { fatalError("Dark preference did not reach native windows") }
        store.theme = .light
        guard app.appearance?.name == .aqua else { fatalError("Light preference did not reach native windows") }
        store.theme = .system
        guard app.appearance == nil else { fatalError("System appearance remains overridden") }
        main.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        try await Task.sleep(nanoseconds: 500_000_000)
        guard app.activationPolicy() == .regular else { fatalError("Main window must show Dock icon") }

        let originalFrame = main.frame
        main.zoom(nil)
        try await Task.sleep(nanoseconds: 350_000_000)
        guard main.frame != originalFrame else { fatalError("Zoom button action must change the window frame") }
        main.zoom(nil)
        try await Task.sleep(nanoseconds: 500_000_000)
        let fullScreenObserver = FullScreenObserver()
        main.delegate = fullScreenObserver
        main.toggleFullScreen(nil)
        for _ in 0..<100 {
            if fullScreenObserver.entered { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        guard fullScreenObserver.entered, main.styleMask.contains(.fullScreen) else { fatalError("Green button must enter full screen") }
        try await Task.sleep(nanoseconds: 1_000_000_000)
        main.toggleFullScreen(nil)
        for _ in 0..<100 {
            if fullScreenObserver.exited { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        guard fullScreenObserver.exited, !main.styleMask.contains(.fullScreen) else { fatalError("Full screen must be reversible") }
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let panel = NSPanel(contentRect: NSRect(x: 100, y: 100, width: 150, height: 70),
                            styleMask: [.nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.orderFront(nil)
        panel.close()
        try await Task.sleep(nanoseconds: 200_000_000)
        guard app.activationPolicy() == .regular else { fatalError("Closing a secondary panel must not hide Dock icon") }

        main.close()
        try await Task.sleep(nanoseconds: 200_000_000)
        guard app.activationPolicy() == .accessory else { fatalError("Closing main window must hide Dock icon") }
        DockPresence.shared.prepareToShow()
        DockPresence.shared.activateMainWindow()
        try await Task.sleep(nanoseconds: 200_000_000)
        guard app.activationPolicy() == .regular, main.isVisible else { fatalError("Reopening must restore window and Dock icon") }
        main.close()
        try await Task.sleep(nanoseconds: 200_000_000)
        guard app.activationPolicy() == .accessory else { fatalError("Repeated close must remain supported") }
        print("PASS: appearance preferences; green-button zoom and full screen; main window close hides Dock; secondary panel close preserves Dock; reopen restores window and Dock; repeated close works")
    }
}
