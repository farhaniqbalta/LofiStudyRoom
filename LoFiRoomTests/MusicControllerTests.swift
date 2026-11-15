import XCTest
@testable import LoFiRoom

@MainActor
final class MusicControllerTests: XCTestCase {
    private var remote: FakeMusicRemote!
    private var changes = 0
    private let playing = NowPlaying(title: "Song", artist: "Band", isPaused: false, imageID: nil)
    private var paused: NowPlaying { var t = playing; t.isPaused = true; return t }

    override func setUp() async throws { remote = FakeMusicRemote(); changes = 0 }

    private func make(token: Bool = false) -> MusicController {
        remote.hasToken = token
        return MusicController(remote: remote) { [unowned self] in changes += 1 }
    }

    private func connected(_ track: NowPlaying? = nil) -> MusicController {
        let c = make(token: true)
        c.cardOpened()
        remote.send(.connected)
        remote.send(.playing(track ?? playing))
        return c
    }

    func testInitialStates() {
        remote.isConfigured = false
        XCTAssertEqual(make().state.connection, .notConfigured)
        remote.isConfigured = true; remote.isInstalled = false
        XCTAssertEqual(make().state.connection, .notInstalled)
        remote.isInstalled = true
        XCTAssertEqual(make().state.connection, .neverConnected)
        XCTAssertEqual(make(token: true).state.connection, .dropped)
        XCTAssertNil(make(token: true).state.track)
    }

    func testOpeningTheCardNeverSwitchesApps() {
        for setup in [{ self.remote.isConfigured = false }, { self.remote.isInstalled = false }, {}, { self.remote.hasToken = true }] {
            remote = FakeMusicRemote(); remote.hasToken = false
            setup()
            let c = MusicController(remote: remote) {}
            c.cardOpened(); c.becameActive()
            XCTAssertEqual(remote.count("authorizeAndPlay"), 0)
        }
        remote = FakeMusicRemote()
        let c = make(token: true)
        c.cardOpened()
        XCTAssertEqual(remote.count("connect"), 1)
        XCTAssertEqual(c.state.connection, .connecting)
    }

    func testConnectFlow() {
        let c = make()
        c.primaryAction()
        XCTAssertEqual(remote.count("authorizeAndPlay"), 1)
        XCTAssertEqual(c.state.connection, .connecting)
        remote.send(.connected)
        XCTAssertEqual(c.state.connection, .connected)
        remote.send(.playing(playing))
        XCTAssertEqual(c.state.track, playing)
    }

    func testPlayPauseAndSkipOnlyWhileConnected() {
        let c = connected()
        c.togglePlayPause()
        remote.send(.playing(paused))
        c.togglePlayPause(); c.next(); c.previous()
        XCTAssertEqual(remote.calls.suffix(4), ["pause", "resume", "next", "previous"])
        remote.send(.disconnected)
        let before = remote.calls.count
        c.togglePlayPause(); c.next(); c.previous()
        XCTAssertEqual(remote.calls.count, before)
    }

    func testDropKeepsTheLastTrackAndOffersResume() {
        let c = connected()
        remote.send(.disconnected)
        XCTAssertEqual(c.state, MusicState(connection: .dropped, track: playing))
        c.primaryAction()
        XCTAssertEqual(remote.count("authorizeAndPlay"), 1)
    }

    func testSilentReconnectFailureFallsBackToDropped() {
        let c = make(token: true)
        c.cardOpened()
        remote.send(.connectFailed(authorization: false))
        XCTAssertEqual(c.state.connection, .dropped)
        XCTAssertEqual(remote.count("forgetToken"), 0)
    }

    func testInvalidTokenIsForgottenAndAsksToReconnect() {
        let c = connected()
        remote.send(.connectFailed(authorization: true))
        XCTAssertEqual(remote.count("forgetToken"), 1)
        XCTAssertEqual(c.state, MusicState(connection: .needsReconnect, track: nil))
        c.primaryAction()
        XCTAssertEqual(remote.count("authorizeAndPlay"), 1)
    }

    func testDeniedAuthorization() {
        let c = make()
        c.primaryAction()
        remote.send(.authorizationDenied)
        XCTAssertEqual(c.state.connection, .needsReconnect)
    }

    func testLeavingTheForegroundDisconnectsAndReturningReconnectsOnce() {
        let c = connected()
        let connects = remote.count("connect")
        c.resignedActive()
        XCTAssertEqual(remote.count("disconnect"), 1)
        XCTAssertEqual(c.state.connection, .dropped)
        c.becameActive()
        XCTAssertEqual(remote.count("connect"), connects + 1)

        remote = FakeMusicRemote()
        let idle = make(token: true)
        idle.resignedActive()
        idle.becameActive()
        XCTAssertEqual(remote.calls, ["disconnect"])
    }

    func testStaleConnectingIsResolvedOnReturn() {
        let c = make()
        c.primaryAction()
        c.becameActive()
        XCTAssertEqual(c.state.connection, .neverConnected)
    }

    func testInstallingSpotifyLaterIsNoticed() {
        remote.isInstalled = false
        let c = make()
        XCTAssertEqual(c.state.connection, .notInstalled)
        remote.isInstalled = true
        c.cardOpened()
        XCTAssertEqual(c.state.connection, .neverConnected)
    }

    func testOnChangeFiresOnlyOnChanges() {
        let c = make()
        c.primaryAction()
        XCTAssertEqual(changes, 1)
        remote.send(.connected)
        XCTAssertEqual(changes, 2)
        remote.send(.connected)
        c.togglePlayPause()
        c.cardClosed()
        XCTAssertEqual(changes, 2)
    }

    // MARK: coordinator

    private func coordinator(music: MusicRemote?) throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository()
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let defaults = UserDefaults(suiteName: "MusicControllerTests")!
        defaults.removePersistentDomain(forName: "MusicControllerTests")
        let fake = FakeTimers()
        return SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                timers: fake, clock: { fake.now }, music: music)
    }

    func testComputerTapOpensCardAndStartsOneSilentConnect() throws {
        remote.hasToken = true
        let c = try coordinator(music: remote)
        c.tapped(hotspot: "computer")
        XCTAssertTrue(c.musicPanelVisible)
        XCTAssertEqual(c.musicState.connection, .connecting)
        XCTAssertEqual(remote.count("connect"), 1)
        XCTAssertEqual(remote.count("authorizeAndPlay"), 0)
    }

    func testCoordinatorWithoutMusicRemoteShowsNotConfigured() throws {
        let c = try coordinator(music: nil)
        c.tapped(hotspot: "computer")
        XCTAssertEqual(c.musicState, MusicState(connection: .notConfigured, track: nil))
    }

    func testCoordinatorSetActiveForwardsToMusic() throws {
        remote.hasToken = true
        let c = try coordinator(music: remote)
        c.tapped(hotspot: "computer")
        c.setActive(true)
        c.setActive(false)
        XCTAssertEqual(remote.count("disconnect"), 1)
        let connects = remote.count("connect")
        c.setActive(true)
        XCTAssertEqual(remote.count("connect"), connects + 1)
    }
}
