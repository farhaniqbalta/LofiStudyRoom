import SwiftUI

/// Settings panel: plain system controls that only call coordinator methods.
struct CustomizationSheet: View {
    @ObservedObject var coordinator: SceneCoordinator
    @State private var search = ""
    @State private var results: [City] = []
    @State private var searching = false

    private func packSection(_ title: String, _ category: String, _ key: KeyPath<RoomConfig, String>) -> some View {
        let names = coordinator.packNames(in: category)
        return Group {
            if names.count > 1 {
                Section(title) {
                    Picker(title, selection: Binding(get: { coordinator.config[keyPath: key] }, set: { coordinator.select($0, in: category) })) {
                        ForEach(names, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
        }
    }

    /// Which art set to open with. The room is built once at launch, so the change waits for the next launch.
    @ViewBuilder private var artSetSection: some View {
        let sets = coordinator.repository.artSets
        if sets.count > 1 {
            let running = coordinator.repository.artSet
            let chosen = coordinator.config.artSet ?? running
            Section {
                Picker("Art set", selection: Binding(get: { chosen ?? "" }, set: { coordinator.chooseArtSet($0) })) {
                    ForEach(sets.keys.sorted(), id: \.self) { Text("\($0) · \(sets[$0]!)").tag($0) }
                }
            } header: { Text("Art set") } footer: {
                if let chosen, chosen != running { Text("Close and reopen the app to switch to \(chosen).") }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                artSetSection
                packSection("Character", "Characters", \.character)
                packSection("Pet", "Pets", \.pet)
                packSection("Scenery", "Scenery", \.scenery)
                Section("Time") {
                    Picker("Time", selection: Binding(get: { coordinator.config.time }, set: { coordinator.setTime($0) })) {
                        Text("Automatic").tag(TimeSetting.automatic)
                        Text("Day").tag(TimeSetting.manual(.day))
                        Text("Night").tag(TimeSetting.manual(.night))
                    }.pickerStyle(.segmented)
                }
                Section("Weather") {
                    Picker("Weather", selection: Binding(get: { coordinator.config.weather }, set: { coordinator.setWeather($0) })) {
                        Text("Automatic").tag(WeatherSetting.automatic)
                        Text("Clear").tag(WeatherSetting.manual(.clear))
                        Text("Rain").tag(WeatherSetting.manual(.rain))
                    }.pickerStyle(.segmented)
                    Text(coordinator.config.city?.name ?? "No city chosen")
                    HStack {
                        TextField("Search city", text: $search).onSubmit(runSearch)
                        Button("Search", action: runSearch).disabled(searching)
                    }
                    ForEach(results, id: \.self) { city in
                        Button(city.name) { coordinator.setCity(city); results = [] }
                    }
                    if let message = coordinator.citySearchMessage { Text(message) }
                    Text(coordinator.weatherStatusLine).foregroundStyle(.secondary)
                }
                Section("Animation") {
                    Slider(value: Binding(get: { Self.slider(forFrequency: coordinator.config.routineFrequency) },
                                          set: { coordinator.setRoutineFrequency(Self.frequency(atSlider: $0)) }), in: 0...1) {
                        Text("Animation frequency")
                    } minimumValueLabel: { Text("Rare") } maximumValueLabel: { Text("Often") }
                    .accessibilityValue("\(Self.frequencyText(coordinator.config.routineFrequency)) times as often")
                    Text(Self.frequencyText(coordinator.config.routineFrequency) + "×").foregroundStyle(.secondary)
                }
                if coordinator.hasRainSound || coordinator.roomSound != nil {
                    Section {
                        if coordinator.hasRainSound {
                            Picker("Rain sound", selection: Binding(get: { coordinator.config.rainSound }, set: { coordinator.setRainSound($0) })) {
                                Text("Off").tag(RainSoundMode.off)
                                Text("When raining").tag(RainSoundMode.whenRaining)
                                Text("Always").tag(RainSoundMode.always)
                            }.pickerStyle(.segmented)
                            HStack {
                                Image(systemName: "speaker.wave.2.fill").accessibilityHidden(true)
                                Slider(value: Binding(get: { coordinator.config.rainVolume }, set: { coordinator.setRainVolume($0) }), in: 0...1) {
                                    Text("Rain volume")
                                }
                            }
                            .disabled(coordinator.config.rainSound == .off)
                        }
                        if let sound = coordinator.roomSound {
                            Toggle("\(sound.name) sound", isOn: Binding(get: { coordinator.config.roomSoundOn }, set: { coordinator.setRoomSound($0) }))
                            HStack {
                                Image(systemName: "speaker.wave.2.fill").accessibilityHidden(true)
                                Slider(value: Binding(get: { coordinator.config.roomSoundVolume }, set: { coordinator.setRoomSoundVolume($0) }), in: 0...1) {
                                    Text("\(sound.name) volume")
                                }
                            }
                            .disabled(!coordinator.config.roomSoundOn)
                        }
                    } header: { Text("Sound") } footer: { Text("Plays on top of Spotify.") }
                }
                Section("Display") {
                    Toggle("Keep screen awake (uses more battery)", isOn: Binding(get: { coordinator.config.keepAwake }, set: { coordinator.setKeepAwake($0) }))
                }
                Section("About") {
                    Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
                }
            }
            .navigationTitle("Room")
            .toolbar { Button("Done") { coordinator.panelVisible = false } }
        }
    }

    /// Slider 0...1 to frequency, logarithmic: 0.5 * 40^t.
    static func frequency(atSlider t: Double) -> Double {
        let range = RoomConfig.routineFrequencyRange
        return range.lowerBound * pow(range.upperBound / range.lowerBound, t)
    }

    static func slider(forFrequency f: Double) -> Double {
        let range = RoomConfig.routineFrequencyRange
        return log(f / range.lowerBound) / log(range.upperBound / range.lowerBound)
    }

    /// One decimal below 10, none above (without the multiplication sign).
    static func frequencyText(_ f: Double) -> String { f < 10 ? String(format: "%.1f", f).replacingOccurrences(of: ".0", with: "") : String(Int(f.rounded())) }

    private func runSearch() {
        searching = true
        Task {
            results = await coordinator.searchCities(search)
            searching = false
        }
    }
}
