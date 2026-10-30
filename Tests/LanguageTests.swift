import Foundation

@main
enum LanguageTests {
    @MainActor
    static func main() throws {
        var count = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            precondition(value(), message); count += 1
        }
        check(AppLanguage.resolve(saved: nil, preferred: ["zh-Hant-TW"]) == .traditionalChinese, "Traditional Chinese system language")
        check(AppLanguage.resolve(saved: nil, preferred: ["zh-TW"]) == .traditionalChinese, "Traditional Chinese region")
        check(AppLanguage.resolve(saved: nil, preferred: ["zh-Hans-HK"]) == .chinese, "Explicit Simplified script overrides region")
        check(AppLanguage.resolve(saved: nil, preferred: ["zh-Hant-CN"]) == .traditionalChinese, "Explicit Traditional script overrides region")
        check(AppLanguage.resolve(saved: nil, preferred: ["zh_Hans_TW"]) == .chinese, "Underscore locale identifiers")
        let bundle = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: "Resources/Info.plist")), format: nil) as! [String: Any]
        check(Set(bundle["CFBundleLocalizations"] as! [String]) == Set(AppLanguage.allCases.map(\.rawValue)), "Bundle declares every supported language")
        check(AppLanguage.resolve(saved: nil, preferred: ["fa-IR"]) == .persian, "Persian system language")
        check(AppLanguage.resolve(saved: nil, preferred: ["ru-RU"]) == .russian, "Russian system language")
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
            } else {
                check(report.contains(L10n.text("连接快照不证明全部流量均经过代理；域名代理地址与数字 IP 可能无法直接匹配。其他连接也可能来自本地工具或子进程。", language: language)), "Localized diagnostic limits")
            }
        }
        let failed = ProxyProbe.interpret(CommandResult(status: 7, output: "refused"), language: .english)
        check(failed.description.hasPrefix("Proxy check failed"), "English failed probe")
        let output = L10n.text("代理探测：%@\n状态读取失败：%@", language: .english, arguments: ["100% %@", "second"])
        check(output == "Proxy probe: 100% %@\nCould not read status: second", "Arguments never become format strings")
        for (key, value) in L10n.english {
            check(key.components(separatedBy: "%@").count == value.components(separatedBy: "%@").count, "Translation argument parity")
            check(!value.isEmpty && value.range(of: "[\\p{Han}]", options: .regularExpression) == nil, "English catalog completeness")
        }
        for language in AppLanguage.allCases where language != .chinese && language != .english {
            let catalog = AdditionalTranslations.values[language]!
            check(catalog.count == L10n.english.count, "Complete \(language.rawValue) catalog")
            for (key, value) in catalog {
                check(value.components(separatedBy: "%@").count == key.components(separatedBy: "%@").count, "Placeholder parity in \(language.rawValue)")
                check(!value.isEmpty && value != L10n.english[key], "Translated \(language.rawValue) message")
            }
        }
        defaults.set("localhost", forKey: "proxyHost")
        defaults.set("8080", forKey: "proxyPort")
        let store = LauncherStore(defaults: defaults, monitor: false)
        check(store.models[.chatgpt]!.port == "8080", "Legacy ChatGPT settings retained")
        check(store.models[.antigravity]!.port == "7890", "New apps do not inherit legacy overrides")
        store.models[.antigravity]!.port = "7891"
        store.models[.antigravity]!.save()
        store.models[.antigravityIDE]!.port = "7892" // Draft only.
        store.selected = .antigravityIDE
        store.setLanguage(.arabic)
        check(store.models.values.allSatisfy { $0.language == .arabic }, "Global language synchronizes every app")
        check(store.current.port == "7892" && store.models[.chatgpt]!.port == "8080", "Language and selection preserve independent drafts")
        store.setLanguage(nil)
        check(store.models.values.allSatisfy { $0.followsSystem }, "Follow-system synchronizes every app")
        let restored = LauncherStore(defaults: defaults, monitor: false)
        check(restored.selected == .antigravityIDE, "Selected app persists")
        check(restored.models[.antigravity]!.port == "7891" && restored.current.port == "7890", "Only saved per-app configuration persists")
        check(restored.models[.chatgpt]!.host == "localhost", "Other app settings unchanged")
        store.models[.antigravity]!.busy = true
        let before = store.current.language
        store.setLanguage(.english)
        check(store.current.language == before, "No mixed-language async result while any app is busy")
        store.models[.antigravity]!.busy = false
        for language in AppLanguage.allCases {
            store.setLanguage(language)
            check(store.current.text("运行中") != "运行中" || language == .chinese, "Running state localized")
            let probe = ProxyProbe.interpret(CommandResult(status: 0, output: "200 403"), language: language, kind: .antigravity)
            check(probe.description.contains("antigravity.google") && !probe.description.contains("chatgpt.com"), "Target-specific probe host")
            let report = snapshot.report(endpoint: endpoint, probe: probe, language: language, kind: .antigravityIDE)
            check(report.contains("Antigravity IDE") && !report.contains("ChatGPT"), "Target-specific report")
        }
        print("PASS: \(count) language and preference checks")
    }
}
