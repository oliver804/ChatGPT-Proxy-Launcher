import AppKit

@main
enum LaunchIntegration {
    @MainActor
    static func main() async throws {
        let target = try TargetApplication(path: CommandLine.arguments[1])
        let endpoint = try ProxyEndpoint(host: "127.0.0.1", port: "7890")
        let resultURL = target.url.deletingLastPathComponent().appendingPathComponent("launch-result.json")
        let app = try await ApplicationControl.launch(target, endpoint: endpoint)
        defer { if !app.isTerminated { app.terminate() } }
        for _ in 0..<50 {
            if FileManager.default.fileExists(atPath: resultURL.path) { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: resultURL)) as! [String: Any]
        let arguments = object["arguments"] as! [String]
        let environment = object["environment"] as! [String: String]
        guard endpoint.launchArguments.allSatisfy(arguments.contains), environment == endpoint.environment else {
            fatalError("Launch Services did not pass arguments/environment correctly")
        }
        guard ApplicationControl.running(target).count == 1 else { fatalError("running app detection") }
        do {
            _ = try await ApplicationControl.launch(target, endpoint: endpoint)
            fatalError("duplicate launch allowed")
        } catch is LauncherError { /* expected */ }
        let snapshot = try DiagnosticSnapshot.collect(target: target, endpoint: endpoint)
        guard snapshot.configured, snapshot.mainPIDs.contains(app.processIdentifier) else {
            fatalError("live diagnostic failed")
        }
        guard app.terminate() else { fatalError("normal termination rejected") }
        for _ in 0..<50 {
            if app.isTerminated { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        guard app.isTerminated else { fatalError("fixture did not terminate") }
        print("PASS: Launch Services arguments + environment, running detection, duplicate rejection, live diagnostics, graceful stop")
    }
}
