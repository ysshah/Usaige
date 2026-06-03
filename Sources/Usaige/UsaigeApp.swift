import SwiftUI
import AppKit

@main
struct Entry {
    static func main() {
        // Hidden verification mode: fetch both providers, print, exit — no UI.
        if CommandLine.arguments.contains("--probe") {
            Probe.run()
            return
        }
        UsaigeApp.main()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = UsageStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceWillSleep(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        store.pause()
    }

    @objc private func workspaceWillSleep(_ notification: Notification) {
        store.pause()
    }

    @objc private func workspaceDidWake(_ notification: Notification) {
        store.start()
    }
}

struct UsaigeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(store: delegate.store)
        } label: {
            Text("\(Image(systemName: "gauge.with.dots.needle.33percent")) \(delegate.store.barTitle)")
        }
        .menuBarExtraStyle(.window)
    }
}
