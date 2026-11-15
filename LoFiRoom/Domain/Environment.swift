import Foundation

enum DayPhase: String, Codable { case day, night }
enum Sky: String, Codable { case clear, rain }

/// Time and weather are independent, each automatic or manual (spec §1.4).
enum TimeSetting: Codable, Equatable { case automatic, manual(DayPhase) }
enum WeatherSetting: Codable, Equatable { case automatic, manual(Sky) }

struct City: Codable, Equatable {
    var name: String
    var latitude: Double
    var longitude: Double
}

/// Last weather fetched for the chosen city.
struct WeatherSnapshot: Codable, Equatable {
    var sky: Sky
    var sunrise: Date?
    var sunset: Date?
    var fetched: Date
}

/// What the scene should look like right now. The clock is not part of it: it always shows real time.
struct ResolvedScene: Equatable {
    var phase: DayPhase
    var sky: Sky
    var lampOn: Bool
}

enum EnvironmentRules {
    static let staleAfter: TimeInterval = 2 * 60 * 60

    /// Open-Meteo WMO codes. Drizzle, rain, snow, showers and thunderstorms show as Rain until snow art exists (review D6).
    static func sky(forWeatherCode code: Int) -> Sky {
        switch code {
        case 51...57, 61...67, 71...77, 80...82, 85...86, 95...99: .rain
        default: .clear
        }
    }

    /// Day between sunrise and sunset, compared as times of day so yesterday's data still works today.
    /// Without data: 06:00–18:00 local (review D5).
    static func phase(at date: Date, snapshot: WeatherSnapshot?, calendar: Calendar) -> DayPhase {
        func minutes(_ d: Date) -> Int {
            let c = calendar.dateComponents([.hour, .minute], from: d)
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
        let sunrise = snapshot?.sunrise.map(minutes) ?? 6 * 60
        let sunset = snapshot?.sunset.map(minutes) ?? 18 * 60
        let now = minutes(date)
        return now >= sunrise && now < sunset ? .day : .night
    }

    static func resolve(config: RoomConfig, snapshot: WeatherSnapshot?, now: Date, calendar: Calendar) -> ResolvedScene {
        let phase: DayPhase
        switch config.time {
        case .manual(let manual): phase = manual
        case .automatic: phase = self.phase(at: now, snapshot: snapshot, calendar: calendar)
        }
        let sky: Sky
        switch config.weather {
        case .manual(let manual): sky = manual
        case .automatic: sky = snapshot?.sky ?? .clear
        }
        return ResolvedScene(phase: phase, sky: sky, lampOn: config.lampOn)
    }

    static func isStale(_ snapshot: WeatherSnapshot, now: Date) -> Bool {
        now.timeIntervalSince(snapshot.fetched) >= staleAfter
    }
}
