import Foundation

/// A single rate-limit window (5-hour or weekly) reduced to what the UI needs.
struct UsageWindow: Sendable {
    var percent: Int
    var resetAt: Date?
}

/// Optional credits / extra-usage info shown beneath the bars.
struct CreditsInfo: Sendable {
    var label: String
}

/// Unified per-provider snapshot the UI renders, decoded from each tool's raw response.
struct UsageSummary: Sendable {
    var planName: String?
    var fiveHour: UsageWindow
    var weekly: UsageWindow
    var credits: CreditsInfo?
}

// MARK: - Claude raw response (GET /api/oauth/usage)

struct ClaudeUsageResponse: Decodable {
    struct Window: Decodable {
        let utilization: Double
        let resets_at: String?
    }
    struct ExtraUsage: Decodable {
        let is_enabled: Bool?
        let monthly_limit: Double?
        let used_credits: Double?
        let currency: String?
    }
    let five_hour: Window
    let seven_day: Window
    let extra_usage: ExtraUsage?

    func toSummary(planName: String?) -> UsageSummary {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]

        func date(_ s: String?) -> Date? {
            guard let s else { return nil }
            return iso.date(from: s) ?? isoPlain.date(from: s)
        }
        func pct(_ d: Double) -> Int { Int(d.rounded()) }

        var credits: CreditsInfo?
        if let eu = extra_usage, eu.is_enabled == true, let limit = eu.monthly_limit {
            let used = eu.used_credits ?? 0
            let cur = eu.currency ?? "USD"
            credits = CreditsInfo(label: "Extra usage: \(format(used, cur)) / \(format(limit, cur))")
        }

        return UsageSummary(
            planName: planName,
            fiveHour: UsageWindow(percent: pct(five_hour.utilization), resetAt: date(five_hour.resets_at)),
            weekly: UsageWindow(percent: pct(seven_day.utilization), resetAt: date(seven_day.resets_at)),
            credits: credits
        )
    }

    private func format(_ amount: Double, _ currency: String) -> String {
        let sign = currency == "USD" ? "$" : ""
        return "\(sign)\(Int(amount.rounded()))"
    }
}

// MARK: - Codex raw response (GET /backend-api/wham/usage)

struct CodexUsageResponse: Decodable {
    struct Window: Decodable {
        let used_percent: Double
        let reset_at: Double?
    }
    struct RateLimit: Decodable {
        let primary_window: Window?
        let secondary_window: Window?
    }
    struct Credits: Decodable {
        let has_credits: Bool?
        let unlimited: Bool?
        let balance: Double?
    }
    let plan_type: String?
    let rate_limit: RateLimit?
    let credits: Credits?

    func toSummary() -> UsageSummary {
        func window(_ w: Window?) -> UsageWindow {
            guard let w else { return UsageWindow(percent: 0, resetAt: nil) }
            let date = w.reset_at.map { Date(timeIntervalSince1970: $0) }
            return UsageWindow(percent: Int(w.used_percent.rounded()), resetAt: date)
        }

        var credits: CreditsInfo?
        if let c = self.credits {
            if c.unlimited == true {
                credits = CreditsInfo(label: "Credits: unlimited")
            } else if let bal = c.balance {
                credits = CreditsInfo(label: "Credits: \(Int(bal.rounded()))")
            } else if c.has_credits == false {
                credits = CreditsInfo(label: "Credits: none")
            }
        }

        return UsageSummary(
            planName: plan_type?.capitalized,
            fiveHour: window(rate_limit?.primary_window),
            weekly: window(rate_limit?.secondary_window),
            credits: credits
        )
    }
}
