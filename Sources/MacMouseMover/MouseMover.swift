import Foundation
import CoreGraphics
import AppKit

final class MouseMover: ObservableObject {
    private static let isRunningKey = "MouseMover.isRunning"

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

    init() {
        if isRunning {
            startJiggling()
        }
    }

    private var timer: Timer?
    private let jiggleInterval: TimeInterval = 30.0

    private func startJiggling() {
        stopJiggling()

        jiggle()

        timer = Timer.scheduledTimer(withTimeInterval: jiggleInterval, repeats: true) { [weak self] _ in
            self?.jiggle()
        }
    }

    private func stopJiggling() {
        timer?.invalidate()
        timer = nil
    }

    private func jiggle() {
        let currentLocation = NSEvent.mouseLocation

        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgPoint = CGPoint(x: currentLocation.x, y: screenHeight - currentLocation.y)

        let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: cgPoint,
            mouseButton: .left
        )
        event?.post(tap: .cghidEventTap)
    }

    deinit {
        stopJiggling()
    }
}
