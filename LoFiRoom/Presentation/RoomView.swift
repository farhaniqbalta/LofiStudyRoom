import SwiftUI

struct RoomView: View {
    @StateObject private var coordinator = SceneCoordinator.live()

    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneContainer(coordinator: coordinator)
            HotspotOverlay(coordinator: coordinator)
            if coordinator.musicPanelVisible {
                Button { coordinator.computerTapped() } label: {
                    Text("Music coming soon")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Music coming soon")
                .padding(24)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .background(.black)
    }
}
