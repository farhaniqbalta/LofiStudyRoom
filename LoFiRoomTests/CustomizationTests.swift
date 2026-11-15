import Combine
import XCTest
@testable import LoFiRoom

@MainActor
final class CustomizationTests: XCTestCase {
    private struct Offline: Error {}
    private let paris = City(name: "Paris, France", latitude: 48.85, longitude: 2.35)
    private let oslo = City(name: "Oslo", latitude: 59.9, longitude: 10.7)
    private let suite = "CustomizationTests"
    private var defaults: UserDefaults!
    private var root: URL!
    private var timers: FakeTimers!
    private var emissions = 0
    private var bag: [AnyCancellable] = []

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        _ = try FixtureScene.make(in: root)
        timers = FakeTimers()
        emissions = 0
        bag = []
    }

    override func tearDown() async throws { try? FileManager.default.removeItem(at: root) }

    private func make(_ provider: FakeWeather = FakeWeather(.success(WeatherSnapshot(sky: .rain, sunrise: nil, sunset: nil, fetched: Date()))),
                      driver: ((LoFiSKScene) -> ClockDriver)? = nil, start: Bool = true) throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let c = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                 timers: fake, clock: { fake.now }, weather: provider,
                                 weatherCacheURL: root.appendingPathComponent("weather.json"))
        if start { c.start(clockDriver: driver?(scene) ?? ClockDriver { scene.clock.show($0) }) }
        c.objectWillChange.sink { [unowned self] in emissions += 1 }.store(in: &bag)
        return c
    }

    private func saved() -> RoomConfig { RoomStateStore(defaults: defaults).config }

    func testSettersSaveApplyAndNotify() throws {
        let c = try make()
        var seen = emissions
        func step(_ change: () -> Void, _ check: (RoomConfig) -> Bool) {
            change()
            XCTAssertTrue(check(c.config))
            XCTAssertTrue(check(saved()))
            XCTAssertGreaterThan(emissions, seen)
            seen = emissions
        }
        step({ c.setTime(.manual(.day)) }) { $0.time == .manual(.day) }
        step({ c.setWeather(.manual(.rain)) }) { $0.weather == .manual(.rain) }
        XCTAssertEqual(c.scene.applied, ResolvedScene(phase: .day, sky: .rain, lampOn: true))
        step({ c.setKeepAwake(true) }) { $0.keepAwake }
    }

    func testSelectNotifiesObservers() throws {
        let c = try make(start: false)
        XCTAssertNotEqual(c.config.character, "Typist")
        XCTAssertTrue(c.select("Typist", in: "Characters"))
        XCTAssertGreaterThan(emissions, 0)
        XCTAssertEqual(c.config.character, "Typist")
    }

    func testManualNightKeepsTheRealClock() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let date = utc.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 10, minute: 15))!
        let c = try make(driver: { scene in ClockDriver(now: { date }, calendar: { utc }) { scene.clock.show($0) } })
        c.setTime(.manual(.night))
        XCTAssertEqual(c.scene.applied?.phase, .night)
        XCTAssertEqual(c.scene.clock.text, "10:15")
    }

    func testSetCityFetchesWeather() async throws {
        let c = try make()
        c.setCity(paris)
        await c.reloadWeather()
        XCTAssertEqual(saved().city, paris)
        XCTAssertEqual(c.weatherStatus, .current)
        XCTAssertEqual(c.scene.applied?.sky, .rain)
    }

    func testCitySearchResultsMessagesAndErrors() async throws {
        let provider = FakeWeather(.failure(Offline()))
        let c = try make(provider)
        let before = c.config.city
        provider.cities = .success([paris, oslo])
        var found = await c.searchCities(" Par ")
        XCTAssertEqual(found, [paris, oslo])
        XCTAssertNil(c.citySearchMessage)
        provider.cities = .success([])
        found = await c.searchCities("zzz")
        XCTAssertEqual(found, [])
        XCTAssertEqual(c.citySearchMessage, "No cities found.")
        provider.cities = .failure(Offline())
        found = await c.searchCities("x")
        XCTAssertEqual(found, [])
        XCTAssertEqual(c.citySearchMessage, "Couldn't search. Check your connection.")
        let calls = provider.searches
        found = await c.searchCities("   ")
        XCTAssertEqual(found, [])
        XCTAssertNil(c.citySearchMessage)
        XCTAssertEqual(provider.searches, calls)
        XCTAssertEqual(c.config.city, before)
    }

    func testWeatherStatusText() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        let fetched = calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 5, minute: 7))
        func text(_ s: WeatherStatus, city: Bool = true, _ date: Date? = nil) -> String {
            SceneCoordinator.weatherStatusText(s, hasCity: city, fetched: date, calendar: calendar)
        }
        XCTAssertEqual(text(.current, city: false, fetched), "Choose a city for automatic weather")
        XCTAssertEqual(text(.off), "Weather is off (time and weather are manual)")
        XCTAssertEqual(text(.loading), "Updating…")
        XCTAssertEqual(text(.current, fetched), "Updated 05:07")
        XCTAssertEqual(text(.current), "Updated")
        XCTAssertEqual(text(.stale), "Weather may be out of date")
        XCTAssertEqual(text(.unavailable), "Weather unavailable")
    }

    func testRevealControlsHidesAfterFourSeconds() throws {
        let c = try make()
        XCTAssertFalse(c.controlsVisible)
        c.revealControls()
        XCTAssertTrue(c.controlsVisible)
        timers.advance(by: 3.9)
        XCTAssertTrue(c.controlsVisible)
        timers.advance(by: 0.1)
        XCTAssertFalse(c.controlsVisible)
        c.revealControls()
        timers.advance(by: 3)
        let pending = timers.pendingDelays.count
        c.revealControls()
        XCTAssertEqual(timers.pendingDelays.count, pending)
        timers.advance(by: 3.9)
        XCTAssertTrue(c.controlsVisible)
        timers.advance(by: 0.2)
        XCTAssertFalse(c.controlsVisible)
    }

    func testPackNamesComeFromTheActiveScene() throws {
        XCTAssertEqual(try make().packNames(in: "Characters"), ["Typist"])
    }
}
