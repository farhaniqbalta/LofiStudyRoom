import SwiftUI
import os

/// SwiftUI content over the slots of the scene's pixel-art music player. The pixel art itself is drawn by SpriteKit.
/// Same coordinate space as `HotspotOverlay`. Nothing animates; the cover is never altered or covered.
struct MusicSkinOverlay: View {
    @ObservedObject var coordinator: SceneCoordinator
    @Environment(\.displayScale) private var displayScale
    private static var warned = false

    /// Spotify's guideline: the logo is never narrower than 70 px.
    static func logoMeetsMinimumWidth(slotWidthPoints: CGFloat, displayScale: CGFloat) -> Bool { slotWidthPoints * displayScale >= 70 }

    private var state: MusicState { coordinator.musicState }

    var body: some View {
        if let skin = coordinator.scene.manifest.music, !coordinator.musicSlotFrames.isEmpty {
            let text = Self.color(skin.textColor), dim = Self.color(skin.dimColor)
            ZStack(alignment: .topLeading) {
                if state.showsTrack, let track = state.track {
                    let faded = state.connection == .connected ? 1.0 : 0.6
                    slot("artwork") { MusicArtwork(coordinator: coordinator, track: track, cornerRadius: 4) }.opacity(faded)
                    slot("title") { line(track.title, "title", text) }.opacity(faded)
                    slot("artist") { line(track.artist, "artist", dim) }.opacity(faded)
                    slot("attribution") {
                        Image("SpotifyLogo").resizable().scaledToFit().accessibilityLabel("Spotify")
                            .onAppear { checkLogoWidth() }
                    }
                    if state.connection == .connected {
                        tap("previous", "Previous track") { coordinator.musicPrevious() }
                        tap("toggle", track.isPaused ? "Play" : "Pause") { coordinator.musicTogglePlayPause() }
                        tap("next", "Next track") { coordinator.musicNext() }
                    }
                } else if let message = state.message {
                    slot("message") {
                        Text(message).font(.system(size: 0.32 * height("message"), design: .monospaced)).foregroundStyle(text)
                            .lineLimit(2).minimumScaleFactor(0.6)
                    }
                }
                if let title = state.actionTitle {
                    if state.connection == .notInstalled {
                        slot("action", padded: true) {
                            Link(title, destination: MusicState.getSpotifyURL).font(.system(size: 0.6 * height("action"), weight: .bold, design: .monospaced))
                                .foregroundStyle(text).minimumScaleFactor(0.6)
                        }
                    } else {
                        tap("action", title, label: Text(title).font(.system(size: 0.6 * height("action"), weight: .bold, design: .monospaced))
                            .foregroundStyle(text).lineLimit(1).minimumScaleFactor(0.6)) { coordinator.musicPrimaryAction() }
                    }
                }
                tap("close", "Close music") { coordinator.computerTapped() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .ignoresSafeArea()
        }
    }

    private func checkLogoWidth() {
        let width = coordinator.musicSlotFrames["attribution"]?.width ?? 0
        guard !Self.logoMeetsMinimumWidth(slotWidthPoints: width, displayScale: displayScale), !Self.warned else { return }
        Self.warned = true
        Logger(subsystem: "com.lofiroom.app", category: "music").warning("Spotify logo is \(width * displayScale, privacy: .public) px wide, below the 70 px minimum")
    }

    private func height(_ name: String) -> CGFloat { coordinator.musicSlotFrames[name]?.height ?? 0 }

    private func line(_ string: String, _ name: String, _ color: Color) -> some View {
        Text(string).font(.system(size: 0.75 * height(name), design: .monospaced)).foregroundStyle(color)
            .lineLimit(1).minimumScaleFactor(0.6).truncationMode(.tail)
    }

    /// Visuals stay in the slot; a tap target is padded to at least 44 pt around it.
    private func slot<V: View>(_ name: String, padded: Bool = false, @ViewBuilder _ content: () -> V) -> some View {
        let f = coordinator.musicSlotFrames[name] ?? .zero
        let r = padded ? SceneCoordinator.tapFrame(f) : f
        return content().frame(width: r.width, height: r.height, alignment: .leading).offset(x: r.minX, y: r.minY)
    }

    private func tap<L: View>(_ name: String, _ accessibility: String, label: L = Color.clear, _ run: @escaping () -> Void) -> some View {
        slot(name, padded: true) {
            Button(action: run) {
                ZStack(alignment: .leading) { Color.clear; label }.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibility)
        }
    }

    /// `#RRGGBB`; anything else is white.
    private static func color(_ hex: String) -> Color {
        guard hex.count == 7, hex.hasPrefix("#"), let v = UInt32(hex.dropFirst(), radix: 16) else { return .white }
        return Color(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255)
    }
}
