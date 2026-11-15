import XCTest
@testable import LoFiRoom

final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var lastURL: URL?
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastURL = request.url
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private struct Offline: Error {}

final class WeatherProviderTests: XCTestCase {
    private let jakarta = City(name: "Jakarta", latitude: -6.2088, longitude: 106.8456)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func provider(status: Int = 200, body: String) -> OpenMeteoProvider {
        StubURLProtocol.status = status
        StubURLProtocol.body = Data(body.utf8)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return OpenMeteoProvider(session: URLSession(configuration: config))
    }

    private func items(_ url: URL?) -> [String: String] {
        let list = URLComponents(url: url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: list.map { ($0.name, $0.value ?? "") })
    }

    func testForecastRequestAndParsing() async throws {
        let body = #"{"current":{"weather_code":61},"daily":{"sunrise":["2026-11-14T05:31"],"sunset":["2026-11-14T17:49"]},"timezone":"Asia/Jakarta"}"#
        let result = try await provider(body: body).snapshot(for: jakarta, now: now)
        XCTAssertEqual(result.sky, .rain)
        XCTAssertEqual(result.fetched, now)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        XCTAssertEqual(result.sunrise, calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 5, minute: 31)))
        XCTAssertEqual(result.sunset, calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 17, minute: 49)))
        let url = StubURLProtocol.lastURL
        XCTAssertEqual(url?.host, "api.open-meteo.com")
        XCTAssertEqual(url?.path, "/v1/forecast")
        let q = items(url)
        XCTAssertEqual(q["current"], "weather_code")
        XCTAssertEqual(q["daily"], "sunrise,sunset")
        XCTAssertEqual(q["timezone"], "auto")
        XCTAssertEqual(q["forecast_days"], "1")
        XCTAssertEqual(Double(q["latitude"] ?? ""), jakarta.latitude)
        XCTAssertEqual(Double(q["longitude"] ?? ""), jakarta.longitude)
    }

    func testForecastWithoutSunTimesStillWorks() async throws {
        let result = try await provider(body: #"{"current":{"weather_code":0}}"#).snapshot(for: jakarta, now: now)
        XCTAssertEqual(result.sky, .clear)
        XCTAssertNil(result.sunrise)
        XCTAssertNil(result.sunset)
        do {
            _ = try await provider(body: "{}").snapshot(for: jakarta, now: now)
            XCTFail("expected a throw")
        } catch {}
    }

    func testCitySearchParsingAndEmptyResult() async throws {
        let body = #"{"results":[{"name":"Paris","latitude":48.85,"longitude":2.35,"country":"France"},{"name":"Nowhere","latitude":1,"longitude":2}]}"#
        let cities = try await provider(body: body).searchCities("Par is")
        XCTAssertEqual(cities.map(\.name), ["Paris, France", "Nowhere"])
        XCTAssertEqual(cities[0].latitude, 48.85)
        let url = StubURLProtocol.lastURL
        XCTAssertEqual(url?.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(items(url)["name"], "Par is")
        XCTAssertEqual(items(url)["count"], "5")
        let empty = try await provider(body: "{}").searchCities("zzz")
        XCTAssertEqual(empty, [])
    }

    func testHttpErrorThrows() async {
        let p = provider(status: 500, body: "{}")
        do { _ = try await p.snapshot(for: jakarta, now: now); XCTFail("expected a throw") } catch {}
        do { _ = try await p.searchCities("x"); XCTFail("expected a throw") } catch {}
    }
}

@MainActor
final class EnvironmentControllerTests: XCTestCase {
    private let jakarta = City(name: "Jakarta", latitude: -6.2088, longitude: 106.8456)
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private var defaults: UserDefaults!
    private var root: URL!
    private var cache: URL!
    private var timers: FakeTimers!
    private var changes = 0

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "WeatherTests")
        defaults.removePersistentDomain(forName: "WeatherTests")
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        _ = try FixtureScene.make(in: root)
        cache = root.appendingPathComponent("weather.json")
        timers = FakeTimers()
        changes = 0
    }

    override func tearDown() async throws { try? FileManager.default.removeItem(at: root) }

    private func snap(_ sky: Sky = .rain, at date: Date? = nil) -> WeatherSnapshot {
        WeatherSnapshot(sky: sky, sunrise: nil, sunset: nil, fetched: date ?? t0)
    }

    private func controller(_ provider: WeatherProviding, now: Date? = nil) -> EnvironmentController {
        let date = now ?? t0
        return EnvironmentController(provider: provider, timers: timers, cacheURL: cache, now: { date }, onChange: { [unowned self] in changes += 1 })
    }

    private func coordinator(_ provider: WeatherProviding, time: TimeSetting, weather: WeatherSetting, city: City?) throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let c = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                 timers: fake, clock: { fake.now }, weather: provider,
                                 weatherCacheURL: root.appendingPathComponent("coordinator.json"))
        c.store.config.time = time
        c.store.config.weather = weather
        c.store.config.city = city
        c.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return c
    }

    func testOfflineFirstLaunchIsUnavailableNotBlank() async throws {
        let failing = FakeWeather(.failure(Offline()))
        let c = controller(failing)
        await c.start(city: jakarta)
        XCTAssertEqual(c.status, .unavailable)
        XCTAssertNil(c.snapshot)
        XCTAssertGreaterThanOrEqual(changes, 1)
        let coordinator = try coordinator(failing, time: .automatic, weather: .automatic, city: jakarta)
        await coordinator.reloadWeather()
        XCTAssertEqual(coordinator.scene.applied?.sky, .clear)
        XCTAssertEqual(coordinator.weatherStatus, .unavailable)
    }

    func testCacheIsUsedOfflineAndMarkedStaleAfterTwoHours() async {
        let first = controller(FakeWeather(.success(snap())))
        await first.start(city: jakarta)
        XCTAssertEqual(first.status, .current)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.path))
        let failing = FakeWeather(.failure(Offline()))
        let second = controller(failing, now: t0.addingTimeInterval(3600))
        await second.start(city: jakarta)
        XCTAssertEqual(second.snapshot, snap())
        XCTAssertEqual(second.status, .current)
        let third = controller(failing, now: t0.addingTimeInterval(3 * 3600))
        await third.start(city: jakarta)
        XCTAssertEqual(third.status, .stale)
        let fourth = controller(failing, now: t0.addingTimeInterval(3600))
        await fourth.start(city: City(name: "Elsewhere", latitude: 1, longitude: 2))
        XCTAssertNil(fourth.snapshot)
        XCTAssertEqual(fourth.status, .unavailable)
    }

    func testRefreshTimerIsSingleAndThirtyMinutes() async {
        let provider = FakeWeather(.success(snap()))
        let c = controller(provider)
        await c.start(city: jakarta)
        c.stop()
        await c.start(city: jakarta)
        XCTAssertEqual(timers.pendingDelays, [1800])
        let before = provider.calls
        timers.advance(by: 1800)
        for _ in 0..<200 where provider.calls == before || timers.pendingDelays.count != 1 { await Task.yield() }
        XCTAssertEqual(provider.calls, before + 1)
        XCTAssertEqual(timers.pendingDelays, [1800])
    }

    func testNoCityMeansOffAndNoNetwork() async throws {
        let provider = FakeWeather(.success(snap()))
        let c = controller(provider)
        await c.start(city: nil)
        XCTAssertEqual(c.status, .off)
        XCTAssertEqual(provider.calls, 0)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
        let coordinator = try coordinator(provider, time: .manual(.night), weather: .manual(.clear), city: jakarta)
        await coordinator.reloadWeather()
        XCTAssertEqual(provider.calls, 0)
        XCTAssertEqual(coordinator.weatherStatus, .off)
    }

    func testManualWeatherIsNeverOverwritten() async throws {
        let provider = FakeWeather(.success(snap(.rain)))
        let coordinator = try coordinator(provider, time: .automatic, weather: .manual(.clear), city: jakarta)
        await coordinator.reloadWeather()
        XCTAssertGreaterThan(provider.calls, 0)
        XCTAssertEqual(coordinator.scene.applied?.sky, .clear)
        XCTAssertEqual(coordinator.store.config.weather, .manual(.clear))
    }

    func testFetchedRainShowsWhenAutomatic() async throws {
        let provider = FakeWeather(.success(snap(.rain)))
        let coordinator = try coordinator(provider, time: .automatic, weather: .automatic, city: jakarta)
        await coordinator.reloadWeather()
        XCTAssertEqual(coordinator.scene.applied?.sky, .rain)
        XCTAssertEqual(coordinator.weatherStatus, .current)
    }

    func testResultAfterStopIsDiscarded() async {
        let provider = FakeWeather(.success(snap()))
        let (stream, release) = AsyncStream<Void>.makeStream()
        provider.gate = { for await _ in stream { break } }
        let c = controller(provider)
        let task = Task { await c.start(city: jakarta) }
        for _ in 0..<200 where provider.calls == 0 { await Task.yield() }
        c.stop()
        release.yield()
        await task.value
        XCTAssertNil(c.snapshot)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
    }
}
