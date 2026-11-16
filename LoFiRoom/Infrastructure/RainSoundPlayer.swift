import AVFoundation

/// Looping rain from the optional `LocalAudio/rain.mp3`. Mixes with Spotify: never interrupts or ducks it.
@MainActor
final class RainSoundPlayer: AmbientPlayer {
    private let player: AVAudioPlayer
    private static var sessionReady = false

    private init(_ player: AVAudioPlayer) { self.player = player }

    /// nil when the file is not in the bundle (fresh clone) or cannot be read.
    static func make() -> RainSoundPlayer? {
        guard let url = Bundle.main.url(forResource: "rain", withExtension: "mp3", subdirectory: "LocalAudio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = -1
        player.prepareToPlay()
        return RainSoundPlayer(player)
    }

    var volume: Float { get { player.volume } set { player.volume = newValue } }
    var isPlaying: Bool { player.isPlaying }

    func play() {
        if !Self.sessionReady {
            // Set once, lazily. Never deactivated, so Spotify is not told to resume or pause.
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            Self.sessionReady = true
        }
        player.play()
    }

    func pause() { player.pause() }
    func fade(to volume: Float, duration: TimeInterval) { player.setVolume(volume, fadeDuration: duration) }
}
