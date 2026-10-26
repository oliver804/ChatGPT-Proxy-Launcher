import AppKit
import SwiftUI

enum BrandIdentity {
    // Restore the native menu bar symbol used in 1.0.0. Its aspect ratio and
    // optical sizing are managed by macOS, including dark and highlighted bars.
    static let menuSymbolName = "arrow.triangle.branch"
}

enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(systemSymbolName: BrandIdentity.menuSymbolName, accessibilityDescription: nil)!
        image.isTemplate = true
        return image
    }()
}

// The window, menu panel and generated Finder / Dock icon all use this artwork.
struct BrandMark: View {
    var size: CGFloat = 44

    var body: some View {
        RouteGlyph()
            .stroke(.white, style: StrokeStyle(lineWidth: size * 0.052, lineCap: .round, lineJoin: .round))
            .padding(size * 0.24)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.60, blue: 0.44), Color(red: 0.04, green: 0.35, blue: 0.29)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: size * 0.28)
            )
    }
}

// Original vector artwork shared across platforms; no system symbol is exported.
struct RouteGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.48, 0.91))
        path.addLine(to: p(0.48, 0.59))
        path.addCurve(to: p(0.88, 0.16), control1: p(0.48, 0.35), control2: p(0.73, 0.32))
        path.move(to: p(0.64, 0.16)); path.addLine(to: p(0.88, 0.16)); path.addLine(to: p(0.88, 0.40))
        path.move(to: p(0.48, 0.59))
        path.addCurve(to: p(0.12, 0.20), control1: p(0.45, 0.37), control2: p(0.27, 0.35))
        path.move(to: p(0.12, 0.43)); path.addLine(to: p(0.12, 0.20)); path.addLine(to: p(0.35, 0.20))
        return path
    }
}
