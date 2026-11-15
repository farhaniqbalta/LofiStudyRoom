import XCTest
@testable import LoFiRoom

final class EnvironmentTests: XCTestCase {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ hour: Int, _ minute: Int, in zone: String = "Asia/Jakarta", day: Int = 14) -> Date {
        calendar(zone).date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testV1ConfigKeepsPackChoices() throws {
        let v1 = #"{"schemaVersion":1,"character":"Girl01","pet":"BlackCat","scenery":"NeonCity02","clock":"RetroDigital01"}"#
        let config = try JSONDecoder().decode(RoomConfig.self, from: Data(v1.utf8))
        XCTAssertEqual(config.character, "Girl01")
        XCTAssertEqual(config.pet, "BlackCat")
        XCTAssertEqual(config.scenery, "NeonCity02")
        XCTAssertEqual(config.clock, "RetroDigital01")
        XCTAssertTrue(config.lampOn)
        XCTAssertEqual(config.time, .automatic)
        XCTAssertEqual(config.weather, .automatic)
        XCTAssertNil(config.city)
        XCTAssertFalse(config.keepAwake)
    }

    func testV2RoundTrips() throws {
        var config = RoomConfig()
        config.lampOn = false
        config.time = .manual(.night)
        config.weather = .manual(.rain)
        config.city = City(name: "Jakarta", latitude: -6.2, longitude: 106.8)
        config.keepAwake = true
        let decoded = try JSONDecoder().decode(RoomConfig.self, from: JSONEncoder().encode(config))
        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.schemaVersion, 2)
    }

    func testWeatherCodeMapping() {
        for code in [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99] {
            XCTAssertEqual(EnvironmentRules.sky(forWeatherCode: code), .rain, "code \(code)")
        }
        for code in [0, 1, 2, 3, 45, 48, 1234] {
            XCTAssertEqual(EnvironmentRules.sky(forWeatherCode: code), .clear, "code \(code)")
        }
    }

    func testPhaseUsesSunriseSunsetThenFallsBack() {
        let jakarta = calendar("Asia/Jakarta")
        let snapshot = WeatherSnapshot(sky: .clear, sunrise: date(6, 10), sunset: date(17, 55), fetched: date(5, 0))
        XCTAssertEqual(EnvironmentRules.phase(at: date(6, 9), snapshot: snapshot, calendar: jakarta), .night)
        XCTAssertEqual(EnvironmentRules.phase(at: date(6, 10), snapshot: snapshot, calendar: jakarta), .day)
        XCTAssertEqual(EnvironmentRules.phase(at: date(17, 54), snapshot: snapshot, calendar: jakarta), .day)
        XCTAssertEqual(EnvironmentRules.phase(at: date(17, 55), snapshot: snapshot, calendar: jakarta), .night)
        // A snapshot from yesterday still gives today's sunrise/sunset times of day
        XCTAssertEqual(EnvironmentRules.phase(at: date(12, 0, day: 15), snapshot: snapshot, calendar: jakarta), .day)
        XCTAssertEqual(EnvironmentRules.phase(at: date(6, 9, day: 15), snapshot: snapshot, calendar: jakarta), .night)

        XCTAssertEqual(EnvironmentRules.phase(at: date(5, 59), snapshot: nil, calendar: jakarta), .night)
        XCTAssertEqual(EnvironmentRules.phase(at: date(6, 0), snapshot: nil, calendar: jakarta), .day)
        XCTAssertEqual(EnvironmentRules.phase(at: date(17, 59), snapshot: nil, calendar: jakarta), .day)
        XCTAssertEqual(EnvironmentRules.phase(at: date(18, 0), snapshot: nil, calendar: jakarta), .night)
    }

    func testAutomaticFollowsSnapshotAndManualWins() {
        let jakarta = calendar("Asia/Jakarta")
        let rainyNoon = WeatherSnapshot(sky: .rain, sunrise: date(6, 0), sunset: date(18, 0), fetched: date(11, 0))
        var config = RoomConfig()
        XCTAssertEqual(EnvironmentRules.resolve(config: config, snapshot: rainyNoon, now: date(12, 0), calendar: jakarta),
                       ResolvedScene(phase: .day, sky: .rain, lampOn: true))

        config.time = .manual(.night)
        config.weather = .manual(.clear)
        config.lampOn = false
        XCTAssertEqual(EnvironmentRules.resolve(config: config, snapshot: rainyNoon, now: date(12, 0), calendar: jakarta),
                       ResolvedScene(phase: .night, sky: .clear, lampOn: false))

        // No weather data at all: clear sky, clock-based day/night
        XCTAssertEqual(EnvironmentRules.resolve(config: RoomConfig(), snapshot: nil, now: date(20, 0), calendar: jakarta),
                       ResolvedScene(phase: .night, sky: .clear, lampOn: true))
    }

    func testStaleAfterTwoHours() {
        let fetched = date(10, 0)
        let snapshot = WeatherSnapshot(sky: .clear, sunrise: nil, sunset: nil, fetched: fetched)
        XCTAssertFalse(EnvironmentRules.isStale(snapshot, now: fetched.addingTimeInterval(7199)))
        XCTAssertTrue(EnvironmentRules.isStale(snapshot, now: fetched.addingTimeInterval(7200)))
    }
}
