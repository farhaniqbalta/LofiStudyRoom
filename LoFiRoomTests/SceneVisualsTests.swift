import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class SceneVisualsTests: XCTestCase {
    private var repository: SpriteAssetRepository!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        repository = try SpriteAssetRepository()
        defaults = UserDefaults(suiteName: "SceneVisualsTests")
        defaults.removePersistentDomain(forName: "SceneVisualsTests")
    }

    private func nodeCount(_ node: SKNode) -> Int { 1 + node.children.map(nodeCount).reduce(0, +) }

    private func coordinator(_ config: (inout RoomConfig) -> Void = { _ in }, now: @escaping () -> Date = Date.init) throws -> SceneCoordinator {
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let store = RoomStateStore(defaults: defaults)
        config(&store.config)
        let coordinator = SceneCoordinator(repository: repository, store: store, scene: scene, now: now)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return coordinator
    }

    private func localDate(hour: Int) -> Date {
        Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: hour))!
    }

    private let nightRain = ResolvedScene(phase: .night, sky: .rain, lampOn: false)
    private let dayClear = ResolvedScene(phase: .day, sky: .clear, lampOn: true)

    func testBundledPacksDeclareRoutinesAndTapReactions() throws {
        for folder in ["Boy01", "Girl01"] {
            let animations = try repository.load("Characters", folder).manifest.animations
            for (name, weight, cooldown) in [("drink", 3.0, 300.0), ("stretch", 1, 900), ("rest", 2, 600)] {
                XCTAssertEqual(animations?[name]?.routine, RoutineSpec(weight: weight, cooldown: cooldown), "\(folder) \(name)")
                XCTAssertEqual(animations?[name]?.loop, false, "\(folder) \(name)")
            }
        }
        for folder in ["OrangeCat", "BlackCat"] {
            let animations = try repository.load("Pets", folder).manifest.animations
            XCTAssertEqual(animations?["idle"]?.routine, RoutineSpec(weight: 1, cooldown: 120), folder)
            XCTAssertEqual(animations?["react"]?.onTap, true, folder)
        }
    }

    func testBundledSceneDeclaresRoomsRainAndHotspots() {
        let scene = repository.scene
        XCTAssertEqual(Set(scene.rooms?.keys ?? [:].keys), ["night-on", "night-off", "day-on", "day-off"])
        XCTAssertEqual(scene.rain?.frame, PixelSize(w: 184, h: 128))
        XCTAssertEqual(Set(scene.hotspots?.keys ?? [:].keys), ["pet", "lamp", "window", "computer"])
        XCTAssertEqual(scene.problems(), [])
    }

    func testRoomImagePicksStateAndFallsBack() {
        var scene = repository.scene
        for (phase, lamp) in [(DayPhase.night, true), (.night, false), (.day, true), (.day, false)] {
            let state = ResolvedScene(phase: phase, sky: .clear, lampOn: lamp)
            let key = "\(phase.rawValue)-\(lamp ? "on" : "off")"
            XCTAssertEqual(scene.roomImage(for: state), scene.rooms?[key])
        }
        scene.rooms = nil
        XCTAssertEqual(scene.roomImage(for: dayClear), scene.room)
    }

    func testApplySwitchesStatesWithoutAddingNodes() throws {
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let before = nodeCount(scene)
        var nightTexture: SKTexture?, dayTexture: SKTexture?
        for _ in 0..<50 {
            scene.apply(nightRain, reduceMotion: false)
            nightTexture = scene.roomSprite.texture
            XCTAssertEqual(scene.rainFramesPerSecond, repository.scene.rain?.fps)
            scene.apply(dayClear, reduceMotion: false)
            dayTexture = scene.roomSprite.texture
            XCTAssertEqual(scene.rainFramesPerSecond, 0)
        }
        XCTAssertEqual(nodeCount(scene), before)
        XCTAssertNotEqual(nightTexture, dayTexture)
    }

    func testReduceMotionHalvesRainSpeed() throws {
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fps = try XCTUnwrap(repository.scene.rain?.fps)
        scene.apply(nightRain, reduceMotion: false)
        XCTAssertEqual(scene.rainFramesPerSecond, fps)
        scene.apply(nightRain, reduceMotion: true)
        XCTAssertEqual(scene.rainFramesPerSecond, fps / 2)
    }

    func testSceneryFollowsThePhase() throws {
        let coordinator = try coordinator()
        let scene = coordinator.scene
        scene.apply(dayClear, reduceMotion: false)
        XCTAssertEqual(scene.scenery.currentAnimation, "day")
        let other = coordinator.store.config.scenery == "NeonCity02" ? "NeonCity01" : "NeonCity02"
        XCTAssertTrue(coordinator.select(other, in: "Scenery"))
        XCTAssertEqual(scene.scenery.currentAnimation, "day")
        scene.apply(ResolvedScene(phase: .night, sky: .clear, lampOn: true), reduceMotion: false)
        XCTAssertEqual(scene.scenery.currentAnimation, "night")
    }

    func testCoordinatorAppliesSavedEnvironment() throws {
        let coordinator = try coordinator {
            $0.time = .manual(.night)
            $0.weather = .manual(.rain)
            $0.lampOn = false
        }
        XCTAssertEqual(coordinator.scene.applied, ResolvedScene(phase: .night, sky: .rain, lampOn: false))
    }

    func testAutomaticPhaseFollowsTheInjectedClock() throws {
        let noon = localDate(hour: 12), late = localDate(hour: 23)
        XCTAssertEqual(try coordinator(now: { noon }).scene.applied?.phase, .day)
        XCTAssertEqual(try coordinator(now: { late }).scene.applied?.phase, .night)
    }

    func testSceneProblemsForBadExtras() {
        var scene = repository.scene
        scene.rain?.anchor = "nowhere"
        scene.hotspots?["window"] = ScenePack.Anchor(x: 64, y: 148, w: nil, h: nil)
        scene.hotspots?["lamp"] = ScenePack.Anchor(x: 9999, y: 124, w: 42, h: 66)
        XCTAssertEqual(scene.problems(), [
            "hotspot 'lamp' is outside the safe area",
            "hotspot 'window' needs a width and height",
            "rain uses unknown anchor 'nowhere'",
        ])
    }

    func testFixtureWithoutExtrasApplies() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try FixtureScene.make(in: root)
        let fixture = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: fixture, showAnchors: false)
        let coordinator = SceneCoordinator(repository: fixture, store: RoomStateStore(defaults: defaults), scene: scene)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        let before = nodeCount(scene), texture = scene.roomSprite.texture
        scene.apply(ResolvedScene(phase: .day, sky: .rain, lampOn: false), reduceMotion: false)
        XCTAssertEqual(nodeCount(scene), before)
        XCTAssertEqual(scene.rainFramesPerSecond, 0)
        XCTAssertEqual(scene.scenery.currentAnimation, "still")
        XCTAssertEqual(scene.roomSprite.texture, texture)
    }
}
