import SpriteKit
import SwiftUI

/// Hosts the SpriteKit scene. A wrapped SKView (not SpriteView) so frame rate and pause are directly controllable.
/// `-fps 12`, `-paused YES` and `-debugAnchors YES` (FPS counter) are read here; the other launch arguments are in `SceneCoordinator.live()`.
struct SceneContainer: UIViewRepresentable {
    @ObservedObject var coordinator: SceneCoordinator

    func makeUIView(context: Context) -> SKView {
        let defaults = UserDefaults.standard
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.showsFPS = defaults.bool(forKey: "debugAnchors")
        view.presentScene(coordinator.scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        let defaults = UserDefaults.standard
        let fps = defaults.integer(forKey: "fps")
        view.isPaused = defaults.bool(forKey: "paused") || !coordinator.isActive
        view.preferredFramesPerSecond = PowerPolicy.framesPerSecond(requested: fps > 0 ? fps : 30,
                                                                    lowPower: coordinator.lowPower, thermal: coordinator.thermal)
    }
}
