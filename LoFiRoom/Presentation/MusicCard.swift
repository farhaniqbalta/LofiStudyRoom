import SwiftUI

/// Now-playing card for the Spotify remote. Static: nothing animates, nothing polls.
struct MusicCard: View {
    @ObservedObject var coordinator: SceneCoordinator
    @State private var artwork: UIImage?

    private var state: MusicState { coordinator.musicState }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if state.showsTrack, let track = state.track { MusicArtwork(coordinator: coordinator, track: track).frame(width: 48, height: 48) }
            VStack(alignment: .leading, spacing: 4) { content }
            Spacer(minLength: 0)
            Button { coordinator.computerTapped() } label: {
                Image(systemName: "xmark").frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("Close music")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(12)
        .frame(width: 320)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var content: some View {
        if state.showsTrack, let track = state.track {
            trackText(track).opacity(state.connection == .connected ? 1 : 0.6)
            if state.connection == .connected { controls(track) }
        } else if let message = state.message {
            Text(message)
        }
        if state.connection == .notInstalled {
            Link(state.actionTitle!, destination: MusicState.getSpotifyURL).font(.callout.bold())
        } else if let title = state.actionTitle {
            action(title)
        }
    }

    private func action(_ title: String) -> some View {
        Button(title) { coordinator.musicPrimaryAction() }
            .font(.callout.bold())
            .frame(minHeight: 44)
    }

    private func trackText(_ track: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(track.title).font(.headline).lineLimit(1)
            Text(track.artist).font(.subheadline).opacity(0.7).lineLimit(1)
        }
    }

    private func controls(_ track: NowPlaying) -> some View {
        HStack(spacing: 0) {
            button("backward.fill", "Previous track") { coordinator.musicPrevious() }
            button(track.isPaused ? "play.fill" : "pause.fill", track.isPaused ? "Play" : "Pause") { coordinator.musicTogglePlayPause() }
            button("forward.fill", "Next track") { coordinator.musicNext() }
        }
    }

    private func button(_ symbol: String, _ label: String, _ run: @escaping () -> Void) -> some View {
        Button(action: run) { Image(systemName: symbol).frame(width: 44, height: 44).contentShape(Rectangle()) }
            .accessibilityLabel(label)
    }
}

/// Texts shared by `MusicCard` and `MusicSkinOverlay` so the two cannot drift apart.
extension MusicState {
    static let getSpotifyURL = URL(string: "https://apps.apple.com/app/id324684580")!

    var showsTrack: Bool { track != nil && (connection == .connected || connection == .dropped) }

    /// Status line for states that show no track; nil when the track is shown.
    var message: String? {
        switch connection {
        case .notConfigured: "Spotify isn't set up in this build"
        case .notInstalled: "Spotify isn't installed"
        case .neverConnected: "Connect Spotify"
        case .connecting: "Connecting…"
        case .connected: track == nil ? "Nothing playing" : nil
        case .dropped: track == nil ? "Spotify is paused" : nil
        case .needsReconnect: "Reconnect Spotify"
        }
    }

    /// The one text button; for `.notInstalled` it is a link to the App Store, otherwise it calls `musicPrimaryAction`.
    var actionTitle: String? {
        switch connection {
        case .notInstalled: "Get Spotify"
        case .neverConnected: "Connect Spotify"
        case .dropped: "Resume in Spotify"
        case .needsReconnect: "Reconnect Spotify"
        default: nil
        }
    }
}

/// The cover exactly as Spotify provides it: never altered or covered. Rounded corners only.
struct MusicArtwork: View {
    let coordinator: SceneCoordinator
    let track: NowPlaying
    var cornerRadius: CGFloat = 8
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() } else {
                Image(systemName: "music.note").foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity, maxHeight: .infinity).background(.white.opacity(0.1))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: "\(track.imageID ?? "")|\(coordinator.musicState.connection == .connected)") { await load() }
    }

    /// A cover may land only if its load was not cancelled and its track is still the current one.
    static func shouldApply(requested: String?, current: String?, cancelled: Bool) -> Bool { !cancelled && requested == current }

    private func load() async {
        image = nil
        let loaded = await coordinator.loadArtwork(for: track, size: CGSize(width: 192, height: 192))
        if Self.shouldApply(requested: track.imageID, current: coordinator.musicState.track?.imageID, cancelled: Task.isCancelled) { image = loaded }
    }
}
