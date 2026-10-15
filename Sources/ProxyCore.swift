import Foundation
import Darwin

struct LauncherError: LocalizedError {
    let message: String
    let arguments: [String]
    var errorDescription: String? { localized(in: .current) }
    init(_ message: String, arguments: [String] = []) { self.message = message; self.arguments = arguments }
    func localized(in language: AppLanguage) -> String { L10n.text(message, language: language, arguments: arguments) }
}

struct ProxyEndpoint: Equatable, Codable {
    let host: String
    let port: Int

    init(host input: String, port inputPort: String) throws {
        var host = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if host.hasPrefix("["), host.hasSuffix("]") { host = String(host.dropFirst().dropLast()) }
        guard !host.isEmpty else { throw LauncherError("请填写代理地址，例如 127.0.0.1。") }
        var v6 = in6_addr()
        let ipv6 = host.withCString { inet_pton(AF_INET6, $0, &v6) == 1 }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        let hostname = host.count <= 253 && labels.allSatisfy { label in
            !label.isEmpty && label.count <= 63 && label.first != "-" && label.last != "-" &&
            label.utf8.allSatisfy { (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45 }
        }
        guard ipv6 || hostname else { throw LauncherError("地址只填写 IP 或域名，不要包含 http://、端口、路径或账号密码。") }
        let portString = inputPort.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !portString.isEmpty, portString.utf8.allSatisfy({ (48...57).contains($0) }),
              let port = Int(portString), (1...65535).contains(port) else {
            throw LauncherError("端口必须是 1～65535 之间的整数。")
        }
        self.host = host.lowercased()
        self.port = port
    }

    var authority: String { "\(host.contains(":") ? "[\(host)]" : host):\(port)" }
    var url: String { "http://\(authority)" }
    var launchArguments: [String] {
        ["--proxy-server=\(url)", "--proxy-bypass-list=localhost;127.0.0.1;[::1]", "--disable-quic"]
    }
    var environment: [String: String] {
        ["HTTP_PROXY": url, "HTTPS_PROXY": url, "ALL_PROXY": url,
         "http_proxy": url, "https_proxy": url, "all_proxy": url,
         "NO_PROXY": "localhost,127.0.0.1,::1", "no_proxy": "localhost,127.0.0.1,::1",
         "NODE_USE_ENV_PROXY": "1"]
    }
    func matches(remote: String) -> Bool {
        let candidates = host == "localhost" ? ["127.0.0.1:\(port)", "[::1]:\(port)"] : [authority]
        return candidates.contains(remote)
    }
}

struct CommandResult {
    let status: Int32
    let output: String
}

enum Commands {
    // Never interpolate user input into a shell command. All arguments are passed separately.
    static func run(_ executable: String, _ arguments: [String], timeout: TimeInterval = 10) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let watchdog = DispatchWorkItem {
            if process.isRunning { process.terminate() }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: watchdog)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        watchdog.cancel()
        return CommandResult(status: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
}

struct TargetApplication {
    let url: URL
    let executable: URL
    let identifier: String
    let version: String

    init(path: String, language: AppLanguage = .current) throws {
        let url = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        guard url.pathExtension == "app", let bundle = Bundle(url: url),
              let executable = bundle.executableURL,
              FileManager.default.isExecutableFile(atPath: executable.path),
              let identifier = bundle.bundleIdentifier else {
            throw LauncherError("找不到有效的 ChatGPT.app，请重新选择应用。")
        }
        let info = bundle.infoDictionary ?? [:]
        let electron = info["ElectronAsarIntegrity"] != nil || info["ChromiumBaseVersion"] != nil ||
            FileManager.default.fileExists(atPath: url.appendingPathComponent("Contents/Frameworks/Electron Framework.framework").path)
        guard electron else {
            throw LauncherError("所选应用不是可识别的 Electron 版本。本工具不能给旧版原生 ChatGPT 强制设置代理。")
        }
        let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? ""
        guard name == "ChatGPT" || identifier == "com.openai.chat" || identifier == "com.openai.codex" else {
            throw LauncherError("请选择 ChatGPT 应用。")
        }
        self.url = url
        self.executable = executable
        self.identifier = identifier
        self.version = info["CFBundleShortVersionString"] as? String ?? L10n.text("未知版本", language: language)
    }
}

struct ProcessRow {
    let pid: Int32
    let parent: Int32
    let executable: String

