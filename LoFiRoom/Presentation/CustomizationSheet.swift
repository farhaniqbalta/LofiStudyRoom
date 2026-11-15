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

    var body: some View {
        NavigationStack {
            Form {
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

    private func runSearch() {
        searching = true
        Task {
            results = await coordinator.searchCities(search)
            searching = false
        }
    }
}
