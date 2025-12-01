import Foundation

final class Schedule: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startScheduleTimer()
            } else {
                stopScheduleTimer()
                onScheduleChange?(false)
            }
        }
    }

    @Published var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var stopTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

    var onScheduleChange: ((Bool) -> Void)?

    private var scheduleTimer: Timer?
    private let checkInterval: TimeInterval = 10.0
    private var wasWithinSchedule: Bool = false

    private func startScheduleTimer() {
        stopScheduleTimer()

        checkSchedule()

        scheduleTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkSchedule()
        }
    }

    private func stopScheduleTimer() {
        scheduleTimer?.invalidate()
        scheduleTimer = nil
    }

    private func checkSchedule() {
        let isWithinSchedule = isCurrentTimeWithinSchedule()

        if isWithinSchedule != wasWithinSchedule {
            wasWithinSchedule = isWithinSchedule
            onScheduleChange?(isWithinSchedule)
        }
    }

    private func isCurrentTimeWithinSchedule() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let stopComponents = calendar.dateComponents([.hour, .minute], from: stopTime)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        guard let startMinutes = startComponents.hour.map({ $0 * 60 + (startComponents.minute ?? 0) }),
              let stopMinutes = stopComponents.hour.map({ $0 * 60 + (stopComponents.minute ?? 0) }),
              let nowMinutes = nowComponents.hour.map({ $0 * 60 + (nowComponents.minute ?? 0) }) else {
            return false
        }

        if startMinutes <= stopMinutes {
            return nowMinutes >= startMinutes && nowMinutes < stopMinutes
        } else {
            return nowMinutes >= startMinutes || nowMinutes < stopMinutes
        }
    }

    deinit {
        stopScheduleTimer()
    }
}
