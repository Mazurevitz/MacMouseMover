import Foundation

final class Schedule: ObservableObject {
    private static let isEnabledKey = "Schedule.isEnabled"
    private static let weekdayStartTimeKey = "Schedule.weekdayStartTime"
    private static let weekdayStopTimeKey = "Schedule.weekdayStopTime"
    private static let weekendStartTimeKey = "Schedule.weekendStartTime"
    private static let weekendStopTimeKey = "Schedule.weekendStopTime"
    private static let weekendScheduleEnabledKey = "Schedule.weekendScheduleEnabled"

    @Published var isEnabled: Bool = UserDefaults.standard.bool(forKey: Schedule.isEnabledKey) {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Schedule.isEnabledKey)
            if isEnabled {
                startScheduleTimer()
            } else {
                stopScheduleTimer()
                onScheduleChange?(false)
            }
        }
    }

    @Published var weekdayStartTime: Date = UserDefaults.standard.object(forKey: Schedule.weekdayStartTimeKey) as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date() {
        didSet {
            UserDefaults.standard.set(weekdayStartTime, forKey: Schedule.weekdayStartTimeKey)
        }
    }

    @Published var weekdayStopTime: Date = UserDefaults.standard.object(forKey: Schedule.weekdayStopTimeKey) as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date() {
        didSet {
            UserDefaults.standard.set(weekdayStopTime, forKey: Schedule.weekdayStopTimeKey)
        }
    }

    @Published var weekendScheduleEnabled: Bool = UserDefaults.standard.bool(forKey: Schedule.weekendScheduleEnabledKey) {
        didSet {
            UserDefaults.standard.set(weekendScheduleEnabled, forKey: Schedule.weekendScheduleEnabledKey)
        }
    }

    @Published var weekendStartTime: Date = UserDefaults.standard.object(forKey: Schedule.weekendStartTimeKey) as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 10, minute: 0)) ?? Date() {
        didSet {
            UserDefaults.standard.set(weekendStartTime, forKey: Schedule.weekendStartTimeKey)
        }
    }

    @Published var weekendStopTime: Date = UserDefaults.standard.object(forKey: Schedule.weekendStopTimeKey) as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date() {
        didSet {
            UserDefaults.standard.set(weekendStopTime, forKey: Schedule.weekendStopTimeKey)
        }
    }

    init() {
        if isEnabled {
            startScheduleTimer()
        }
    }

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

    private var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }

    private func isCurrentTimeWithinSchedule() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let startTime: Date
        let stopTime: Date

        if isWeekend && weekendScheduleEnabled {
            startTime = weekendStartTime
            stopTime = weekendStopTime
        } else if isWeekend && !weekendScheduleEnabled {
            return false
        } else {
            startTime = weekdayStartTime
            stopTime = weekdayStopTime
        }

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
