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
