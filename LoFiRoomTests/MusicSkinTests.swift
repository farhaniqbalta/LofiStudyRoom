import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class MusicSkinTests: XCTestCase {
    private var defaults: UserDefaults!
    private let playing = NowPlaying(title: "Song", artist: "Band", isPaused: false, imageID: nil)
    private var paused: NowPlaying { var t = playing; t.isPaused = true; return t }

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "MusicSkinTests")
        defaults.removePersistentDomain(forName: "MusicSkinTests")
    }

    private func nodeCount(_ node: SKNode) -> Int { 1 + node.children.map(nodeCount).reduce(0, +) }

    private func state(_ connection: MusicConnection, _ track: NowPlaying? = nil) -> MusicState {
        MusicState(connection: connection, track: track)
    }

    func testBundledSetAHasAValidMusicSkin() throws {
        let scene = try SpriteAssetRepository().scene
        let skin = try XCTUnwrap(scene.music)
        XCTAssertTrue(scene.problems().isEmpty, "\(scene.problems())")
        XCTAssertNotNil(skin.notes)
        for name in MusicSkin.requiredSlots {
            let slot = try XCTUnwrap(skin.slots[name], name)
            let w = try XCTUnwrap(slot.w), h = try XCTUnwrap(slot.h)
            XCTAssertTrue(slot.x >= skin.frame.x && slot.y >= skin.frame.y
                          && slot.x + w <= skin.frame.x + (skin.frame.w ?? 0) && slot.y + h <= skin.frame.y + (skin.frame.h ?? 0), name)
        }
        XCTAssertEqual(Set(MusicSkin.requiredIcons).subtracting(skin.icons.names), [])
    }

    func testSkinProblemsAreReported() throws {
        var scene = try SpriteAssetRepository().scene
        var skin = try XCTUnwrap(scene.music)
        skin.slots["title"] = nil
        skin.slots["artist"]?.w = nil
        skin.slots["next"]?.x = skin.frame.x + (skin.frame.w ?? 0)
        skin.icons.names.removeAll { $0 == "pause" }
        skin.notes?.anchor = "nowhere"
        scene.music = skin
        XCTAssertEqual(scene.problems(), [
            "music is missing icon 'pause'",
            "music is missing slot 'title'",
            "music notes use unknown anchor 'nowhere'",
            "music slot 'artist' needs a width and height",
            "music slot 'next' is outside the music frame",
        ])
    }

    func testBadSkinGeometryIsReported() throws {
        var scene = try SpriteAssetRepository().scene
        scene.music?.icons.frame.w = 0
        scene.music?.notes?.frame.w = 0
        scene.music?.notes?.fps = 0
        XCTAssertEqual(scene.problems(), [
            "music icons frame needs a positive width and height",
            "music notes frame needs a positive width and height",
            "music notes need a positive fps",
        ])
    }

    func testTransportNeedsAConnectedTrack() throws {
        let scene = try LoFiSKScene(repository: try SpriteAssetRepository(artSet: "A"), showAnchors: false)
        scene.applyMusic(panelVisible: true, state: state(.connected, nil), reduceMotion: false)
        XCTAssertFalse(scene.musicTransportIsShown)
        scene.applyMusic(panelVisible: true, state: state(.connected, playing), reduceMotion: false)
        XCTAssertTrue(scene.musicTransportIsShown)
    }

    func testCoordinatorLoadsCoverThroughTheRemote() async throws {
        let repository = try SpriteAssetRepository(artSet: "A")
        let remote = FakeMusicRemote()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in }
        remote.artworkImage = image
        func make(_ music: MusicRemote?) throws -> SceneCoordinator {
            SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults),
                             scene: try LoFiSKScene(repository: repository, showAnchors: false), music: music)
        }
        let loaded = await (try make(remote)).loadArtwork(for: playing, size: CGSize(width: 8, height: 8))
        XCTAssertTrue(loaded === image)
        let none = await (try make(nil)).loadArtwork(for: playing, size: CGSize(width: 8, height: 8))
        XCTAssertNil(none)
    }

    func testSceneWithoutSkinFallsBack() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        _ = try FixtureScene.make(in: root)
        defer { try? FileManager.default.removeItem(at: root) }
        for repository in [try SpriteAssetRepository(root: root)] {   // every bundled set has a skin; the fixture has none
            let scene = try LoFiSKScene(repository: repository, showAnchors: false)
            XCTAssertFalse(scene.hasMusicSkin)
            let count = nodeCount(scene)
            scene.applyMusic(panelVisible: true, state: state(.connected, playing), reduceMotion: false)
            XCTAssertEqual(nodeCount(scene), count)
            XCTAssertNil(scene.viewRect(forMusicSlot: "title"))
            let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene)
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
            view.presentScene(scene)
            XCTAssertTrue(coordinator.musicSlotFrames.isEmpty)
            XCTAssertFalse(coordinator.hasMusicSkin)
        }
    }

    func testApplyMusicShowsAndHidesWithoutAddingNodes() throws {
        let scene = try LoFiSKScene(repository: try SpriteAssetRepository(), showAnchors: false)
        XCTAssertTrue(scene.hasMusicSkin)
        let count = nodeCount(scene)
        let steps: [(Bool, MusicState)] = [
            (false, state(.neverConnected)), (true, state(.neverConnected)), (true, state(.connected, playing)),
            (true, state(.connected, paused)), (false, state(.connected, playing)), (false, state(.dropped, playing)),
        ]
        for (visible, music) in steps {
            scene.applyMusic(panelVisible: visible, state: music, reduceMotion: false)
            scene.applyMusic(panelVisible: visible, state: music, reduceMotion: false)
            let connected = music.connection == .connected
            let isPlaying = connected && music.track?.isPaused == false
            XCTAssertEqual(scene.musicPanelIsShown, visible)
            XCTAssertEqual(scene.musicTransportIsShown, visible && connected)
            XCTAssertEqual(scene.musicToggleShowsPause, isPlaying)
            XCTAssertEqual(scene.musicNotesAreShown, isPlaying)
            XCTAssertEqual(scene.musicNotesAreAnimating, isPlaying)
            XCTAssertEqual(nodeCount(scene), count)
        }
    }

    func testReduceMotionStopsTheNotesAnimation() throws {
        let scene = try LoFiSKScene(repository: try SpriteAssetRepository(), showAnchors: false)
        scene.applyMusic(panelVisible: true, state: state(.connected, playing), reduceMotion: true)
        XCTAssertTrue(scene.musicNotesAreShown)
        XCTAssertFalse(scene.musicNotesAreAnimating)
        scene.applyMusic(panelVisible: true, state: state(.connected, playing), reduceMotion: false)
        XCTAssertTrue(scene.musicNotesAreAnimating)
    }

    func testCoordinatorDrivesTheSkin() throws {
        let remote = FakeMusicRemote()
        remote.hasToken = true
        let repository = try SpriteAssetRepository()
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene, music: remote)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
        view.presentScene(scene)
        XCTAssertEqual(Set(coordinator.musicSlotFrames.keys), Set(MusicSkin.requiredSlots))
        XCTAssertFalse(scene.musicPanelIsShown)
        coordinator.tapped(hotspot: "computer")
        XCTAssertTrue(scene.musicPanelIsShown)
        remote.send(.connected)
        remote.send(.playing(playing))
        XCTAssertTrue(scene.musicNotesAreShown)
        XCTAssertTrue(scene.musicToggleShowsPause)
        remote.send(.playing(paused))
        XCTAssertFalse(scene.musicNotesAreShown)
        XCTAssertFalse(scene.musicToggleShowsPause)
        coordinator.tapped(hotspot: "computer")
        XCTAssertFalse(scene.musicPanelIsShown)
    }

    func testMusicSlotTapFramesAreAtLeast44Points() throws {
        let repository = try SpriteAssetRepository()
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
        view.presentScene(scene)
        for name in ["previous", "toggle", "next", "close", "action"] {
            let rect = try XCTUnwrap(scene.viewRect(forMusicSlot: name), name)
            let frame = SceneCoordinator.tapFrame(rect)
            XCTAssertGreaterThanOrEqual(frame.width, 44, name)
            XCTAssertGreaterThanOrEqual(frame.height, 44, name)
        }
    }
}
