import Foundation

@main
enum UpdateTests {
    @MainActor static func main() async throws {
        var count = 0
        func check(_ value: Bool, _ note: String) { precondition(value, note); count += 1 }
        func payload(_ tag: String, draft: Bool = false, prerelease: Bool = false, url: String? = nil) throws -> Data {
            try JSONSerialization.data(withJSONObject: ["tag_name": tag, "draft": draft, "prerelease": prerelease,
                "html_url": url ?? ReleaseUpdate.repository + "/releases/tag/" + tag])
        }
        for value in ["1.4", "v1.4.1-beta", "1.4.1+build", "1.04.0", "-1.2.3", "1.2.3.4", "１.2.3", "1.2.99999999999999999999999999"] {
            check(ReleaseVersion(value) == nil, "Rejected invalid/staged version " + value)
        }
        check(ReleaseVersion("v1.10.0")! > ReleaseVersion("1.9.9")!, "Numeric, not lexical ordering")
        check(try ReleaseUpdate.parse(payload("v1.4.1"), current: "1.4.0").isNewer, "New stable version")
        check(try !ReleaseUpdate.parse(payload("v1.4.0"), current: "1.4.0").isNewer, "Same version")
        check(try !ReleaseUpdate.parse(payload("v1.3.0"), current: "1.4.0").isNewer, "Development version ahead of stable")
        for data in [try payload("v1.4.1", draft: true), try payload("v1.4.1", prerelease: true), try payload("v1.4.1", url: "https://example.com/download"), try payload("v1.4.1", url: ReleaseUpdate.repository + "/releases/tag/v1.4.1?redirect=elsewhere"), Data("{}".utf8)] {
            do { _ = try ReleaseUpdate.parse(data, current: "1.4.0"); preconditionFailure("Accepted untrusted release") }
            catch { count += 1 }
        }
        let domain = "local.route.update-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let model = UpdateModel(defaults: defaults, version: "1.4.0")
        check(model.automatic && model.release == nil && !model.checking, "No network on construction")
        model.automatic = false
        check(!UpdateModel(defaults: defaults, version: "1.4.0").automatic, "Persist startup opt-out")
        let release = try ReleaseUpdate.parse(payload("v1.4.1"), current: "1.4.0")
        await model.check { _ in release }
        check(model.release == release && !model.failed && !model.checking, "Success")
        await model.check { _ in throw URLError(.timedOut) }
        check(model.failed && model.release == nil && !model.checking, "Failure clears stale result")
        await model.check { _ in release }
        check(!model.failed && model.release == release, "Retry recovers")
        var calls = 0
        let first = Task { await model.check { _ in calls += 1; try await Task.sleep(nanoseconds: 100_000_000); return release } }
        await Task.yield()
        await model.check { _ in calls += 1; return release }
        await first.value
        check(calls == 1, "Deduplicate concurrent checks")
        print("PASS: \(count) update checks")
    }
}
