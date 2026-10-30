import AppKit
import SwiftUI

enum BrandIdentity {
    static let repositoryURL = URL(string: "https://github.com/oliver804/ChatGPT-Proxy-Launcher")!
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
        path.move(to: p(0.50, 0.91))
        path.addLine(to: p(0.50, 0.59))
        // Reflect the same branch around the center; both arrowheads share a baseline.
        for direction: CGFloat in [-1, 1] {
            func branch(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(0.50 + direction * x, y) }
            path.move(to: branch(0, 0.59))
            path.addCurve(to: branch(0.38, 0.16), control1: branch(0, 0.35), control2: branch(0.23, 0.32))
            path.move(to: branch(0.14, 0.16))
            path.addLine(to: branch(0.38, 0.16))
            path.addLine(to: branch(0.38, 0.40))
        }
        return path
    }
}

// GitHub mark from Primer Octicons (MIT); see THIRD_PARTY_NOTICES.md.
struct GitHubMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 6.766000, y: 11.328000))
        path.addCurve(to: CGPoint(x: 3.250000, y: 7.672000), control1: CGPoint(x: 4.703000, y: 11.078000), control2: CGPoint(x: 3.250000, y: 9.594000))
        path.addCurve(to: CGPoint(x: 4.000000, y: 5.484000), control1: CGPoint(x: 3.250000, y: 6.891000), control2: CGPoint(x: 3.531000, y: 6.047000))
        path.addCurve(to: CGPoint(x: 4.063000, y: 3.422000), control1: CGPoint(x: 3.797000, y: 4.969000), control2: CGPoint(x: 3.828000, y: 3.875000))
        path.addCurve(to: CGPoint(x: 6.031000, y: 4.125000), control1: CGPoint(x: 4.688000, y: 3.344000), control2: CGPoint(x: 5.531000, y: 3.672000))
        path.addCurve(to: CGPoint(x: 8.016000, y: 3.844000), control1: CGPoint(x: 6.625000, y: 3.938000), control2: CGPoint(x: 7.250000, y: 3.844000))
        path.addCurve(to: CGPoint(x: 9.969000, y: 4.109000), control1: CGPoint(x: 8.781000, y: 3.844000), control2: CGPoint(x: 9.406000, y: 3.938000))
        path.addCurve(to: CGPoint(x: 11.938000, y: 3.422000), control1: CGPoint(x: 10.453000, y: 3.672000), control2: CGPoint(x: 11.313000, y: 3.344000))
        path.addCurve(to: CGPoint(x: 11.984000, y: 5.469000), control1: CGPoint(x: 12.156000, y: 3.844000), control2: CGPoint(x: 12.188000, y: 4.937000))
        path.addCurve(to: CGPoint(x: 12.750000, y: 7.672000), control1: CGPoint(x: 12.484000, y: 6.062000), control2: CGPoint(x: 12.750000, y: 6.859000))
        path.addCurve(to: CGPoint(x: 9.203000, y: 11.312000), control1: CGPoint(x: 12.750000, y: 9.594000), control2: CGPoint(x: 11.297000, y: 11.047000))
        path.addCurve(to: CGPoint(x: 10.093000, y: 13.266000), control1: CGPoint(x: 9.734000, y: 11.656000), control2: CGPoint(x: 10.093000, y: 12.406000))
        path.addLine(to: CGPoint(x: 10.093000, y: 14.891000))
        path.addCurve(to: CGPoint(x: 10.953000, y: 15.438000), control1: CGPoint(x: 10.093000, y: 15.359000), control2: CGPoint(x: 10.484000, y: 15.625000))
        path.addCurve(to: CGPoint(x: 16.000000, y: 8.030000), control1: CGPoint(x: 13.781000, y: 14.359000), control2: CGPoint(x: 16.000000, y: 11.530000))
        path.addCurve(to: CGPoint(x: 7.984000, y: 0.000000), control1: CGPoint(x: 16.000000, y: 3.610000), control2: CGPoint(x: 12.406000, y: 0.000000))
        path.addCurve(to: CGPoint(x: 0.000000, y: 8.031000), control1: CGPoint(x: 3.563000, y: 0.000000), control2: CGPoint(x: 0.000000, y: 3.610000))
        path.addCurve(to: CGPoint(x: 5.172000, y: 15.453000), control1: CGPoint(x: -0.009220, y: 11.346744), control2: CGPoint(x: 2.058182, y: 14.313537))
        path.addCurve(to: CGPoint(x: 6.000000, y: 14.906000), control1: CGPoint(x: 5.594000, y: 15.609000), control2: CGPoint(x: 6.000000, y: 15.328000))
        path.addLine(to: CGPoint(x: 6.000000, y: 13.656000))
        path.addCurve(to: CGPoint(x: 5.250000, y: 13.812000), control1: CGPoint(x: 5.781000, y: 13.750000), control2: CGPoint(x: 5.500000, y: 13.812000))
        path.addCurve(to: CGPoint(x: 3.172000, y: 12.203000), control1: CGPoint(x: 4.219000, y: 13.812000), control2: CGPoint(x: 3.610000, y: 13.250000))
        path.addCurve(to: CGPoint(x: 2.453000, y: 11.484000), control1: CGPoint(x: 3.000000, y: 11.781000), control2: CGPoint(x: 2.812000, y: 11.531000))
        path.addCurve(to: CGPoint(x: 2.203000, y: 11.297000), control1: CGPoint(x: 2.266000, y: 11.469000), control2: CGPoint(x: 2.203000, y: 11.391000))
        path.addCurve(to: CGPoint(x: 2.828000, y: 10.969000), control1: CGPoint(x: 2.203000, y: 11.109000), control2: CGPoint(x: 2.516000, y: 10.969000))
        path.addCurve(to: CGPoint(x: 4.078000, y: 11.829000), control1: CGPoint(x: 3.281000, y: 10.969000), control2: CGPoint(x: 3.672000, y: 11.250000))
        path.addCurve(to: CGPoint(x: 5.109000, y: 12.484000), control1: CGPoint(x: 4.391000, y: 12.281000), control2: CGPoint(x: 4.718000, y: 12.484000))
        path.addCurve(to: CGPoint(x: 6.109000, y: 11.984000), control1: CGPoint(x: 5.500000, y: 12.484000), control2: CGPoint(x: 5.750000, y: 12.344000))
        path.addCurve(to: CGPoint(x: 6.766000, y: 11.328000), control1: CGPoint(x: 6.375000, y: 11.719000), control2: CGPoint(x: 6.579000, y: 11.484000))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width / 16, y: rect.height / 16)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}
