import Foundation
import Observation

enum ProviderState {
    case loading
    case ok(UsageSummary)
    case error(String)

    /// Compact menu-bar fragment for one provider, e.g. "4%" or "⚠".
    var barFragment: String {
        switch self {
        case .loading: return "…"
        case .ok(let s): return "\(s.worstPercent)%"
        case .error: return "⚠"
        }
    }
}

@MainActor
@Observable
final class UsageStore {
    var claude: ProviderState = .loading
    var codex: ProviderState = .loading
    var lastUpdated: Date?

    /// Polling cadence.
    private let interval: Duration = .seconds(300)
    private var pollTask: Task<Void, Never>?

    /// Menu bar label, e.g. "C 4% · X 37%".
    var barTitle: String {
        "C \(claude.barFragment) · X \(codex.barFragment)"
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: self?.interval ?? .seconds(300))
            }
        }
    }

    func refresh() async {
        async let claudeResult = Self.load { try await ClaudeClient().fetch() }
        async let codexResult = Self.load { try await CodexClient().fetch() }
        claude = await claudeResult
        codex = await codexResult
        lastUpdated = Date()
    }

    private static func load(_ work: () async throws -> UsageSummary) async -> ProviderState {
        do {
            return .ok(try await work())
        } catch {
            return .error(error.localizedDescription)
        }
    }
}
