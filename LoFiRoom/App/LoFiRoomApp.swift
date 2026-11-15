import SwiftUI

@main
struct LoFiRoomApp: App {
    var body: some Scene {
        WindowGroup {
            // Throwaway: `-spotifySpike YES` shows the App Remote test screen instead of the room.
            if UserDefaults.standard.bool(forKey: "spotifySpike") { SpotifySpikeView() } else { RoomView() }
        }
    }
}
