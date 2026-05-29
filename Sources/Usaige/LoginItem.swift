import Foundation
import ServiceManagement

/// Thin wrapper over SMAppService for the "Launch at login" toggle.
/// Only meaningful when running from the bundled .app (registered by bundle id).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Usaige: login item toggle failed: \(error)")
        }
    }
}
