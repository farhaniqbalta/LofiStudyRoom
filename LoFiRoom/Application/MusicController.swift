import UIKit

enum MusicRemoteEvent: Equatable {
    case connected, connectFailed(authorization: Bool), disconnected, playing(NowPlaying), authorizationDenied, authorizeFailed
}

@MainActor
protocol MusicRemote: AnyObject {
    var isConfigured: Bool { get }
    var isInstalled: Bool { get }
    var hasToken: Bool { get }
    var onEvent: ((MusicRemoteEvent) -> Void)? { get set }
    func authorizeAndPlay()
    func connect()
    func disconnect()
    func forgetToken()
    func pause()
    func resume()
    func next()
    func previous()
    func handleCallback(_ url: URL) -> Bool
    func artwork(for track: NowPlaying, size: CGSize, completion: @escaping (UIImage?) -> Void)
    var lastArtworkError: String? { get }
}

/// All music state logic. No timers, no polling; the only app switch is `primaryAction()`.
@MainActor
final class MusicController {
    private let remote: MusicRemote
    private let onChange: () -> Void
    private var cardIsOpen = false
    private var started = false
    private var wasConnectedWhenLeft = false
    /// A callback delivered a token and the adapter already started connecting.
    private var connectInFlight = false
    private(set) var state: MusicState {
        didSet { if started, state != oldValue { onChange() } }
    }

    init(remote: MusicRemote, onChange: @escaping () -> Void) {
        self.remote = remote
        self.onChange = onChange
        state = MusicState(connection: .notConfigured, track: nil)
        recheck()
        started = true
        remote.onEvent = { [weak self] in self?.handle($0) }
    }

    func cardOpened() { cardIsOpen = true; silentConnect() }

    func becameActive() {
        let wasConnected = wasConnectedWhenLeft
        wasConnectedWhenLeft = false
        if connectInFlight { return }
        // An authorize that produced no callback leaves `connecting` behind.
        if state.connection == .connecting { state.connection = remote.hasToken ? .dropped : .neverConnected }
        if wasConnected || cardIsOpen { silentConnect() } else { recheck() }
    }

    func resignedActive() {
        let connection = state.connection
        wasConnectedWhenLeft = connection == .connected
        connectInFlight = false
        remote.disconnect()
        if connection == .connected || (connection == .connecting && remote.hasToken) { state.connection = .dropped }
    }

    func cardClosed() { cardIsOpen = false }

    func primaryAction() {
        switch state.connection {
        case .neverConnected, .dropped, .needsReconnect:
            state.connection = .connecting
            remote.authorizeAndPlay()
        default: break
        }
    }

    func togglePlayPause() {
        guard state.connection == .connected, let track = state.track else { return }
        if track.isPaused { remote.resume() } else { remote.pause() }
    }

    func next() { if state.connection == .connected { remote.next() } }
    func previous() { if state.connection == .connected { remote.previous() } }
    func handleCallback(_ url: URL) -> Bool {
        let handled = remote.handleCallback(url)
        if handled && state.connection == .connecting { connectInFlight = true }
        return handled
    }

    /// The user may have installed Spotify, or configured the build, since the last look.
    private func recheck() {
        if !remote.isConfigured { state.connection = .notConfigured }
        else if !remote.isInstalled { state.connection = .notInstalled }
        else if state.connection == .notConfigured || state.connection == .notInstalled {
            state.connection = remote.hasToken ? .dropped : .neverConnected
        }
    }

    private func silentConnect() {
        recheck()
        if state.connection == .dropped {
            state.connection = .connecting
            remote.connect()
        }
    }

    private func handle(_ event: MusicRemoteEvent) {
        if case .playing = event {} else { connectInFlight = false }
        switch event {
        case .connected: state.connection = .connected
        case .playing(let track): state.track = track
        case .disconnected, .connectFailed(authorization: false): state.connection = .dropped
        case .connectFailed(authorization: true):
            remote.forgetToken()
            state = MusicState(connection: .needsReconnect, track: nil)
        case .authorizationDenied: if state.connection == .connecting { state.connection = .needsReconnect }
        case .authorizeFailed:
            recheck()
            if state.connection == .connecting { state.connection = remote.hasToken ? .dropped : .neverConnected }
        }
    }
}
