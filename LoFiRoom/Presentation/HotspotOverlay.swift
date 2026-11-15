import SwiftUI

/// Invisible tap areas over the room, one per manifest hotspot. Same coordinate space as the SKView.
struct HotspotOverlay: View {
    @ObservedObject var coordinator: SceneCoordinator
    private let debug = UserDefaults.standard.bool(forKey: "debugAnchors")

    private static let labels = ["pet": "Pet", "lamp": "Desk lamp", "window": "Window", "computer": "Computer"]

    var body: some View {
        // Smaller frames last, so they are on top (the pet sits inside the window).
        let entries = coordinator.hotspotFrames.sorted { $0.value.width * $0.value.height > $1.value.width * $1.value.height }
        ZStack(alignment: .topLeading) {
            ForEach(entries, id: \.key) { name, frame in
                Button { coordinator.tapped(hotspot: name) } label: {
                    Color.clear.contentShape(Rectangle())
                        .overlay { if debug { Rectangle().stroke(.yellow, lineWidth: 1) } }
                }
                .buttonStyle(.plain)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
                .accessibilityLabel(Self.labels[name] ?? name)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
    }
}
