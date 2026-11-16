import Foundation
@testable import LoFiRoom

@MainActor
final class FakeAmbientPlayer: AmbientPlayer {
    var volume: Float = 1
    private(set) var isPlaying = false
    private(set) var playCalls = 0
    private(set) var pauseCalls = 0
    private(set) var fades: [(volume: Float, duration: TimeInterval)] = []

    func play() { isPlaying = true; playCalls += 1 }
    func pause() { isPlaying = false; pauseCalls += 1 }
    func fade(to volume: Float, duration: TimeInterval) { fades.append((volume, duration)) }
}
