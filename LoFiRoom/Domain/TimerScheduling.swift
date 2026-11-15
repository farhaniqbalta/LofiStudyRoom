import Foundation

@MainActor protocol Cancellable { func cancel() }

@MainActor protocol TimerScheduling {
    func schedule(after delay: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> Cancellable
}

/// Real one-shot timers on the main run loop (.common, so they also fire while scrolling).
@MainActor struct LiveTimers: TimerScheduling {
    private final class Box: NSObject, Cancellable {
        var timer: Timer?
        let fire: @MainActor () -> Void
        init(_ fire: @escaping @MainActor () -> Void) { self.fire = fire }
        @objc func go() { fire() }
        func cancel() { timer?.invalidate(); timer = nil }
    }

    func schedule(after delay: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> Cancellable {
        let box = Box(fire)
        let timer = Timer(timeInterval: delay, target: box, selector: #selector(Box.go), userInfo: nil, repeats: false)
        timer.tolerance = delay * 0.1
        RunLoop.main.add(timer, forMode: .common)
        box.timer = timer
        return box
    }
}
