import Foundation
import CoreGraphics
import AppKit

final class MouseMover: ObservableObject {
    @Published var isRunning: Bool = false {
        didSet {
            if isRunning {
                startJiggling()
            } else {
                stopJiggling()
            }
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
