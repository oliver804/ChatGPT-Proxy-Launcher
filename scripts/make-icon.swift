import AppKit
import SwiftUI

@main
enum IconGenerator {
    @MainActor
    static func main() throws {
        let destination = URL(fileURLWithPath: CommandLine.arguments[1])
        let iconset = URL(fileURLWithPath: "build/AppIcon.iconset", isDirectory: true)
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = points * scale
                let content = BrandMark(size: CGFloat(points) * 0.875)
                    .frame(width: CGFloat(points), height: CGFloat(points))
                    .environment(\.colorScheme, .light)
                let renderer = ImageRenderer(content: content)
                renderer.scale = CGFloat(scale)
                guard let cgImage = renderer.cgImage else { fatalError("Cannot render app icon") }
                let bitmap = NSBitmapImageRep(cgImage: cgImage)
                guard bitmap.pixelsWide == pixels, bitmap.pixelsHigh == pixels,
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    fatalError("Invalid icon dimensions")
                }
                let suffix = scale == 2 ? "@2x" : ""
                try png.write(to: iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
            }
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconset.path, "-o", destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { fatalError("iconutil failed") }
        print("Generated Finder / Dock icon from the shared BrandMark (10 sizes).")
    }
}
