import Foundation

@main
enum CoreTests {
    static func main() throws {
        var count = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError(message) }
            count += 1
        }
        let local = try ProxyEndpoint(host: " 127.0.0.1 ", port: "7890")
        check(local.url == "http://127.0.0.1:7890", "default endpoint")
        let ipv6 = try ProxyEndpoint(host: "[::1]", port: "7890")
        check(ipv6.url == "http://[::1]:7890", "IPv6 bracketing")
        check(ipv6.matches(remote: "[::1]:7890"), "IPv6 socket matching")
        for invalid in ["http://127.0.0.1", "127.0.0.1:7890", "a;b", "a b", "user@host", "$(id)", "a/path", "", "-invalid", "a..b"] {
            do { _ = try ProxyEndpoint(host: invalid, port: "7890"); fatalError("Accepted invalid host: \(invalid)") }
            catch { count += 1 }
        }
        for port in ["0", "65536", "-1", "+80", "abc", "", "1 2"] {
            do { _ = try ProxyEndpoint(host: "localhost", port: port); fatalError("Accepted invalid port") }
            catch { count += 1 }
        }
        check(local.launchArguments.contains("--proxy-server=http://127.0.0.1:7890"), "proxy flag")
        check(!local.launchArguments.contains("--no-sandbox"), "preserve sandbox")
        check(local.environment["HTTPS_PROXY"] == local.url && local.environment["https_proxy"] == local.url, "proxy environment")
        check(local.environment["NO_PROXY"] == "localhost,127.0.0.1,::1", "local tools bypass")
        let rows = ProcessRow.parse(" 100 1 /Applications/ChatGPT.app/Contents/MacOS/ChatGPT\n101 100 /Applications/App With Spaces.app/helper\n102 101 /bin/tool\n200 1 /another/app\n")
        check(rows.count == 4 && rows[1].executable.contains("With Spaces"), "process paths with spaces")
        check(ProcessRow.family(roots: [100], rows: rows) == [100, 101, 102], "descendants exclude unrelated apps")
        let sockets = TCPConnection.parse("p100\nf10\nn127.0.0.1:53000->127.0.0.1:7890\np101\nf11\nn[::1]:53001->[::1]:7890\n")
        check(sockets.count == 2 && sockets[1].pid == 101, "lsof parsing")
        check(TCPConnection.warnings(CommandResult(status: 1, output: "p100\nf10\nn127.0.0.1:53000->127.0.0.1:7890\n")).isEmpty, "valid lsof output with exit 1 is not an error")
        check(!TCPConnection.warnings(CommandResult(status: 1, output: "lsof: permission denied\n")).isEmpty, "real lsof error remains visible")
        check(local.matches(remote: sockets[0].remote), "proxy socket matching")
        check(!local.matches(remote: "127.0.0.1:17890"), "port matching must be exact")
        check(ProxyProbe.interpret(CommandResult(status: 0, output: "\n200 403\n")).usable, "HTTP 403 still proves tunnel and TLS")
        check(!ProxyProbe.interpret(CommandResult(status: 60, output: "TLS error\n200 000\n")).usable, "TLS failure must not report success")
        check(!ProxyProbe.interpret(CommandResult(status: 7, output: "refused\n000 000\n")).usable, "closed proxy must fail")
        check(!ProxyProbe.interpret(CommandResult(status: 56, output: "\n407 000\n")).usable, "proxy auth must fail")
        let result = try Commands.run("/usr/bin/printf", ["%s", "literal;$(id)"])
        check(result.output == "literal;$(id)", "arguments never evaluated by shell")
        print("PASS: \(count) checks")
    }
}