    static func parse(_ text: String) -> [ProcessRow] {
        text.split(separator: "\n").compactMap { line in
            let fields = line.split(maxSplits: 2, whereSeparator: { $0.isWhitespace })
            guard fields.count == 3, let pid = Int32(fields[0]), let parent = Int32(fields[1]) else { return nil }
            return ProcessRow(pid: pid, parent: parent, executable: String(fields[2]))
        }
    }

    static func family(roots: Set<Int32>, rows: [ProcessRow]) -> Set<Int32> {
        var result = roots
        while true {
            let children = Set(rows.filter { result.contains($0.parent) }.map(\.pid))
            let next = result.union(children)
            if next == result { return result }
            result = next
        }
    }
}

struct TCPConnection: Equatable {
    let pid: Int32
    let route: String
    var remote: String { String(route.components(separatedBy: "->").last ?? "") }

    static func parse(_ text: String) -> [TCPConnection] {
        var pid: Int32 = 0
        var result: [TCPConnection] = []
        for line in text.split(separator: "\n") {
            if line.first == "p" { pid = Int32(line.dropFirst()) ?? 0 }
            if line.first == "n", line.contains("->"), pid > 0 {
                result.append(TCPConnection(pid: pid, route: String(line.dropFirst())))
            }
        }
        return result
    }

    static func warnings(_ result: CommandResult, language: AppLanguage = .current) -> [String] {
        // A vanished PID or a PID without a matching socket can yield exit 1 even with valid records.
        let messages = result.output.split(separator: "\n").filter { $0.hasPrefix("lsof:") }
        if !messages.isEmpty { return [L10n.text("连接读取提示：", language: language) + messages.joined(separator: "\n").prefix(400)] }
        if result.status != 0 && result.status != 1 { return [L10n.text("连接读取未完成（状态 %@）。", language: language, arguments: [String(result.status)])] }
        return []
    }
}

struct ProxyProbe {
    let usable: Bool
    let description: String

    static func interpret(_ result: CommandResult, language: AppLanguage = .current) -> ProxyProbe {
        let metrics = result.output.split(separator: "\n").last.map(String.init) ?? ""
        let codes = metrics.split(separator: " ")
        let connect = codes.count == 2 ? Int(codes[0]) ?? 0 : 0
        let response = codes.count == 2 ? Int(codes[1]) ?? 0 : 0
        if result.status == 0 && connect == 200 && (200...599).contains(response) {
            return ProxyProbe(usable: true, description: L10n.text("HTTP 代理隧道和 TLS 已连通；chatgpt.com 返回 HTTP %@。", language: language, arguments: [String(response)]) + (response >= 400 ? L10n.text("网站拒绝了此探测请求，不代表账号或聊天可用。", language: language) : ""))
        }
        if connect == 407 { return ProxyProbe(usable: false, description: L10n.text("代理要求认证。请使用无需账号密码的本地代理端口。", language: language)) }
        return ProxyProbe(usable: false, description: L10n.text("代理测试未通过。请确认本地代理正在运行、端口正确且服务可用。\n", language: language) + String(result.output.prefix(900)))
    }

    static func check(_ endpoint: ProxyEndpoint, language: AppLanguage = .current) -> ProxyProbe {
        do {
            let result = try Commands.run("/usr/bin/curl", ["--disable", "--silent", "--show-error", "--head",
                "--proxy", endpoint.url, "--noproxy", "", "--connect-timeout", "5", "--max-time", "12",
                "--output", "/dev/null", "--write-out", "\n%{http_connect} %{http_code}\n",
                "https://chatgpt.com/"], timeout: 15)
            return interpret(result, language: language)
        } catch { return ProxyProbe(usable: false, description: L10n.error(error, language: language)) }
    }
}

struct DiagnosticSnapshot {
    let mainPIDs: [Int32]
    let configured: Bool
    let arguments: String
    let connections: [TCPConnection]
    let warnings: [String]

