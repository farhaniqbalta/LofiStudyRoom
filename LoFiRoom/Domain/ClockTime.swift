import Foundation

/// Wall-clock maths for the in-world clock. Always 24-hour `HH:mm`, whatever the locale prefers.
enum ClockTime {
    static func text(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// The next instant at which the displayed minute changes.
    static func nextMinute(after date: Date, calendar: Calendar) -> Date {
        calendar.nextDate(after: date, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? date.addingTimeInterval(60)
    }
}
