import SwiftUI

/// Now-playing card for the Spotify remote. Static: nothing animates, nothing polls.
struct MusicCard: View {
    @ObservedObject var coordinator: SceneCoordinator
    @State private var artwork: UIImage?

    private var state: MusicState { coordinator.musicState }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if showsTrack { art }
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
        .task(id: state.track?.imageID) { await loadArtwork() }
    }

    private var showsTrack: Bool { state.track != nil && (state.connection == .connected || state.connection == .dropped) }

    @ViewBuilder private var content: some View {
        switch state.connection {
        case .notConfigured: Text("Spotify isn't set up in this build")
        case .notInstalled:
            Text("Spotify isn't installed")
            Link("Get Spotify", destination: URL(string: "https://apps.apple.com/app/id324684580")!).font(.callout.bold())
        case .neverConnected: Text("Connect Spotify"); action("Connect Spotify")
        case .connecting: Text("Connecting…")
        case .connected:
            if let track = state.track { trackText(track); controls(track) } else { Text("Nothing playing") }
        case .dropped:
            if let track = state.track { trackText(track).opacity(0.6) } else { Text("Spotify is paused") }
            action("Resume in Spotify")
        case .needsReconnect: Text("Reconnect Spotify"); action("Reconnect Spotify")
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

    private var art: some View {
        Group {
            if let artwork { Image(uiImage: artwork).resizable() } else {
                Image(systemName: "music.note").foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity, maxHeight: .infinity).background(.white.opacity(0.1))
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadArtwork() async {
        artwork = nil
        guard let track = state.track, let adapter = coordinator.musicRemote as? SpotifyRemoteAdapter else { return }
        artwork = await withCheckedContinuation { continuation in
            adapter.artwork(for: track, size: CGSize(width: 96, height: 96)) { continuation.resume(returning: $0) }
        }
    }
}
