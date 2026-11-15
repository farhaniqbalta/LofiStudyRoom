import Foundation

/// The one saved room configuration. Pack values are folder names; unknown ones fall back to the first pack that loads.
struct RoomConfig: Codable, Equatable {
    var schemaVersion = 2
    var character = "Boy01"
    var pet = "OrangeCat"
    var scenery = "NeonCity01"
    var clock = "RetroDigital01"
    var lampOn = true
    var time = TimeSetting.automatic
    var weather = WeatherSetting.automatic
    var city: City?
    var keepAwake = false

    init() {}

    /// Missing keys take their defaults, so a save from an older version keeps what it has.
    /// (Synthesized decoding would throw on the first missing key and the store would reset everything.)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = RoomConfig()
        character = try c.decodeIfPresent(String.self, forKey: .character) ?? d.character
        pet = try c.decodeIfPresent(String.self, forKey: .pet) ?? d.pet
        scenery = try c.decodeIfPresent(String.self, forKey: .scenery) ?? d.scenery
        clock = try c.decodeIfPresent(String.self, forKey: .clock) ?? d.clock
        lampOn = try c.decodeIfPresent(Bool.self, forKey: .lampOn) ?? d.lampOn
        time = try c.decodeIfPresent(TimeSetting.self, forKey: .time) ?? d.time
        weather = try c.decodeIfPresent(WeatherSetting.self, forKey: .weather) ?? d.weather
        city = try c.decodeIfPresent(City.self, forKey: .city)
        keepAwake = try c.decodeIfPresent(Bool.self, forKey: .keepAwake) ?? d.keepAwake
    }
}

/// Holds the active configuration and saves every change.
@MainActor
final class RoomStateStore {
    private let defaults: UserDefaults
    private static let key = "roomConfig"

    var config: RoomConfig {
        didSet {
            guard config != oldValue, let data = try? JSONEncoder().encode(config) else { return }
            defaults.set(data, forKey: Self.key)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // A missing or unreadable save falls back to the default room rather than blocking launch.
        config = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(RoomConfig.self, from: $0) } ?? RoomConfig()
    }
}
