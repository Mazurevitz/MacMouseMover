import Foundation
import CoreGraphics
import AppKit

enum JiggleInterval: Int, CaseIterable {
    case thirtySeconds = 30
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300

    var label: String {
        switch self {
        case .thirtySeconds: return "30 seconds"
        case .oneMinute: return "1 minute"
        case .twoMinutes: return "2 minutes"
        case .fiveMinutes: return "5 minutes"
        }
    }

    var seconds: TimeInterval {
        return TimeInterval(rawValue)
    }
}

final class MouseMover: ObservableObject {
    private static let isRunningKey = "MouseMover.isRunning"
    private static let intervalKey = "MouseMover.interval"

    @Published var isRunning: Bool = UserDefaults.standard.bool(forKey: MouseMover.isRunningKey) {
        didSet {
            UserDefaults.standard.set(isRunning, forKey: MouseMover.isRunningKey)
            if isRunning {
                startJiggling()
            } else {
                stopJiggling()
            }
        }
    }

    @Published var interval: JiggleInterval = JiggleInterval(rawValue: UserDefaults.standard.integer(forKey: MouseMover.intervalKey)) ?? .thirtySeconds {
        didSet {
            UserDefaults.standard.set(interval.rawValue, forKey: MouseMover.intervalKey)
            if isRunning {
                startJiggling()
            }
        }
    }

    init() {
        if isRunning {
            startJiggling()
        }
    }

    private var timer: Timer?

    private func startJiggling() {
        stopJiggling()

        jiggle()

        timer = Timer.scheduledTimer(withTimeInterval: interval.seconds, repeats: true) { [weak self] _ in
            self?.jiggle()
        }
    }

    private func stopJiggling() {
        timer?.invalidate()
        timer = nil
    }

    private var jiggleDirection: Bool = false

    private func jiggle() {
        let currentLocation = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 0

        // Move 1 pixel in alternating directions
        let offset: CGFloat = jiggleDirection ? 1.0 : -1.0
        jiggleDirection.toggle()

        let movedPoint = CGPoint(
            x: currentLocation.x + offset,
            y: screenHeight - currentLocation.y
        )

        // Move to offset position
        let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: movedPoint,
            mouseButton: .left
        )
        moveEvent?.post(tap: .cghidEventTap)

        // Move back to original position
        let returnPoint = CGPoint(
            x: currentLocation.x,
            y: screenHeight - currentLocation.y
        )
        let returnEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: returnPoint,
            mouseButton: .left
        )
        returnEvent?.post(tap: .cghidEventTap)
    }

    deinit {
        stopJiggling()
    }
}
