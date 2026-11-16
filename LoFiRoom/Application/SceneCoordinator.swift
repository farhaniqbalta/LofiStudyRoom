import Foundation
import QuartzCore
import UIKit
import os

/// Turns application state and events into scene updates. The scene never reads state or services itself.
@MainActor
final class SceneCoordinator: ObservableObject {
    let repository: SpriteAssetRepository
    let store: RoomStateStore
    let scene: LoFiSKScene
    /// Tap frames in view points, already padded.
    @Published private(set) var hotspotFrames: [String: CGRect] = [:]
    /// View-coordinate frames of every music skin slot; empty without a skin.
    @Published private(set) var musicSlotFrames: [String: CGRect] = [:]
    @Published var musicPanelVisible = false { didSet { applyMusic() } }
    @Published private(set) var musicState = MusicState(connection: .notConfigured, track: nil) { didSet { applyMusic() } }
    @Published private(set) var weatherStatus: WeatherStatus = .off
    @Published var panelVisible = false
    @Published private(set) var controlsVisible = false
    @Published private(set) var citySearchMessage: String?
    @Published private(set) var isActive = false
    @Published private(set) var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Published private(set) var thermal = ProcessInfo.processInfo.thermalState
    private let timers: TimerScheduling
    private let weather: WeatherProviding
    private var hideControls: Cancellable?
    private var environment: EnvironmentController!
    private var reloading: Task<Void, Never>?
    private var clockDriver: ClockDriver?
    private let now: () -> Date
    private let log = Logger(subsystem: "com.lofiroom.app", category: "packs")

    static let categories: [(name: String, key: WritableKeyPath<RoomConfig, String>)] = [
        ("Scenery", \.scenery), ("Characters", \.character), ("Pets", \.pet), ("Clocks", \.clock),
    ]

    private var music: MusicController?
    let musicRemote: MusicRemote?
    private let characterDirector: ActorDirector
    private let petDirector: ActorDirector
    private let ambient: AmbientAudio?
    var hasRainSound: Bool { ambient != nil }

    init(repository: SpriteAssetRepository, store: RoomStateStore, scene: LoFiSKScene,
         timers: TimerScheduling = LiveTimers(), clock: @escaping () -> TimeInterval = CACurrentMediaTime,
         routineSpeed: Double? = nil, now: @escaping () -> Date = Date.init,
         weather: WeatherProviding = OpenMeteoProvider(), weatherCacheURL: URL = SceneCoordinator.defaultWeatherCacheURL(),
         music: MusicRemote? = nil, ambient: AmbientPlayer? = nil) {
        musicRemote = music
        self.ambient = ambient.map { AmbientAudio(player: $0, timers: timers) }
        self.now = now
        self.timers = timers
        self.weather = weather
        self.repository = repository
        self.store = store
        self.scene = scene
        characterDirector = ActorDirector(node: scene.character, delay: RoutineConfig.characterDelay, timers: timers,
                                          clock: clock, speed: routineSpeed ?? store.config.routineFrequency) { [scene] in scene.show($0) }
        petDirector = ActorDirector(node: scene.pet, delay: RoutineConfig.petDelay, timers: timers,
                                    clock: clock, speed: routineSpeed ?? store.config.routineFrequency) { [scene] in scene.show($0) }
        environment = EnvironmentController(provider: weather, timers: timers, cacheURL: weatherCacheURL, now: now) { [weak self] in
            guard let self else { return }
            applyEnvironment()
            weatherStatus = environment.status
        }
        self.music = music.map { remote in
            MusicController(remote: remote) { [weak self] in
                guard let self, let state = self.music?.state else { return }
                musicState = state
            }
        }
        if let state = self.music?.state { musicState = state }
        scene.onLayout = { [weak self, weak scene] in
            guard let self, let scene else { return }
            var frames: [String: CGRect] = [:]
            for name in scene.manifest.hotspots?.keys ?? [:].keys {
                if let rect = scene.viewRect(forHotspot: name) { frames[name] = Self.tapFrame(rect) }
            }
            if frames != hotspotFrames { hotspotFrames = frames }
            var slots: [String: CGRect] = [:]
            for name in scene.manifest.music?.slots.keys ?? [:].keys {
                if let rect = scene.viewRect(forMusicSlot: name) { slots[name] = rect }
            }
            if slots != musicSlotFrames { musicSlotFrames = slots }
        }
    }