    static func collect(target: TargetApplication, endpoint: ProxyEndpoint, language: AppLanguage = .current) throws -> DiagnosticSnapshot {
        let ps = try Commands.run("/bin/ps", ["-axo", "pid=,ppid=,comm="])
        guard ps.status == 0 else { throw LauncherError("无法读取进程列表：%@" , arguments: [String(ps.output)]) }
        let rows = ProcessRow.parse(ps.output)
        let mainPIDs = rows.filter { $0.executable == target.executable.path }.map(\.pid)
        guard !mainPIDs.isEmpty else {
            return DiagnosticSnapshot(mainPIDs: [], configured: false, arguments: "", connections: [], warnings: [])
        }
        var argumentLines: [String] = []
        var warnings: [String] = []
        for pid in mainPIDs {
            let args = try Commands.run("/bin/ps", ["-ww", "-p", String(pid), "-o", "args="])
            if args.status == 0 { argumentLines.append(args.output.trimmingCharacters(in: .whitespacesAndNewlines)) }
            else { warnings.append(L10n.text("无法读取 PID %@ 的启动参数。", language: language, arguments: [String(pid)])) }
        }
        let configured = argumentLines.count == mainPIDs.count && argumentLines.allSatisfy { line in
            let tokens = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            return tokens.contains("--proxy-server=\(endpoint.url)") && !tokens.contains("--no-proxy-server") &&
                tokens.filter { $0.hasPrefix("--proxy-server=") }.count == 1
        }
        let family = ProcessRow.family(roots: Set(mainPIDs), rows: rows)
        let sockets = try Commands.run("/usr/sbin/lsof", ["-nP", "-a", "-p", family.sorted().map(String.init).joined(separator: ","),
            "-iTCP", "-sTCP:ESTABLISHED", "-F", "pn"], timeout: 12)
        warnings.append(contentsOf: TCPConnection.warnings(sockets, language: language))
        return DiagnosticSnapshot(mainPIDs: mainPIDs, configured: configured, arguments: argumentLines.joined(separator: "\n"),
                                  connections: TCPConnection.parse(sockets.output), warnings: warnings)
    }

    func report(endpoint: ProxyEndpoint, probe: ProxyProbe, language: AppLanguage = .current) -> String {
        func t(_ key: String, _ args: String...) -> String { L10n.text(key, language: language, arguments: args) }
        let matched = connections.filter { endpoint.matches(remote: $0.remote) }
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return [
            t("检查时间：%@", formatter.string(from: Date())),
            t("检查地址：%@", endpoint.url),
            "ChatGPT: " + (mainPIDs.isEmpty ? t("未运行") : t("运行中（PID %@）", mainPIDs.map(String.init).joined(separator: ", "))),
            t("启动参数：%@", configured ? t("与当前代理地址匹配") : t("未确认匹配")),
            t("代理探测：%@", probe.description),
            t("实际连接：%@", matched.isEmpty ? t("本次快照未观察到到该代理的 TCP 连接") : t("观察到 %@ 条到该代理的 TCP 连接", String(matched.count))),
            "", t("ChatGPT 及其子进程的当前 TCP 连接："),
            connections.isEmpty ? t("无可见的已建立连接") : connections.map { "PID \($0.pid)  \($0.route)" }.joined(separator: "\n"),
            "", warnings.joined(separator: "\n"),
            t("连接快照不证明全部流量均经过代理；域名代理地址与数字 IP 可能无法直接匹配。其他连接也可能来自本地工具或子进程。"),
            t("代理探测由启动器独立发起，不等于 ChatGPT 已使用代理。语音 / WebRTC / UDP 与不支持代理环境变量的子进程不在保证范围内。")
        ].joined(separator: "\n")
    }
}
