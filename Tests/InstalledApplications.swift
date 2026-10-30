import AppKit

/// Optional local smoke test. Does not send prompts, edit app data, or terminate
/// an app that was already running. CI uses isolated fixtures instead.
@main
enum InstalledApplications {
    @MainActor
    static func main() async throws {
        let endpoint = try ProxyEndpoint(host: "127.0.0.1", port: "7890")
        for kind in [ApplicationKind.antigravity, .antigravityIDE] {
            let target = try TargetApplication(path: kind.defaultPath, kind: kind)
            print("Recognized \(kind.name) \(target.version)")
            let existing = ApplicationControl.running(target)
            if !existing.isEmpty {
                let snapshot = try DiagnosticSnapshot.collect(target: target, endpoint: endpoint)
                print("EXISTING: \(kind.name); launch left untouched; configured=\(snapshot.configured); proxy sockets=\(snapshot.connections.filter { endpoint.matches(remote: $0.remote) }.count); backend processes=\(snapshot.backendPIDs.count)")
                continue
            }
            let probe = await Task.detached { ProxyProbe.check(endpoint, language: .english, kind: kind) }.value
            guard probe.usable else { throw LauncherError("Proxy unavailable for installed-app smoke test") }
            let app = try await ApplicationControl.launch(target, endpoint: endpoint)
            defer { if !app.isTerminated { app.terminate() } }
            try await Task.sleep(nanoseconds: 5_000_000_000)
            let snapshot = try DiagnosticSnapshot.collect(target: target, endpoint: endpoint)
            guard snapshot.configured, !snapshot.mainPIDs.isEmpty else { throw LauncherError("Installed app did not retain proxy arguments") }
            print("PASS: \(kind.name) launched with proxy arguments; proxy sockets=\(snapshot.connections.filter { endpoint.matches(remote: $0.remote) }.count); backend processes=\(snapshot.backendPIDs.count)")
            guard app.terminate() else { throw LauncherError("Please close the test-launched app manually") }
            for _ in 0..<30 {
                if app.isTerminated { break }
                try await Task.sleep(nanoseconds: 300_000_000)
            }
            guard app.isTerminated else { throw LauncherError("App did not exit; check its save/confirmation dialog") }
        }
        print("No authenticated AI request was submitted. Model responses and backend routing still require a real user request.")
    }
}
