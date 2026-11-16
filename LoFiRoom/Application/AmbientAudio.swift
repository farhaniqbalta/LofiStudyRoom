import Foundation

@MainActor
protocol AmbientPlayer: AnyObject {
    var volume: Float { get set }
    var isPlaying: Bool { get }
    func play()
    func pause()
    /// Ramps the volume; the live player lets AVAudioPlayer do it, so nothing runs per frame here.
    func fade(to volume: Float, duration: TimeInterval)
}

/// Applies "should it play, how loud" to one player with fades. One timer at most, only while fading out.
@MainActor
final class AmbientAudio {
    static let fadeDuration: TimeInterval = 1.5
    private let player: AmbientPlayer
    private let timers: TimerScheduling
    private var playing = false
    private var volume = 0.0
    private var pauseTimer: Cancellable?

    init(player: AmbientPlayer, timers: TimerScheduling) {
        self.player = player
        self.timers = timers
    }

    func update(play: Bool, volume: Double) {
        guard play != playing || (play && volume != self.volume) else { return }
        let fadingIn = play && !playing
        playing = play
        self.volume = volume
        pauseTimer?.cancel()
        pauseTimer = nil
        if play {
            if !player.isPlaying { player.volume = 0; player.play() }
            player.fade(to: Float(volume), duration: fadingIn ? Self.fadeDuration : 0.2)
        } else {
            player.fade(to: 0, duration: Self.fadeDuration)
            pauseTimer = timers.schedule(after: Self.fadeDuration) { [player] in player.pause() }
        }
    }
}