    var config: RoomConfig { store.config }

    /// The only place the config is written, so observers always hear about it.
    private func update(_ change: (inout RoomConfig) -> Void) {
        objectWillChange.send()
        change(&store.config)
    }

    func packNames(in category: String) -> [String] { repository.folders(in: category) }

    func setTime(_ setting: TimeSetting) { update { $0.time = setting }; environmentSettingsChanged() }
    func setWeather(_ setting: WeatherSetting) { update { $0.weather = setting }; environmentSettingsChanged() }
    func setCity(_ city: City) { update { $0.city = city }; environmentSettingsChanged() }
    func setKeepAwake(_ on: Bool) { update { $0.keepAwake = on } }
    func setRainSound(_ mode: RainSoundMode) { update { $0.rainSound = mode }; applyAmbient() }
    func setRainVolume(_ volume: Double) { update { $0.rainVolume = volume }; applyAmbient() }

    func setRoutineFrequency(_ value: Double) {
        update { $0.routineFrequency = value }
        characterDirector.setSpeed(config.routineFrequency)
        petDirector.setSpeed(config.routineFrequency)
    }

    /// Shows the settings gear for 4 seconds; calling again restarts the 4 seconds.
    func revealControls() {
        controlsVisible = true
        hideControls?.cancel()
        hideControls = timers.schedule(after: 4) { [weak self] in self?.controlsVisible = false }
    }

    /// Never changes the saved city; the caller picks one of the results.
    func searchCities(_ text: String) async -> [City] {
        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { citySearchMessage = nil; return [] }
        do {
            let cities = try await weather.searchCities(name)
            citySearchMessage = cities.isEmpty ? "No cities found." : nil
            return cities
        } catch {
            citySearchMessage = "Couldn't search. Check your connection."
            return []
        }
    }

    static func weatherStatusText(_ status: WeatherStatus, hasCity: Bool, fetched: Date?, calendar: Calendar) -> String {
        guard hasCity else { return "Choose a city for automatic weather" }
        switch status {
        case .off: return "Weather is off (time and weather are manual)"
        case .loading: return "Updating…"
        case .current:
            guard let fetched else { return "Updated" }
            let format = DateFormatter()
            format.locale = Locale(identifier: "en_US_POSIX")
            format.calendar = calendar
            format.timeZone = calendar.timeZone
            format.dateFormat = "HH:mm"
            return "Updated \(format.string(from: fetched))"
        case .stale: return "Weather may be out of date"
        case .unavailable: return "Weather unavailable"
        }
    }

    var weatherStatusLine: String {
        Self.weatherStatusText(weatherStatus, hasCity: config.city != nil, fetched: environment.snapshot?.fetched, calendar: .autoupdatingCurrent)
    }

    static func defaultWeatherCacheURL() -> URL {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("weather.json")
    }

    /// Call after `store.config.time`, `.weather` or `.city` changed.
    func environmentSettingsChanged() {
        applyEnvironment()
        Task { await reloadWeather() }
    }

    /// Fetches only with a city and at least one automatic setting; otherwise the network stays unused.
    /// Reloads run one after another, so overlapping calls cannot discard each other's result.
    func reloadWeather() async {
        let previous = reloading
        let task = Task { @MainActor in
            await previous?.value
            let config = store.config
            let automatic = config.time == .automatic || config.weather == .automatic
            await environment.start(city: automatic ? config.city : nil)
        }
        reloading = task
        await task.value
    }

