import Foundation

extension SceneCoordinator {
    /// Builds the running room from the bundle and launch arguments.
    /// Launch arguments: `-fps 12`, `-paused YES`, `-debugAnchors YES` (anchor overlay + FPS counter), and
    /// `-artSet <A|B|...>` or `-scene <folder>` (default: the set chosen in Settings, else the active set in `Assets/art-sets.json`), `-character Girl01`, `-pet BlackCat`, `-scenery NeonCity02` to choose packs (the choice is saved),
    /// `-time auto|day|night`, `-weather auto|clear|rain`, `-lamp on|off` (saved too; unknown values are ignored),
    /// `-cityName <text> -cityLat <number> -cityLon <number>` (all three) set the weather city,
    /// `-showPanel YES` opens the settings panel at launch, `-showMusic YES` opens the music panel at launch (debug),
    /// and `-routineSpeed 20` to run routine delays that many times faster (testing).
    static func live() -> SceneCoordinator {
        let defaults = UserDefaults.standard
        do {
            let saved = RoomStateStore()
            let sceneName = defaults.string(forKey: "scene")
            // A launch argument wins; a saved choice that is no longer in the registry falls back to the active set.
            let repository = try defaults.string(forKey: "artSet").map { try SpriteAssetRepository(sceneName: sceneName, artSet: $0) }
                ?? (try? SpriteAssetRepository(sceneName: sceneName, artSet: saved.config.artSet))
                ?? SpriteAssetRepository(sceneName: sceneName)
            let room = try LoFiSKScene(repository: repository, showAnchors: defaults.bool(forKey: "debugAnchors"))
            let speed = defaults.double(forKey: "routineSpeed")
            let coordinator = SceneCoordinator(repository: repository, store: saved, scene: room,
                                           routineSpeed: speed > 0 ? speed : nil, music: SpotifyRemoteAdapter(),
                                           ambient: RainSoundPlayer.make())
            let store = coordinator.store
            switch defaults.string(forKey: "time") {
            case "auto": store.config.time = .automatic
            case DayPhase.day.rawValue: store.config.time = .manual(.day)
            case DayPhase.night.rawValue: store.config.time = .manual(.night)
            default: break
            }
            switch defaults.string(forKey: "weather") {
            case "auto": store.config.weather = .automatic
            case Sky.clear.rawValue: store.config.weather = .manual(.clear)
            case Sky.rain.rawValue: store.config.weather = .manual(.rain)
            default: break
            }
            switch defaults.string(forKey: "lamp") {
            case "on": store.config.lampOn = true
            case "off": store.config.lampOn = false
            default: break
            }
            if let name = defaults.string(forKey: "cityName"), defaults.object(forKey: "cityLat") != nil,
               defaults.object(forKey: "cityLon") != nil {
                store.config.city = City(name: name, latitude: defaults.double(forKey: "cityLat"), longitude: defaults.double(forKey: "cityLon"))
            }
            coordinator.start()
            for (category, argument) in [("Characters", "character"), ("Pets", "pet"), ("Scenery", "scenery")] {
                if let folder = defaults.string(forKey: argument) { coordinator.select(folder, in: category) }
            }
            coordinator.panelVisible = defaults.bool(forKey: "showPanel")
            if defaults.bool(forKey: "showMusic") { coordinator.computerTapped() }
            return coordinator
        } catch {
            // The room itself ships in the bundle; if it cannot load, the build is broken.
            fatalError(error.localizedDescription)
        }
    }
}
