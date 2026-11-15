import Foundation

struct NowPlaying: Equatable {
    var title: String
    var artist: String
    var isPaused: Bool
    var imageID: String?
}

enum MusicConnection: Equatable {
    case notConfigured, notInstalled, neverConnected, connecting, connected, dropped, needsReconnect
}

struct MusicState: Equatable {
    var connection: MusicConnection
    var track: NowPlaying?
}
