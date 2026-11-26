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
    var routineFrequency = 1.0 { didSet { routineFrequency = Self.clamp(routineFrequency, Self.routineFrequencyRange) } }
    var rainSound = RainSoundMode.whenRaining
    var rainVolume = 0.4 { didSet { rainVolume = Self.clamp(rainVolume, 0...1) } }
    /// The art set to open with next launch (nil: the registry's active set). A launch argument wins over it.
    var artSet: String?

    /// How many times as often routines run; 1 is the manifest pacing.
    static let routineFrequencyRange: ClosedRange<Double> = 0.5...20

    private static func clamp(_ x: Double, _ r: ClosedRange<Double>) -> Double { min(max(x, r.lowerBound), r.upperBound) }

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
        routineFrequency = Self.clamp(try c.decodeIfPresent(Double.self, forKey: .routineFrequency) ?? d.routineFrequency, Self.routineFrequencyRange)
        rainSound = try c.decodeIfPresent(RainSoundMode.self, forKey: .rainSound) ?? d.rainSound
        rainVolume = Self.clamp(try c.decodeIfPresent(Double.self, forKey: .rainVolume) ?? d.rainVolume, 0...1)
        artSet = try c.decodeIfPresent(String.self, forKey: .artSet)
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
