import AppKit

// Exercise the same system icon lookup used for application bundles, not just ICNS decoding.
let app = NSApplication.shared
let appURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let bundle = Bundle(url: appURL)!
guard let name = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
      name.hasSuffix(".icns"),
      let resource = bundle.url(forResource: name, withExtension: nil),
      NSImage(contentsOf: resource)?.isValid == true else {
    fatalError("Icon declaration must point to an existing, decodable ICNS file with its full extension")
}
if CommandLine.arguments.contains("--structural") {
    print("PASS: icon declaration resolves and ICNS decodes (system icon service check skipped)")
    exit(0)
}
app.setActivationPolicy(.prohibited)
let icon = NSWorkspace.shared.icon(forFile: appURL.path)
_ = icon.tiffRepresentation
icon.size = NSSize(width: 256, height: 256)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
icon.draw(in: NSRect(x: 0, y: 0, width: 256, height: 256))
NSGraphicsContext.restoreGraphicsState()
var greenPixels = 0
for y in 0..<256 {
    for x in 0..<256 {
        guard let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        if c.alphaComponent > 0.8, c.greenComponent > 0.2,
           c.greenComponent > c.redComponent * 1.4, c.greenComponent > c.blueComponent * 1.1 {
            greenPixels += 1
        }
    }
}
if CommandLine.arguments.count > 2 {
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
}
guard greenPixels > 15000 else { fatalError("System icon lookup returned a placeholder or unexpected artwork") }
print("PASS: bundle icon declaration resolves; ICNS decodes; macOS icon service returns the green brand icon")
