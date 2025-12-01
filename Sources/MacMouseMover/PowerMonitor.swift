import Foundation
import IOKit.ps

final class PowerMonitor: ObservableObject {
    private static let pauseOnBatteryKey = "PowerMonitor.pauseOnBattery"

    @Published var pauseOnBattery: Bool = UserDefaults.standard.bool(forKey: PowerMonitor.pauseOnBatteryKey) {
        didSet {
            UserDefaults.standard.set(pauseOnBattery, forKey: PowerMonitor.pauseOnBatteryKey)
        }
    }

    @Published var isOnBattery: Bool = false

    var onPowerChange: ((Bool) -> Void)?

    private var runLoopSource: CFRunLoopSource?

    init() {
        isOnBattery = checkBatteryStatus()
        startMonitoring()
    }

    private func startMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.powerSourceChanged()
        }, context).takeRetainedValue()

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }

    private func powerSourceChanged() {
        let wasOnBattery = isOnBattery
        isOnBattery = checkBatteryStatus()

        if wasOnBattery != isOnBattery {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.pauseOnBattery {
                    self.onPowerChange?(self.isOnBattery)
                }
            }
        }
    }

    private func checkBatteryStatus() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return false
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                return powerSource == kIOPSBatteryPowerValue
            }
        }

        return false
    }

    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
}
