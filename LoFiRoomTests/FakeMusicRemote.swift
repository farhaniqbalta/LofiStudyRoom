import UIKit
@testable import LoFiRoom

@MainActor
final class FakeMusicRemote: MusicRemote {
    var isConfigured = true
    var isInstalled = true
    var hasToken = false
    var onEvent: ((MusicRemoteEvent) -> Void)?
    private(set) var calls: [String] = []
    func count(_ name: String) -> Int { calls.filter { $0 == name }.count }
    func send(_ event: MusicRemoteEvent) { onEvent?(event) }

    func authorizeAndPlay() { calls.append("authorizeAndPlay") }
    func connect() { calls.append("connect") }
    func disconnect() { calls.append("disconnect") }
    func forgetToken() { calls.append("forgetToken"); hasToken = false }
    func pause() { calls.append("pause") }
    func resume() { calls.append("resume") }
    func next() { calls.append("next") }
    func previous() { calls.append("previous") }
    var callbackResult: Bool?
    var artworkImage: UIImage?
    var lastArtworkError: String?
    func handleCallback(_ url: URL) -> Bool { calls.append("handleCallback"); return callbackResult ?? (url.scheme == "lofiroom") }
    func artwork(for track: NowPlaying, size: CGSize, completion: @escaping (UIImage?) -> Void) { completion(artworkImage) }
}
