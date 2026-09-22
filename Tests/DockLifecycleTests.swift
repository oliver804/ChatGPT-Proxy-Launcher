import AppKit

@main
enum DockLifecycleTests {
    @MainActor
    static func main() async throws {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        let main = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 200, height: 100),
                            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        main.title = "Dock lifecycle test"
        main.isReleasedWhenClosed = false
        DockPresence.shared.track(main)
        main.orderFront(nil)
        try await Task.sleep(nanoseconds: 200_000_000)
        guard app.activationPolicy() == .regular else { fatalError("Main window must show Dock icon") }

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
        print("PASS: main window close hides Dock; secondary panel close preserves Dock; reopen restores window and Dock; repeated close works")
    }
}
