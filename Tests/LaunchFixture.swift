import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let output = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("launch-result.json")
let selected = ProcessInfo.processInfo.environment.filter {
    ["HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "all_proxy", "no_proxy", "NODE_USE_ENV_PROXY"].contains($0.key)
}
let data = try JSONSerialization.data(withJSONObject: ["arguments": CommandLine.arguments, "environment": selected])
try data.write(to: output, options: .atomic)
Timer.scheduledTimer(withTimeInterval: 25, repeats: false) { _ in app.terminate(nil) }
app.run()
