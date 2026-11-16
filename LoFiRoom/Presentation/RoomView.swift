import SwiftUI

struct RoomView: View {
    @StateObject private var coordinator = SceneCoordinator.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneContainer(coordinator: coordinator)
            Color.clear.contentShape(Rectangle())
                .onTapGesture { coordinator.revealControls() }
                .accessibilityHidden(true)
            HotspotOverlay(coordinator: coordinator)
            if UserDefaults.standard.bool(forKey: "debugAnchors") {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let a = coordinator.scene.applied
                    Text("weather: \(String(describing: coordinator.weatherStatus)) · \(a?.phase.rawValue ?? "-") · \(a?.sky.rawValue ?? "-") · lamp \(a?.lampOn == true ? "on" : "off") · music: \(String(describing: coordinator.musicState.connection)) · cover: \(coordinator.artworkStatus ?? "ok or not asked")")
                        .font(.caption.monospaced()).foregroundStyle(.white)
                        .padding(4).background(.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .allowsHitTesting(false)
            }
            if coordinator.musicPanelVisible {
                if coordinator.hasMusicSkin {
                    MusicSkinOverlay(coordinator: coordinator)
                } else {
                    MusicCard(coordinator: coordinator)
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            Button { coordinator.panelVisible = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .opacity(coordinator.controlsVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: coordinator.controlsVisible)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Room settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(8)
        }
        .sheet(isPresented: $coordinator.panelVisible) { CustomizationSheet(coordinator: coordinator) }
        .onOpenURL { coordinator.handleCallback($0) }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .background(.black)
        .onChange(of: scenePhase) { _, phase in coordinator.setActive(phase == .active) }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in powerChanged() }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in powerChanged() }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)) { _ in
            coordinator.applyEnvironment()
        }
        .onChange(of: coordinator.config.keepAwake) { updateIdleTimer() }
        .onChange(of: coordinator.isActive) { updateIdleTimer() }
        .onAppear { updateIdleTimer() }
    }

    private func powerChanged() {
        let info = ProcessInfo.processInfo
        coordinator.powerStateChanged(lowPower: info.isLowPowerModeEnabled, thermal: info.thermalState)
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = PowerPolicy.idleTimerDisabled(keepAwake: coordinator.config.keepAwake, active: coordinator.isActive)
    }
}
