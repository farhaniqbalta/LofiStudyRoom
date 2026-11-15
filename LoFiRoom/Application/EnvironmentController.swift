import Foundation

enum WeatherStatus: Equatable { case off, loading, current, stale, unavailable }

/// Keeps the latest weather for one city: disk cache, a fetch on start and every 30 minutes. Never throws.
@MainActor
final class EnvironmentController {
    static let refreshInterval: TimeInterval = 30 * 60

    private struct Cache: Codable { var city: City; var snapshot: WeatherSnapshot }

    private let provider: WeatherProviding
    private let timers: TimerScheduling
    private let cacheURL: URL
    private let now: () -> Date
    private let onChange: () -> Void
    private var city: City?
    private var timer: Cancellable?
    /// Bumped by start and stop; a fetch that finds it changed is discarded.
    private var generation = 0
    private var fetching: Int?
    private(set) var snapshot: WeatherSnapshot?
    private(set) var status: WeatherStatus = .off

    init(provider: WeatherProviding, timers: TimerScheduling, cacheURL: URL,
         now: @escaping () -> Date, onChange: @escaping () -> Void) {
        self.provider = provider
        self.timers = timers
        self.cacheURL = cacheURL
        self.now = now
        self.onChange = onChange
    }

    func start(city: City?) async {
        stop()
        self.city = city
        guard let city else {
            snapshot = nil
            status = .off
            onChange()
            return
        }
        let cached = (try? JSONDecoder().decode(Cache.self, from: Data(contentsOf: cacheURL))).flatMap { $0.city == city ? $0.snapshot : nil }
        snapshot = cached
        status = settled()
        onChange()
        let mine = generation
        await refresh()
        arm(mine)
    }

    func stop() {
        generation += 1
        timer?.cancel()
        timer = nil
    }

    func refreshIfStale() async {
        guard city != nil else { return }
        let mine = generation
        if snapshot.map({ now().timeIntervalSince($0.fetched) >= Self.refreshInterval }) ?? true { await refresh() }
        arm(mine)
    }

    func refresh() async {
        guard let city, fetching != generation else { return }
        let mine = generation
        fetching = mine
        defer { if fetching == mine { fetching = nil } }
        if snapshot == nil { status = .loading }
        let fetched = try? await provider.snapshot(for: city, now: now())
        guard mine == generation else { return }
        if let fetched {
            snapshot = fetched
            try? JSONEncoder().encode(Cache(city: city, snapshot: fetched)).write(to: cacheURL, options: .atomic)
        }
        status = settled()
        onChange()
    }

    private func settled() -> WeatherStatus {
        guard let snapshot else { return .unavailable }
        return EnvironmentRules.isStale(snapshot, now: now()) ? .stale : .current
    }

    /// One timer at most; does nothing if start or stop ran since `mine`.
    private func arm(_ mine: Int) {
        guard mine == generation, city != nil else { return }
        timer?.cancel()
        timer = timers.schedule(after: Self.refreshInterval) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                await self.refresh()
                self.arm(mine)
            }
        }
    }
}
