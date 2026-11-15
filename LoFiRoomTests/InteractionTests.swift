import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class InteractionTests: XCTestCase {
    private var defaults: UserDefaults!
    private var root: URL!
    private var timers: FakeTimers!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "InteractionTests")
        defaults.removePersistentDomain(forName: "InteractionTests")
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        _ = try FixtureScene.make(in: root)
        timers = FakeTimers()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func bundled() throws -> SceneCoordinator { try make(SpriteAssetRepository()) }
    private func fixture() throws -> SceneCoordinator { try make(SpriteAssetRepository(root: root)) }

    private func make(_ repository: SpriteAssetRepository) throws -> SceneCoordinator {
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                           timers: fake, clock: { fake.now })
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return coordinator
    }

    func testTapFramePadsSmallRectsAndKeepsLargeOnes() {
        func frame(_ w: CGFloat, _ h: CGFloat) -> CGRect {
            SceneCoordinator.tapFrame(CGRect(x: 100 - w / 2, y: 100 - h / 2, width: w, height: h))
        }
        XCTAssertEqual(frame(10, 20), CGRect(x: 78, y: 78, width: 44, height: 44))
        XCTAssertEqual(frame(60, 30), CGRect(x: 70, y: 78, width: 60, height: 44))
        XCTAssertEqual(frame(100, 80), CGRect(x: 50, y: 60, width: 100, height: 80))
    }

    func testLampTapTogglesSavesAndApplies() throws {
        let coordinator = try bundled()
        coordinator.tapped(hotspot: "lamp")
        XCTAssertFalse(coordinator.store.config.lampOn)
        XCTAssertFalse(RoomStateStore(defaults: defaults).config.lampOn)
        XCTAssertEqual(coordinator.scene.applied?.lampOn, false)
        coordinator.tapped(hotspot: "lamp")
        XCTAssertTrue(coordinator.store.config.lampOn)
        XCTAssertEqual(coordinator.scene.applied?.lampOn, true)
    }

    func testWindowTapCyclesSceneryAndWraps() throws {
        let coordinator = try bundled()
        let folders = coordinator.repository.folders(in: "Scenery")
        XCTAssertGreaterThanOrEqual(folders.count, 2)
        XCTAssertEqual(coordinator.store.config.scenery, folders[0])
        coordinator.tapped(hotspot: "window")
        XCTAssertEqual(coordinator.store.config.scenery, folders[1])
        XCTAssertEqual(coordinator.scene.scenery.pack?.manifest.id, try coordinator.repository.load("Scenery", folders[1]).manifest.id)
        for _ in 1..<folders.count { coordinator.tapped(hotspot: "window") }
        XCTAssertEqual(coordinator.store.config.scenery, folders[0])
    }

    func testWindowTapWithOneSceneryDoesNothing() throws {
        let coordinator = try fixture()
        let before = coordinator.store.config
        let pack = coordinator.scene.scenery.pack?.manifest.id
        coordinator.tapped(hotspot: "window")
        XCTAssertEqual(coordinator.store.config, before)
        XCTAssertEqual(coordinator.scene.scenery.pack?.manifest.id, pack)
    }

    func testComputerTapTogglesMusicPanel() throws {
        let coordinator = try bundled()
        XCTAssertFalse(coordinator.musicPanelVisible)
        coordinator.tapped(hotspot: "computer")
        XCTAssertTrue(coordinator.musicPanelVisible)
        coordinator.tapped(hotspot: "computer")
        XCTAssertFalse(coordinator.musicPanelVisible)
    }

    func testPetTapPlaysTheManifestTapReaction() throws {
        let coordinator = try bundled()
        let manifest = try coordinator.repository.load("Pets", coordinator.store.config.pet).manifest
        let reaction = try XCTUnwrap(manifest.animations?.first { $0.value.onTap == true }?.key)
        coordinator.tapped(hotspot: "pet")
        XCTAssertEqual(coordinator.scene.pet.currentAnimation, reaction)
        timers.advance(by: 60)
        XCTAssertEqual(coordinator.scene.pet.currentAnimation, manifest.fallbackAnimation)
    }

    func testUnknownHotspotIsIgnored() throws {
        let coordinator = try bundled()
        let before = coordinator.store.config
        coordinator.tapped(hotspot: "ceiling")
        XCTAssertEqual(coordinator.store.config, before)
        XCTAssertFalse(coordinator.musicPanelVisible)
    }

    func testHotspotFramesAreAtLeast44PointsAndPetIsInsideWindow() throws {
        func present(_ coordinator: SceneCoordinator) {
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
            view.presentScene(coordinator.scene)
        }
        let coordinator = try bundled()
        present(coordinator)
        let frames = coordinator.hotspotFrames
        XCTAssertEqual(Set(frames.keys), ["pet", "lamp", "window", "computer"])
        let bounds = CGRect(x: 0, y: 0, width: 1194, height: 834)
        for (name, frame) in frames {
            XCTAssertGreaterThanOrEqual(frame.width, 44, name)
            XCTAssertGreaterThanOrEqual(frame.height, 44, name)
            XCTAssertTrue(bounds.contains(frame), "\(name) \(frame)")
        }
        let pet = try XCTUnwrap(frames["pet"]), window = try XCTUnwrap(frames["window"])
        XCTAssertTrue(window.contains(CGPoint(x: pet.midX, y: pet.midY)))

        let plain = try fixture()
        present(plain)
        XCTAssertTrue(plain.hotspotFrames.isEmpty)
    }
}
