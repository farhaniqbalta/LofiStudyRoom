import Foundation

protocol WeatherProviding: Sendable {
    func snapshot(for city: City, now: Date) async throws -> WeatherSnapshot
    func searchCities(_ name: String) async throws -> [City]
}

/// Open-Meteo, no key. Requests carry only the coordinates or the typed city name.
struct OpenMeteoProvider: WeatherProviding {
    var session: URLSession = .shared

    init(session: URLSession = .shared) { self.session = session }

    private struct Forecast: Decodable {
        struct Current: Decodable { var weather_code: Int }
        struct Daily: Decodable { var sunrise: [String]?; var sunset: [String]? }
        var current: Current?
        var daily: Daily?
        var timezone: String?
    }

    private struct Search: Decodable {
        struct Result: Decodable { var name: String; var latitude: Double; var longitude: Double; var country: String? }
        var results: [Result]?
    }

    private func fetch<T: Decodable>(_ host: String, _ path: String, _ query: [URLQueryItem]) async throws -> T {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = host
        parts.path = path
        parts.queryItems = query
        guard let url = parts.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func snapshot(for city: City, now: Date) async throws -> WeatherSnapshot {
        let forecast: Forecast = try await fetch("api.open-meteo.com", "/v1/forecast", [
            .init(name: "latitude", value: String(city.latitude)),
            .init(name: "longitude", value: String(city.longitude)),
            .init(name: "current", value: "weather_code"),
            .init(name: "daily", value: "sunrise,sunset"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1"),
        ])
        guard let code = forecast.current?.weather_code else { throw URLError(.cannotParseResponse) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = forecast.timezone.flatMap(TimeZone.init(identifier:))
        func time(_ list: [String]?) -> Date? {
            guard formatter.timeZone != nil, let text = list?.first else { return nil }
            return formatter.date(from: text)
        }
        return WeatherSnapshot(sky: EnvironmentRules.sky(forWeatherCode: code), sunrise: time(forecast.daily?.sunrise),
                               sunset: time(forecast.daily?.sunset), fetched: now)
    }

    func searchCities(_ name: String) async throws -> [City] {
        let search: Search = try await fetch("geocoding-api.open-meteo.com", "/v1/search", [
            .init(name: "name", value: name), .init(name: "count", value: "5"),
            .init(name: "language", value: "en"), .init(name: "format", value: "json"),
        ])
        return (search.results ?? []).map { r in
            City(name: r.country.map { "\(r.name), \($0)" } ?? r.name, latitude: r.latitude, longitude: r.longitude)
        }
    }
}
