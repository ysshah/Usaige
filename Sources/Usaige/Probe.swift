import Foundation

/// Synchronous CLI verification path: fetch both providers, print a summary, exit.
enum Probe {
    static func run() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await printProvider("Claude") { try await ClaudeClient().fetch() }
            await printProvider("Codex") { try await CodexClient().fetch() }
            semaphore.signal()
        }
        semaphore.wait()
    }

    private static func printProvider(_ name: String, _ fetch: () async throws -> UsageSummary) async {
        do {
            let s = try await fetch()
            let plan = s.planName.map { " (\($0))" } ?? ""
            print("\(name)\(plan)")
            print("  5-hour: \(s.fiveHour.percent)%  \(resetLine(s.fiveHour.resetAt))")
            print("  weekly: \(s.weekly.percent)%  \(resetLine(s.weekly.resetAt))")
            if let credits = s.credits { print("  \(credits.label)") }
        } catch {
            print("\(name): ERROR — \(error.localizedDescription)")
        }
    }

    private static func resetLine(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return "(resets \(f.string(from: date)))"
    }
}
