import Foundation

extension SceneCoordinator {
    /// Builds the running room from the bundle and launch arguments.
    /// Launch arguments: `-fps 12`, `-paused YES`, `-debugAnchors YES` (anchor overlay + FPS counter), and
    /// `-scene <folder>` (default: first scene folder), `-character Girl01`, `-pet BlackCat`, `-scenery NeonCity02` to choose packs (the choice is saved),
    /// `-time auto|day|night`, `-weather auto|clear|rain`, `-lamp on|off` (saved too; unknown values are ignored),
    /// and `-routineSpeed 20` to run routine delays that many times faster (testing).
    static func live() -> SceneCoordinator {
        let defaults = UserDefaults.standard
        do {
            let repository = try SpriteAssetRepository(sceneName: defaults.string(forKey: "scene"))
            let scene = try LoFiSKScene(repository: repository, showAnchors: defaults.bool(forKey: "debugAnchors"))
            let speed = defaults.double(forKey: "routineSpeed")
            let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(), scene: scene,
                                           routineSpeed: speed > 0 ? speed : 1)
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
            coordinator.start()
            for (category, argument) in [("Characters", "character"), ("Pets", "pet"), ("Scenery", "scenery")] {
                if let folder = defaults.string(forKey: argument) { coordinator.select(folder, in: category) }
            }
            return coordinator
        } catch {
            // The room itself ships in the bundle; if it cannot load, the build is broken.
            fatalError(error.localizedDescription)
        }
    }
}
