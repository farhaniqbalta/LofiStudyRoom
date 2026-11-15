import Foundation
@testable import LoFiRoom

@MainActor
final class FakeTimers: TimerScheduling {
    private final class Entry: Cancellable {
        let time: TimeInterval
        let fire: @MainActor () -> Void
        var cancelled = false
        init(time: TimeInterval, fire: @escaping @MainActor () -> Void) { self.time = time; self.fire = fire }
        func cancel() { cancelled = true }
    }

    private var entries: [Entry] = []
    var now: TimeInterval = 0

    var pendingDelays: [TimeInterval] { entries.filter { !$0.cancelled }.map { $0.time - now }.sorted() }

    func schedule(after delay: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> Cancellable {
        let entry = Entry(time: now + delay, fire: fire)
        entries.append(entry)
        return entry
    }

    func advance(by delta: TimeInterval) {
        let target = now + delta
        while let next = entries.filter({ !$0.cancelled && $0.time <= target }).min(by: { $0.time < $1.time }) {
            now = max(now, next.time)
            entries.removeAll { $0 === next }
            next.fire()
        }
        now = target
    }
}
