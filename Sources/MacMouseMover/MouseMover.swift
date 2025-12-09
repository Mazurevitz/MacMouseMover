import Foundation
import CoreGraphics
import AppKit
import IOKit.pwr_mgt

// Set to true to enable debug logging, false for production
private let DEBUG_LOG = true
private func log(_ message: String) {
    if DEBUG_LOG { print("[MMM] \(message)") }
}

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
        setupWakeNotification()
        if isRunning {
            startJiggling()
        }
    }

    private func setupWakeNotification() {
        // Restart jiggling after system wake to re-establish power assertion and timers
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            log("System wake detected")
            guard let self = self, self.isRunning else { return }
            // Small delay to let system fully wake
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.isRunning {
                    log("Restarting after wake")
                    self.startJiggling()
                }
            }
        }

        // Also handle screen unlock
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            log("Screen unlock detected")
            guard let self = self, self.isRunning else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.isRunning {
                    log("Restarting after unlock")
                    self.startJiggling()
                }
            }
        }
    }

    private var timer: Timer?
    private var assertionID: IOPMAssertionID = 0

    private func createPowerAssertion() {
        let reason = "MacMouseMover keeping system awake" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result != kIOReturnSuccess {
            print("Failed to create power assertion")
        }
    }

    private func releasePowerAssertion() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }

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
        log("Starting")
        stopJiggling()
        createPowerAssertion()
        jiggle()
        scheduleNextJiggle()
    }

    private func stopJiggling() {
        log("Stopping")
        timer?.invalidate()
        timer = nil
        releasePowerAssertion()
    }

    private var jiggleDirection: Bool = false
    private let idleThreshold: TimeInterval = 10.0 // Only jiggle if user idle for 10+ seconds
    private var lastJiggleTime: Date?

    private func isUserIdle() -> Bool {
        let systemIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)! // All event types
        )

        // If we've jiggled before, check if the system idle time is approximately
        // equal to time since our last jiggle. If so, the user is still idle
        // (only our synthetic events reset the timer).
        if let lastJiggle = lastJiggleTime {
            let timeSinceOurJiggle = Date().timeIntervalSince(lastJiggle)
            // If system idle ≈ time since our jiggle (within 2 seconds), user is still idle
            // If system idle << time since our jiggle, user did something real
            if abs(systemIdleTime - timeSinceOurJiggle) < 2.0 {
                return true // User still idle, only our events happened
            }
        }

        return systemIdleTime >= idleThreshold
    }

    private func simulateKeyPress() {
        // Use Shift key (56) - harmless modifier that won't trigger anything on Windows/Citrix
        // F13-F19 map to Print Screen, Scroll Lock, etc. on Windows
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 56, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 56, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private var consecutiveFailures = 0

    private func jiggle() {
        // Only jiggle if user has been idle - don't disturb active use
        guard isUserIdle() else {
            log("Skipped - user active")
            lastJiggleTime = nil // Reset so next idle check uses threshold
            consecutiveFailures = 0 // User activity means system is responsive
            return
        }

        // Check if previous jiggle actually worked by comparing idle time
        if let lastJiggle = lastJiggleTime {
            let timeSinceJiggle = Date().timeIntervalSince(lastJiggle)
            let systemIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)

            // If system idle is much greater than time since our jiggle, events aren't registering
            if systemIdle > timeSinceJiggle + 5.0 {
                consecutiveFailures += 1
                log("WARNING: Events not registering (idle=\(Int(systemIdle))s, expected=\(Int(timeSinceJiggle))s) failures=\(consecutiveFailures)")

                if consecutiveFailures >= 3 {
                    log("ERROR: CGEvents failing - restarting app")
                    restartApp()
                    return
                }
            } else {
                consecutiveFailures = 0
            }
        }

        log("Jiggling")
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

        // Simulate key press to keep apps like Teams active
        simulateKeyPress()

        // Record when we jiggled so we can distinguish our events from user events
        lastJiggleTime = Date()
    }

    private func restartApp() {
        let url = Bundle.main.bundleURL
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", url.path]
        try? task.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }

    deinit {
        stopJiggling()
    }
}
