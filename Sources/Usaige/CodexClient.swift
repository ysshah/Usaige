import Foundation

struct CodexClient {
    static let authPath = ("~/.codex/auth.json" as NSString).expandingTildeInPath
    static let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    private struct Auth: Decodable {
        struct Tokens: Decodable {
            let access_token: String
            let account_id: String
        }
        let tokens: Tokens
    }

    func fetch() async throws -> UsageSummary {
        let auth = try readAuth()

        var request = URLRequest(url: Self.usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(auth.tokens.access_token)", forHTTPHeaderField: "Authorization")
        request.setValue(auth.tokens.account_id, forHTTPHeaderField: "chatgpt-account-id")
        request.setValue("Usaige", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw UsageError.message("No HTTP response")
        }
        switch http.statusCode {
        case 200: break
        case 401, 403: throw UsageError.authExpired
        default: throw UsageError.http(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
        return decoded.toSummary()
    }

    private func readAuth() throws -> Auth {
        guard let data = FileManager.default.contents(atPath: Self.authPath) else {
            throw UsageError.notSignedIn
        }
        return try JSONDecoder().decode(Auth.self, from: data)
    }
}
