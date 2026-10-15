import Foundation

@main
enum LanguageTests {
    @MainActor
    static func main() throws {
        var count = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            precondition(value(), message); count += 1
        }
        check(AppLanguage.resolve(saved: nil, preferred: ["zh-Hant-TW"]) == .chinese, "Chinese system fallback")
        check(AppLanguage.resolve(saved: nil, preferred: ["fr-FR"]) == .english, "Other systems use English")
        check(AppLanguage.resolve(saved: "en", preferred: ["zh-Hans"]) == .english, "Saved choice wins")
        check(AppLanguage.resolve(saved: "invalid", preferred: ["en"]) == .english, "Invalid preference falls back")
        let domain = "local.route-launcher.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set("zh-Hans", forKey: "interfaceLanguage")
        defaults.set("localhost", forKey: "proxyHost")
        defaults.set("8080", forKey: "proxyPort")
        defaults.set("/nonexistent/ChatGPT.app", forKey: "targetPath")
        let model = LauncherModel(defaults: defaults, monitor: false)
        check(model.language == .chinese && model.proxyStatus == "尚未检查", "Initial language")
        model.host = "127.0.0.1" // Unsaved edits must survive a language change.
        model.setLanguage(.english)
        check(model.proxyStatus == "Not checked" && model.message.contains("Language changed"), "Immediate model translation")
        check(model.host == "127.0.0.1" && model.port == "8080", "Preserve unsaved network settings")
        check(defaults.string(forKey: "proxyHost") == "localhost", "Language change does not save network edits")
        let reopened = LauncherModel(defaults: defaults, monitor: false)
        check(reopened.language == .english && reopened.host == "localhost", "Choice persists across launches")
        model.host = "http://invalid"
        model.save()
        check(model.isError && model.message.hasPrefix("Enter only"), "English validation errors")
        model.setLanguage(.chinese)
        model.save()
        check(model.isError && model.message.hasPrefix("地址只填写"), "Chinese validation errors")
        model.busy = true
        model.setLanguage(.english)
        check(model.language == .chinese, "Language stays consistent during async operations")
        model.busy = false
        let endpoint = try ProxyEndpoint(host: "127.0.0.1", port: "7890")
        let snapshot = DiagnosticSnapshot(mainPIDs: [42], configured: true, arguments: "", connections: [TCPConnection(pid: 42, route: "127.0.0.1:5000->127.0.0.1:7890")], warnings: [])
        for language in AppLanguage.allCases {
            let probe = ProxyProbe.interpret(CommandResult(status: 0, output: "200 403"), language: language)
            let report = snapshot.report(endpoint: endpoint, probe: probe, language: language)
            check(probe.usable && report.contains("403") && report.contains("7890"), "Keep diagnostic facts in both languages")
            if language == .english {
                check(report.range(of: "[\\p{Han}]", options: .regularExpression) == nil, "No Chinese in English report")
                check(report.contains("does not prove") && report.contains("not guaranteed"), "Preserve diagnostic limits")
            } else { check(report.contains("不证明全部流量"), "Chinese diagnostic limits") }
        }
        let failed = ProxyProbe.interpret(CommandResult(status: 7, output: "refused"), language: .english)
        check(failed.description.hasPrefix("Proxy check failed"), "English failed probe")
        let output = L10n.text("代理探测：%@\n状态读取失败：%@", language: .english, arguments: ["100% %@", "second"])
        check(output == "Proxy probe: 100% %@\nCould not read status: second", "Arguments never become format strings")
        for (key, value) in L10n.english {
            check(key.components(separatedBy: "%@").count == value.components(separatedBy: "%@").count, "Translation argument parity")
            check(!value.isEmpty && value.range(of: "[\\p{Han}]", options: .regularExpression) == nil, "English catalog completeness")
        }
        print("PASS: \(count) language and preference checks")
    }
}