    func powerStateChanged(lowPower: Bool, thermal: ProcessInfo.ThermalState) {
        self.lowPower = lowPower
        self.thermal = thermal
    }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        if active { Task { await environment.refreshIfStale() } } else { environment.stop() }
        characterDirector.setActive(active)
        petDirector.setActive(active)
        applyAmbient()
        if active { music?.becameActive() } else { music?.resignedActive() }
    }

    func petTapped() { petDirector.tapped() }

    /// Grows a rect around its centre so each side is at least `minimum`; never shrinks.
    static func tapFrame(_ rect: CGRect, minimum: CGFloat = 44) -> CGRect {
        let w = max(rect.width, minimum), h = max(rect.height, minimum)
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }

    /// Hotspot roles are engine vocabulary; anything else is ignored.
    func tapped(hotspot name: String) {
        switch name {
        case "pet": petTapped()
        case "lamp": lampTapped()
        case "window": windowTapped()
        case "computer": computerTapped()
        default: break
        }
    }

    func lampTapped() {
        update { $0.lampOn.toggle() }
        applyEnvironment()
    }

    func windowTapped() {
        let folders = repository.folders(in: "Scenery")
        guard folders.count > 1 else { return }
        let next = (folders.firstIndex(of: store.config.scenery).map { $0 + 1 } ?? 0) % folders.count
        select(folders[next], in: "Scenery")
    }

    func computerTapped() {
        musicPanelVisible.toggle()
        if musicPanelVisible { music?.cardOpened() } else { music?.cardClosed() }
    }

    /// The cover for a track through the music protocol; nil when there is no remote or no image.
    func loadArtwork(for track: NowPlaying, size: CGSize) async -> UIImage? {
        guard let remote = musicRemote else { return nil }
        return await withCheckedContinuation { continuation in
            remote.artwork(for: track, size: size) { continuation.resume(returning: $0) }
        }
    }
    var artworkStatus: String? { musicRemote?.lastArtworkError }

    func musicPrimaryAction() { music?.primaryAction() }
    func musicTogglePlayPause() { music?.togglePlayPause() }
    func musicNext() { music?.next() }
    func musicPrevious() { music?.previous() }
    func handleCallback(_ url: URL) { _ = music?.handleCallback(url) }

    /// Shows the saved configuration and starts the clock.
    func start(clockDriver: ClockDriver? = nil) {
        for (category, key) in Self.categories {
            // A saved pack that no longer exists or fails validation falls back to the first pack that loads.
            let candidates = [store.config[keyPath: key]] + repository.folders(in: category)
            if !candidates.contains(where: { select($0, in: category) }) {
                log.error("No usable pack in \(category, privacy: .public)")
            }
        }
        applyEnvironment()
        Task { await reloadWeather() }
        let driver = clockDriver ?? ClockDriver { [weak self] in
            self?.scene.clock.show($0)
            self?.applyEnvironment()
        }
        driver.start()
        self.clockDriver = driver
        setActive(true)
    }

    var hasMusicSkin: Bool { scene.hasMusicSkin }

    private func applyMusic() {
        scene.applyMusic(panelVisible: musicPanelVisible, state: musicState, reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    func applyEnvironment() {
        applyMusic()
        scene.apply(EnvironmentRules.resolve(config: store.config, snapshot: environment.snapshot, now: now(), calendar: .autoupdatingCurrent),
                    reduceMotion: UIAccessibility.isReduceMotionEnabled)
        applyAmbient()
    }

    private func applyAmbient() {
        ambient?.update(play: AmbientSound.shouldPlay(mode: config.rainSound, sky: scene.applied?.sky ?? .clear, active: isActive),
                        volume: config.rainVolume)
    }

    /// Swaps one pack and saves the choice. Returns false, leaving the scene as it was, if the pack is unusable.
    @discardableResult
    func select(_ folder: String, in category: String) -> Bool {
        guard let key = Self.categories.first(where: { $0.name == category })?.key else { return false }
        do {
            let pack = try repository.load(category, folder)
            switch category {
            case "Characters": characterDirector.show(pack)
            case "Pets": petDirector.show(pack)
            default: scene.show(pack)
            }
            update { $0[keyPath: key] = folder }
            return true
        } catch {
            log.error("\(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
