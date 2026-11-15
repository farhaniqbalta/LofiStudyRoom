import Foundation
import QuartzCore
import os

/// Turns application state and events into scene updates. The scene never reads state or services itself.
@MainActor
final class SceneCoordinator {
    let repository: SpriteAssetRepository
    let store: RoomStateStore
    let scene: LoFiSKScene
    private var clockDriver: ClockDriver?
    private let log = Logger(subsystem: "com.lofiroom.app", category: "packs")

    static let categories: [(name: String, key: WritableKeyPath<RoomConfig, String>)] = [
        ("Scenery", \.scenery), ("Characters", \.character), ("Pets", \.pet), ("Clocks", \.clock),
    ]

    private let characterDirector: ActorDirector
    private let petDirector: ActorDirector

    init(repository: SpriteAssetRepository, store: RoomStateStore, scene: LoFiSKScene,
         timers: TimerScheduling = LiveTimers(), clock: @escaping () -> TimeInterval = CACurrentMediaTime,
         routineSpeed: Double = 1) {
        self.repository = repository
        self.store = store
        self.scene = scene
        characterDirector = ActorDirector(node: scene.character, delay: RoutineConfig.characterDelay, timers: timers,
                                          clock: clock, speed: routineSpeed) { [scene] in scene.show($0) }
        petDirector = ActorDirector(node: scene.pet, delay: RoutineConfig.petDelay, timers: timers,
                                    clock: clock, speed: routineSpeed) { [scene] in scene.show($0) }
    }

    func setActive(_ active: Bool) {
        characterDirector.setActive(active)
        petDirector.setActive(active)
    }

    func petTapped() { petDirector.tapped() }

    /// Shows the saved configuration and starts the clock.
    func start(clockDriver: ClockDriver? = nil) {
        for (category, key) in Self.categories {
            // A saved pack that no longer exists or fails validation falls back to the first pack that loads.
            let candidates = [store.config[keyPath: key]] + repository.folders(in: category)
            if !candidates.contains(where: { select($0, in: category) }) {
                log.error("No usable pack in \(category, privacy: .public)")
            }
        }
        let driver = clockDriver ?? ClockDriver { [scene] in scene.clock.show($0) }
        driver.start()
        self.clockDriver = driver
        setActive(true)
    }

    /// Swaps one pack and saves the choice. Returns false, leaving the scene as it was, if the pack is unusable.
    @discardableResult
    func select(_ folder: String, in category: String) -> Bool {
        guard let key = Self.categories.first(where: { $0.name == category })?.key else { return false }
        do {
            let pack = try repository.load(category, folder)
            switch category {
            case "Characters": characterDirector.show(pack)
            case "Pets": petDirector.show(pack)
            default: scene.show(pack)
            }
            store.config[keyPath: key] = folder
            return true
        } catch {
            log.error("\(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
