import UIKit

/// Tells the clock what to show: once now, then at each minute boundary, and whenever the system says
/// the time may have jumped (foreground, time-zone change, clock change, midnight/DST). No polling.
@MainActor
final class ClockDriver: NSObject {
    private let now: () -> Date
    private let calendar: () -> Calendar
    private let onTime: (String) -> Void
    private var timer: Timer?

    init(now: @escaping () -> Date = Date.init,
         calendar: @escaping () -> Calendar = { .autoupdatingCurrent },
         onTime: @escaping (String) -> Void) {
        self.now = now
        self.calendar = calendar
        self.onTime = onTime
    }

    func start() {
        let center = NotificationCenter.default
        for name in [UIApplication.didBecomeActiveNotification, UIApplication.significantTimeChangeNotification,
                     .NSSystemTimeZoneDidChange, .NSSystemClockDidChange] {
            center.addObserver(self, selector: #selector(refresh), name: name, object: nil)
        }
        refresh()
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    /// Always recomputes from the wall clock, so a late or missed timer (suspend) cannot leave a stale time.
    @objc func refresh() {
        let date = now(), calendar = calendar()
        onTime(ClockTime.text(for: date, calendar: calendar))
        timer?.invalidate()
        let next = Timer(fireAt: ClockTime.nextMinute(after: date, calendar: calendar), interval: 0,
                         target: self, selector: #selector(refresh), userInfo: nil, repeats: false)
        next.tolerance = 0.5
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }
}
