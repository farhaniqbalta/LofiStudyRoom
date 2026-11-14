import Foundation
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

    init(repository: SpriteAssetRepository, store: RoomStateStore, scene: LoFiSKScene) {
        self.repository = repository
        self.store = store
        self.scene = scene
    }

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
    }

    /// Swaps one pack and saves the choice. Returns false, leaving the scene as it was, if the pack is unusable.
    @discardableResult
    func select(_ folder: String, in category: String) -> Bool {
        guard let key = Self.categories.first(where: { $0.name == category })?.key else { return false }
        do {
            scene.show(try repository.load(category, folder))
            store.config[keyPath: key] = folder
            return true
        } catch {
            log.error("\(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
