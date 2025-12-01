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
    private static let randomizeKey = "MouseMover.randomize"

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

    @Published var randomize: Bool = UserDefaults.standard.bool(forKey: MouseMover.randomizeKey) {
        didSet {
            UserDefaults.standard.set(randomize, forKey: MouseMover.randomizeKey)
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

    private func randomizedInterval() -> TimeInterval {
        let base = interval.seconds
        // Vary by ±20%
        let variance = base * 0.2
        return base + Double.random(in: -variance...variance)
    }

    private func scheduleNextJiggle() {
        let nextInterval = randomize ? randomizedInterval() : interval.seconds
        timer = Timer.scheduledTimer(withTimeInterval: nextInterval, repeats: false) { [weak self] _ in
            self?.jiggle()
            self?.scheduleNextJiggle()
        }
    }

    private func startJiggling() {
        stopJiggling()
        jiggle()
        scheduleNextJiggle()
    }

    private func stopJiggling() {
        timer?.invalidate()
        timer = nil
    }

    private var jiggleDirection: Bool = false

    private func jiggle() {
        let currentLocation = NSEvent.mouseLocation

        // Find the screen containing the mouse cursor
        let screen = NSScreen.screens.first { NSMouseInRect(currentLocation, $0.frame, false) } ?? NSScreen.main
        let screenHeight = screen?.frame.maxY ?? 0

        // Move in alternating directions with optional randomization
        let baseOffset: CGFloat = jiggleDirection ? 1.0 : -1.0
        let offset: CGFloat = randomize ? baseOffset * CGFloat.random(in: 1.0...3.0) : baseOffset
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
