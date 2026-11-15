import Foundation
@testable import LoFiRoom

final class FakeWeather: WeatherProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls = 0
    var result: Result<WeatherSnapshot, Error>
    var gate: (@Sendable () async -> Void)?
    init(_ result: Result<WeatherSnapshot, Error>) { self.result = result }
    var calls: Int { lock.withLock { _calls } }
    func snapshot(for city: City, now: Date) async throws -> WeatherSnapshot {
        lock.withLock { _calls += 1 }
        await gate?()
        return try result.get()
    }
    var cities: Result<[City], Error> = .success([])
    private var _searches = 0
    var searches: Int { lock.withLock { _searches } }
    func searchCities(_ name: String) async throws -> [City] {
        lock.withLock { _searches += 1 }
        return try cities.get()
    }
}
