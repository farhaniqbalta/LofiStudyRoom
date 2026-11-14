import Foundation

/// The one saved room configuration. Values are pack folder names.
struct RoomConfig: Codable, Equatable {
    var schemaVersion = 1
    var character = "Boy01"
    var pet = "OrangeCat"
    var scenery = "NeonCity01"
    var clock = "RetroDigital01"
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
