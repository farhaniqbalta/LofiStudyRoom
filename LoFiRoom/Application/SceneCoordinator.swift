import Foundation
import QuartzCore
import UIKit
import os

/// Turns application state and events into scene updates. The scene never reads state or services itself.
@MainActor
final class SceneCoordinator: ObservableObject {
    let repository: SpriteAssetRepository
    let store: RoomStateStore
    let scene: LoFiSKScene
    /// Tap frames in view points, already padded.
    @Published private(set) var hotspotFrames: [String: CGRect] = [:]
    @Published var musicPanelVisible = false
    private var clockDriver: ClockDriver?
    private let now: () -> Date
    private let log = Logger(subsystem: "com.lofiroom.app", category: "packs")

    static let categories: [(name: String, key: WritableKeyPath<RoomConfig, String>)] = [
        ("Scenery", \.scenery), ("Characters", \.character), ("Pets", \.pet), ("Clocks", \.clock),
    ]

    private let characterDirector: ActorDirector
    private let petDirector: ActorDirector

    init(repository: SpriteAssetRepository, store: RoomStateStore, scene: LoFiSKScene,
         timers: TimerScheduling = LiveTimers(), clock: @escaping () -> TimeInterval = CACurrentMediaTime,
         routineSpeed: Double = 1, now: @escaping () -> Date = Date.init) {
        self.now = now
        self.repository = repository
        self.store = store
        self.scene = scene
        characterDirector = ActorDirector(node: scene.character, delay: RoutineConfig.characterDelay, timers: timers,
                                          clock: clock, speed: routineSpeed) { [scene] in scene.show($0) }
        petDirector = ActorDirector(node: scene.pet, delay: RoutineConfig.petDelay, timers: timers,
                                    clock: clock, speed: routineSpeed) { [scene] in scene.show($0) }
        scene.onLayout = { [weak self, weak scene] in
            guard let self, let scene else { return }
            var frames: [String: CGRect] = [:]
            for name in scene.manifest.hotspots?.keys ?? [:].keys {
                if let rect = scene.viewRect(forHotspot: name) { frames[name] = Self.tapFrame(rect) }
            }
            if frames != hotspotFrames { hotspotFrames = frames }
        }
    }

    func setActive(_ active: Bool) {
        characterDirector.setActive(active)
        petDirector.setActive(active)
    }

    func petTapped() { petDirector.tapped() }

    /// Grows a rect around its centre so each side is at least `minimum`; never shrinks.
    static func tapFrame(_ rect: CGRect, minimum: CGFloat = 44) -> CGRect {
        let w = max(rect.width, minimum), h = max(rect.height, minimum)
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }

    /// Hotspot roles are engine vocabulary; anything else is ignored.
    func tapped(hotspot name: String) {
        switch name {
        case "pet": petTapped()
        case "lamp": lampTapped()
        case "window": windowTapped()
        case "computer": computerTapped()
        default: break
        }
    }

    func lampTapped() {
        store.config.lampOn.toggle()
        applyEnvironment()
    }

    func windowTapped() {
        let folders = repository.folders(in: "Scenery")
        guard folders.count > 1 else { return }
        let next = (folders.firstIndex(of: store.config.scenery).map { $0 + 1 } ?? 0) % folders.count
        select(folders[next], in: "Scenery")
    }

    func computerTapped() { musicPanelVisible.toggle() }

    /// Shows the saved configuration and starts the clock.
    func start(clockDriver: ClockDriver? = nil) {
        for (category, key) in Self.categories {
            // A saved pack that no longer exists or fails validation falls back to the first pack that loads.
            let candidates = [store.config[keyPath: key]] + repository.folders(in: category)
            if !candidates.contains(where: { select($0, in: category) }) {
                log.error("No usable pack in \(category, privacy: .public)")
            }
        }
        applyEnvironment()
        let driver = clockDriver ?? ClockDriver { [weak self] in
            self?.scene.clock.show($0)
            self?.applyEnvironment()
        }
        driver.start()
        self.clockDriver = driver
        setActive(true)
    }

    func applyEnvironment() {
        // snapshot is nil until weather data arrives in a later task.
        scene.apply(EnvironmentRules.resolve(config: store.config, snapshot: nil, now: now(), calendar: .autoupdatingCurrent),
                    reduceMotion: UIAccessibility.isReduceMotionEnabled)
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
