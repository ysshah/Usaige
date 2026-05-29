import SwiftUI

struct MenuContentView: View {
    @Bindable var store: UsageStore
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            providerSection(title: "Claude", state: store.claude)
            Divider()
            providerSection(title: "Codex", state: store.codex)

            Divider()

            HStack {
                Text(lastUpdatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh now")
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.callout)
                .onChange(of: launchAtLogin) { _, newValue in
                    LoginItem.setEnabled(newValue)
                    launchAtLogin = LoginItem.isEnabled
                }

            Button("Quit Usaige") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 280)
    }

    @ViewBuilder
    private func providerSection(title: String, state: ProviderState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case .loading:
                header(title, plan: nil)
                Text("Loading…").font(.caption).foregroundStyle(.secondary)
            case .error(let message):
                header(title, plan: nil)
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            case .ok(let summary):
                header(title, plan: summary.planName)
                windowRow(label: "5-hour", window: summary.fiveHour)
                windowRow(label: "Weekly", window: summary.weekly)
                if let credits = summary.credits {
                    Text(credits.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func header(_ title: String, plan: String?) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.headline)
            if let plan {
                Text(plan)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private func windowRow(label: String, window: UsageWindow) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(window.percent)%").font(.caption.monospacedDigit())
                if let reset = window.resetAt {
                    Text("· \(Self.resetText(reset))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: Double(min(max(window.percent, 0), 100)), total: 100)
                .progressViewStyle(.linear)
        }
    }

    private var lastUpdatedText: String {
        guard let date = store.lastUpdated else { return "Never updated" }
        let f = DateFormatter()
        f.timeStyle = .short
        return "Updated \(f.string(from: date))"
    }

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func resetText(_ date: Date) -> String {
        "resets \(relative.localizedString(for: date, relativeTo: Date()))"
    }
}
