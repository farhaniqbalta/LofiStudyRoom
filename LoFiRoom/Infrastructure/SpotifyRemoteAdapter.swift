@preconcurrency import SpotifyiOS
import UIKit

/// The only file that imports the Spotify SDK.
@MainActor
final class SpotifyRemoteAdapter: NSObject, MusicRemote, @preconcurrency SPTAppRemoteDelegate, @preconcurrency SPTAppRemotePlayerStateDelegate {
    var onEvent: ((MusicRemoteEvent) -> Void)?
    private let remote: SPTAppRemote?
    private var lastTrack: SPTAppRemoteTrack?

    override init() {
        let id = Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String ?? ""
        if id.isEmpty || id == "$(SPOTIFY_CLIENT_ID)" {
            remote = nil
        } else {
            let configuration = SPTConfiguration(clientID: id, redirectURL: URL(string: "lofiroom://spotify-callback")!)
            remote = SPTAppRemote(configuration: configuration, logLevel: .none)
            remote?.connectionParameters.accessToken = KeychainToken.load()
        }
        super.init()
        remote?.delegate = self
    }

    var isConfigured: Bool { remote != nil }
    var isInstalled: Bool { UIApplication.shared.canOpenURL(URL(string: "spotify:")!) }
    var hasToken: Bool { remote?.connectionParameters.accessToken != nil }

    func authorizeAndPlay() { remote?.authorizeAndPlayURI("") { _ in } }
    func connect() { remote?.connect() }
    func disconnect() { remote?.disconnect() }

    func forgetToken() {
        KeychainToken.delete()
        remote?.connectionParameters.accessToken = nil
    }

    func pause() { remote?.playerAPI?.pause(nil) }
    func resume() { remote?.playerAPI?.resume(nil) }
    func next() { remote?.playerAPI?.skip(toNext: nil) }
    func previous() { remote?.playerAPI?.skip(toPrevious: nil) }

    func handleCallback(_ url: URL) -> Bool {
        guard let remote, url.scheme == "lofiroom" else { return false }
        if let token = remote.authorizationParameters(from: url)?[SPTAppRemoteAccessTokenKey] {
            KeychainToken.save(token)
            remote.connectionParameters.accessToken = token
            remote.connect()
        } else {
            onEvent?(.authorizationDenied)
        }
        return true
    }

    /// Why the last cover request gave no image; shown in the debug status line.
    private(set) var lastArtworkError: String?

    func artwork(for track: NowPlaying, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        // Every path must call `completion`: the caller awaits it.
        guard let remote, let item = lastTrack, item.imageIdentifier == track.imageID, let api = remote.imageAPI else {
            lastArtworkError = remote?.imageAPI == nil ? "no image API (not connected)" : "track changed"
            return completion(nil)
        }
        api.fetchImage(forItem: item, with: size) { [weak self] image, error in
            self?.lastArtworkError = image is UIImage ? nil : "fetch failed: \(error.map { "\($0)" } ?? "result was \(type(of: image))")"
            completion(image as? UIImage)
        }
    }

    // MARK: SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: nil)
        onEvent?(.connected)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        // The SDK reports a bad token through the error text ("invalid token", "not authorized"); anything else is treated as a plain drop.
        let text = (error as NSError?).map { "\($0.domain) \($0.localizedDescription) \($0.userInfo)".lowercased() } ?? ""
        let authorization = text.contains("token") || text.contains("authoriz") || text.contains("authentic")
        onEvent?(.connectFailed(authorization: authorization))
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) { onEvent?(.disconnected) }

    // MARK: SPTAppRemotePlayerStateDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        lastTrack = playerState.track
        onEvent?(.playing(NowPlaying(title: playerState.track.name, artist: playerState.track.artist.name,
                                     isPaused: playerState.isPaused, imageID: playerState.track.imageIdentifier)))
    }
}
