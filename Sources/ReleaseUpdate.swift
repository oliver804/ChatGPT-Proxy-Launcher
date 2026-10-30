import Foundation

/// Stable releases only; never treats a prerelease or an arbitrary URL as an update.
struct ReleaseVersion: Comparable, Equatable {
    let parts: [Int]
    init?(_ text: String) {
        let value = text.hasPrefix("v") ? String(text.dropFirst()) : text
        let fields = value.split(separator: ".", omittingEmptySubsequences: false)
        guard fields.count == 3, fields.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) && ($0.count == 1 || !$0.hasPrefix("0")) }),
              let major = Int(fields[0]), let minor = Int(fields[1]), let patch = Int(fields[2]) else { return nil }
        parts = [major, minor, patch]
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.parts.lexicographicallyPrecedes(rhs.parts) }
}

struct ReleaseUpdate: Equatable {
    static let repository = "https://github.com/oliver804/Local-Route-Launcher"
    static let releasesURL = URL(string: repository + "/releases")!
    static let apiURL = URL(string: "https://api.github.com/repos/oliver804/Local-Route-Launcher/releases/latest")!
    let version: String
    let url: URL
    let isNewer: Bool
    private struct Payload: Decodable { let tag_name: String; let draft: Bool; let prerelease: Bool; let html_url: String }
    static func parse(_ data: Data, current: String) throws -> Self {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard !payload.draft, !payload.prerelease, let latest = ReleaseVersion(payload.tag_name), let installed = ReleaseVersion(current),
              payload.html_url == repository + "/releases/tag/" + payload.tag_name,
              let url = URL(string: payload.html_url) else { throw URLError(.cannotParseResponse) }
        return Self(version: payload.tag_name, url: url, isNewer: latest > installed)
    }
    static func fetch(current: String) async throws -> Self {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Local-Route-Launcher", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count <= 1_048_576 else { throw URLError(.badServerResponse) }
        return try parse(data, current: current)
    }
}
