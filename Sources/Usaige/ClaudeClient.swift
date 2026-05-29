import Foundation

enum UsageError: LocalizedError {
    case notSignedIn
    case authExpired
    case http(Int)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in"
        case .authExpired: return "Auth expired — sign in via the CLI to refresh"
        case .http(let code): return "Request failed (HTTP \(code))"
        case .message(let m): return m
        }
    }
}

struct ClaudeClient {
    static let keychainService = "Claude Code-credentials"
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    /// Shape of the JSON blob stored in the Keychain item.
    private struct Credentials: Decodable {
        struct OAuth: Decodable {
            let accessToken: String
            let subscriptionType: String?
        }
        let claudeAiOauth: OAuth
    }

    func fetch() async throws -> UsageSummary {
        let creds = try readCredentials()

        var request = URLRequest(url: Self.usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.claudeAiOauth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
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

        let decoded = try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
        let plan = creds.claudeAiOauth.subscriptionType.map { $0.capitalized }
        return decoded.toSummary(planName: plan)
    }

    private func readCredentials() throws -> Credentials {
        let raw: String
        do {
            raw = try Keychain.readGenericPassword(service: Self.keychainService)
        } catch KeychainError.notFound {
            throw UsageError.notSignedIn
        }
        guard let data = raw.data(using: .utf8) else { throw UsageError.notSignedIn }
        return try JSONDecoder().decode(Credentials.self, from: data)
    }
}
