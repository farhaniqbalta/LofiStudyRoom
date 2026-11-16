import XCTest
@testable import LoFiRoom

@MainActor
final class PolishAudioTests: XCTestCase {
    private let suite = "PolishAudioTests"
    private var defaults: UserDefaults!
    private var root: URL!
    private var timers: FakeTimers!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        _ = try FixtureScene.make(in: root)
        timers = FakeTimers()
    }

    override func tearDown() async throws { try? FileManager.default.removeItem(at: root) }

    private func coordinator(ambient: AmbientPlayer? = nil) throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let c = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                 timers: fake, clock: { fake.now },
                                 weather: FakeWeather(.success(WeatherSnapshot(sky: .clear, sunrise: nil, sunset: nil, fetched: Date()))),
                                 weatherCacheURL: root.appendingPathComponent("weather.json"), ambient: ambient)
        c.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return c
    }

    private func saved() -> RoomConfig { RoomStateStore(defaults: defaults).config }

    private func decode(_ json: String) throws -> RoomConfig { try JSONDecoder().decode(RoomConfig.self, from: Data(json.utf8)) }

    // MARK: Logo

    func testLogoMinimumWidth() {
        XCTAssertTrue(MusicSkinOverlay.logoMeetsMinimumWidth(slotWidthPoints: 35, displayScale: 2))
        XCTAssertFalse(MusicSkinOverlay.logoMeetsMinimumWidth(slotWidthPoints: 34, displayScale: 2))
        XCTAssertTrue(MusicSkinOverlay.logoMeetsMinimumWidth(slotWidthPoints: 24, displayScale: 3))
    }

    // MARK: Frequency

    func testRoutineFrequencyDecodesWithDefaultAndClamps() throws {
        XCTAssertEqual(try decode(#"{"character":"Boy01"}"#).routineFrequency, 1)
        XCTAssertEqual(try decode(#"{"character":"Boy01"}"#).character, "Boy01")
        XCTAssertEqual(try decode(#"{"routineFrequency":100}"#).routineFrequency, 20)
        XCTAssertEqual(try decode(#"{"routineFrequency":0}"#).routineFrequency, 0.5)
    }

    func testLogMappingEnds() {
        XCTAssertEqual(CustomizationSheet.frequency(atSlider: 0), 0.5, accuracy: 0.001)
        XCTAssertEqual(CustomizationSheet.frequency(atSlider: 1), 20, accuracy: 0.001)
        XCTAssertEqual(CustomizationSheet.frequency(atSlider: CustomizationSheet.slider(forFrequency: 1)), 1, accuracy: 0.001)
    }

    func testSetSpeedReschedulesOnce() throws {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let director = ActorDirector(node: scene.character, delay: RoutineConfig.characterDelay, timers: fake, clock: { fake.now }) { scene.show($0) }
        director.show(try repository.load("Characters", "Typist"))
        director.setActive(true)
        XCTAssertEqual(timers.pendingDelays.count, 1)
        director.setSpeed(20)
        XCTAssertEqual(timers.pendingDelays.count, 1)
        XCTAssertLessThanOrEqual(timers.pendingDelays[0], RoutineConfig.characterDelay.upperBound / 20)
        director.setSpeed(20)
        XCTAssertEqual(timers.pendingDelays.count, 1)
    }

    func testCoordinatorFrequencyIsSavedAndApplied() throws {
        let c = try coordinator()
        c.setRoutineFrequency(20)
        XCTAssertEqual(saved().routineFrequency, 20)
        XCTAssertEqual(timers.pendingDelays.count, 1)
        XCTAssertLessThanOrEqual(timers.pendingDelays[0], RoutineConfig.characterDelay.upperBound / 20)
        c.setRoutineFrequency(1000)
        XCTAssertEqual(c.config.routineFrequency, 20)
    }

    func testLoweringFrequencyAfterALongFastRunStillPlaysRoutines() throws {
        let c = try coordinator()
        c.setRoutineFrequency(20)
        timers.advance(by: 7200)   // two hours at 20x
        c.setRoutineFrequency(1)
        var seen = Set<String>()
        for _ in 0..<3000 {        // fifty minutes at 1x: delays are 90-240 s, so several routines must play
            timers.advance(by: 1)
            seen.insert(c.scene.character.currentAnimation ?? "")
        }
        XCTAssertFalse(seen.isDisjoint(with: ["sip", "lean"]), "routines stopped after lowering the frequency: \(seen)")
    }

    // MARK: Rain sound

    func testShouldPlayTable() {
        for mode in RainSoundMode.allCases {
            for sky in [Sky.clear, .rain] {
                XCTAssertFalse(AmbientSound.shouldPlay(mode: mode, sky: sky, active: false))
                let expected = mode == .always || (mode == .whenRaining && sky == .rain)
                XCTAssertEqual(AmbientSound.shouldPlay(mode: mode, sky: sky, active: true), expected, "\(mode) \(sky)")
            }
        }
    }

    func testUpdateFadesInAndOutWithOneTimer() {
        let player = FakeAmbientPlayer()
        let audio = AmbientAudio(player: player, timers: timers)
        audio.update(play: true, volume: 0.4)
        XCTAssertEqual(player.playCalls, 1)
        XCTAssertEqual(player.volume, 0)
        XCTAssertEqual(player.fades.count, 1)
        XCTAssertEqual(player.fades[0].volume, 0.4, accuracy: 0.001)
        XCTAssertEqual(player.fades[0].duration, 1.5)
        audio.update(play: true, volume: 0.4)
        XCTAssertEqual(player.fades.count, 1)
        XCTAssertEqual(player.playCalls, 1)
        audio.update(play: false, volume: 0.4)
        XCTAssertEqual(player.fades.last?.volume, 0)
        XCTAssertEqual(timers.pendingDelays, [1.5])
        audio.update(play: false, volume: 0.4)
        XCTAssertEqual(timers.pendingDelays, [1.5])
        timers.advance(by: 1.5)
        XCTAssertEqual(player.pauseCalls, 1)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
    }

    func testCoordinatorPlaysRainOnlyWhenRaining() throws {
        let player = FakeAmbientPlayer()
        let c = try coordinator(ambient: player)
        c.setWeather(.manual(.rain))
        XCTAssertTrue(player.isPlaying)
        c.setWeather(.manual(.clear))
        timers.advance(by: 1.5)
        XCTAssertFalse(player.isPlaying)
        c.setRainSound(.always)
        XCTAssertTrue(player.isPlaying)
        c.setActive(false)
        timers.advance(by: 1.5)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(saved().rainSound, .always)
        c.setRainVolume(3)
        XCTAssertEqual(c.config.rainVolume, 1)
        XCTAssertTrue(c.hasRainSound)
    }

    func testRainSettingsDecodeWithDefaultsAndClamp() throws {
        let d = try decode("{}")
        XCTAssertEqual(d.rainSound, .whenRaining)
        XCTAssertEqual(d.rainVolume, 0.4)
        let c = try decode(#"{"rainSound":"always","rainVolume":7}"#)
        XCTAssertEqual(c.rainSound, .always)
        XCTAssertEqual(c.rainVolume, 1)
        XCTAssertEqual(try decode(#"{"rainVolume":-1}"#).rainVolume, 0)
    }
}
