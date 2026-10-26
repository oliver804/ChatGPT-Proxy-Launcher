import AppKit

@main
enum MenuBarIconTests {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        let image = MenuBarIcon.image
        precondition(image.isTemplate, "Menu bar artwork must be a native template")
        let original = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)!
        precondition(image.size == original.size, "Preserve the native 1.0.0 symbol proportions")
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 30, height: 24))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = image
        let window = NSWindow(contentRect: button.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = button
        window.orderFront(nil)
        defer { window.orderOut(nil) }

        // Reuse the same cached image/control across appearance changes. Sample
        // actual AppKit rendering, rather than only asserting isTemplate.
        for name in [NSAppearance.Name.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua, .aqua] {
            let dark = name == .darkAqua || name == .accessibilityHighContrastDarkAqua
            let appearance = NSAppearance(named: name)!
            window.appearance = appearance
            button.appearance = appearance
            for highlighted in [false, true] {
                button.highlight(highlighted)
                button.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
                var png: Data?
                appearance.performAsCurrentDrawingAppearance {
                    let bitmap = button.bitmapImageRepForCachingDisplay(in: button.bounds)!
                    button.cacheDisplay(in: button.bounds, to: bitmap)
                    var brightness: CGFloat = 0
                    var coverage: CGFloat = 0
                    for y in 0..<bitmap.pixelsHigh {
                        for x in 0..<bitmap.pixelsWide {
                            let color = bitmap.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                            if color.alphaComponent > 0.1 {
                                coverage += color.alphaComponent
                                brightness += color.redComponent * color.alphaComponent
                            }
                        }
                    }
                    precondition(coverage > 10, "Icon is missing in \(name.rawValue), highlighted=\(highlighted)")
                    if !highlighted {
                        precondition(dark ? brightness / coverage > 0.7 : brightness / coverage < 0.3,
                                     "Template did not adapt to \(name.rawValue)")
                    }
                    png = bitmap.representation(using: .png, properties: [:])
                }
                let output = "build/menu-icon-\(name.rawValue)-\(highlighted).png"
                try png!.write(to: URL(fileURLWithPath: output))
            }
        }
        print("PASS: native template rendering in light, dark, high-contrast and highlighted states; live appearance changes")
    }
}
