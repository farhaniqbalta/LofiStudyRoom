import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class ArtIndependenceTests: XCTestCase {
    private var root: URL!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        _ = try FixtureScene.make(in: root)
        defaults = UserDefaults(suiteName: "ArtIndependenceTests")
        defaults.removePersistentDomain(forName: "ArtIndependenceTests")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func fixtureCoordinator() throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return coordinator
    }

    func testFixtureSceneLoadsAndRuns() throws {
        let coordinator = try fixtureCoordinator()
        XCTAssertEqual(coordinator.repository.scene.id, "fixtureroom", "the only scene folder is picked by default")
        XCTAssertEqual(coordinator.scene.size, CGSize(width: 320, height: 240))
        XCTAssertEqual(coordinator.scene.character.currentAnimation, "type")
        XCTAssertEqual(coordinator.scene.pet.currentAnimation, "nap")
        XCTAssertEqual(coordinator.scene.scenery.currentAnimation, "still")
        XCTAssertEqual(coordinator.scene.clock.text.count, 5)
        XCTAssertEqual(coordinator.store.config.character, "Typist", "the bundled default name falls back to the fixture pack")
    }

    func testPackListsAreFilteredByPerspective() throws {
        let bundled = Bundle.main.resourceURL!.appendingPathComponent("Assets/Characters/Boy01")
        try FileManager.default.copyItem(at: bundled, to: root.appendingPathComponent("Characters/Boy01"))
        let repository = try SpriteAssetRepository(root: root)
        XCTAssertEqual(repository.folders(in: "Characters"), ["Typist"])
        XCTAssertEqual(repository.folders(in: "Clocks"), ["Mini"])
    }

    func testSceneIsChosenByName() throws {
        let fixtureFolder = root.appendingPathComponent("Scenes/\(FixtureScene.name)")
        try FileManager.default.copyItem(at: fixtureFolder, to: root.appendingPathComponent("Scenes/AAA_Other"))
        XCTAssertEqual(try SpriteAssetRepository(root: root, sceneName: FixtureScene.name).scene.id, "fixtureroom")
        XCTAssertThrowsError(try SpriteAssetRepository(root: root, sceneName: "Missing")) {
            XCTAssertEqual($0.localizedDescription, "Scenes/Missing: manifest.json is missing")
        }
    }

    func testBrokenArtSetsFileThrowsAndMissingFileLoads() throws {
        XCTAssertEqual(try SpriteAssetRepository(root: root).scene.id.isEmpty, false)
        try Data("{\"active\": \"A\", \"sets\": {".utf8).write(to: root.appendingPathComponent("art-sets.json"))
        XCTAssertThrowsError(try SpriteAssetRepository(root: root)) {
            XCTAssertTrue($0.localizedDescription.hasPrefix("art-sets.json is invalid"), $0.localizedDescription)
        }
    }

    func testArtSetsAreChosenByTheRegistry() throws {
        // The bundle holds two art sets; B's scene folder sorts first, so only the registry keeps A the default.
        XCTAssertEqual(try SpriteAssetRepository().scene.id, "studyroom01")
        XCTAssertEqual(try SpriteAssetRepository(artSet: "A").scene.id, "studyroom01")
        let b = try SpriteAssetRepository(artSet: "B")
        XCTAssertEqual(b.scene.id, "cyberdesk01")
        XCTAssertEqual(b.folders(in: "Characters"), ["CyberBoy"])
        XCTAssertEqual(b.folders(in: "Pets"), ["CyberCat"])
        XCTAssertEqual(b.folders(in: "Scenery"), ["CyberCity01"])
        XCTAssertEqual(b.folders(in: "Clocks"), ["CyberClock"])
        XCTAssertThrowsError(try SpriteAssetRepository(artSet: "Z")) {
            XCTAssertEqual($0.localizedDescription, "art-sets.json has no art set 'Z'")
        }
        // An explicit scene name still wins over the registry.
        XCTAssertEqual(try SpriteAssetRepository(sceneName: "CyberDesk01", artSet: "A").scene.id, "cyberdesk01")
    }

    func testArtSetBRunsTheEngineUnchanged() throws {
        let repository = try SpriteAssetRepository(artSet: "B")
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        XCTAssertEqual(scene.character.pack?.manifest.id, "cyberboy")
        XCTAssertEqual(scene.pet.pack?.manifest.id, "cybercat")
        XCTAssertEqual(scene.clock.text.count, 5)
        XCTAssertEqual(coordinator.config.character, "CyberBoy", "the saved Type A name falls back to Type B's character")
    }

    func testRestingAnimationComesFromTheManifest() throws {
        let repository = try SpriteAssetRepository()
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let boy = try repository.load("Characters", "Boy01")
        scene.show(boy)
        XCTAssertEqual(scene.character.currentAnimation, boy.manifest.fallbackAnimation)
    }

    func testManifestDeclaresRoutinesAndTapReactions() throws {
        let typist = try SpriteAssetRepository(root: root).load("Characters", "Typist").manifest
        XCTAssertEqual(typist.animations?["sip"]?.routine, RoutineSpec(weight: 1, cooldown: 10))
        XCTAssertNil(typist.animations?["type"]?.routine)
        let nappy = try SpriteAssetRepository(root: root).load("Pets", "Nappy").manifest
        XCTAssertEqual(nappy.animations?["purr"]?.onTap, true)
    }
}
