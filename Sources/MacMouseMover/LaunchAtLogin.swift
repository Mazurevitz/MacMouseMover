import Foundation
import ServiceManagement

final class LaunchAtLogin: ObservableObject {
    private static let key = "LaunchAtLogin.isEnabled"

    @Published var isEnabled: Bool = UserDefaults.standard.bool(forKey: LaunchAtLogin.key) {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: LaunchAtLogin.key)
            syncLoginItem()
        }
    }

    init() {
        // Sync actual system state with our stored preference
        let systemEnabled = SMAppService.mainApp.status == .enabled
        if isEnabled != systemEnabled {
            syncLoginItem()
        }
    }

    private func syncLoginItem() {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
