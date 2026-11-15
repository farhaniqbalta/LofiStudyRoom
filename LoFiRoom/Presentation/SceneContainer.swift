import SpriteKit
import SwiftUI

/// Hosts the SpriteKit scene. A wrapped SKView (not SpriteView) so frame rate and pause are directly controllable.
/// `-fps 12`, `-paused YES` and `-debugAnchors YES` (FPS counter) are read here; the other launch arguments are in `SceneCoordinator.live()`.
struct SceneContainer: UIViewRepresentable {
    let coordinator: SceneCoordinator

    func makeUIView(context: Context) -> SKView {
        let defaults = UserDefaults.standard
        let view = SKView()
        view.ignoresSiblingOrder = true
        let fps = defaults.integer(forKey: "fps")
        view.preferredFramesPerSecond = fps > 0 ? fps : 30
        view.showsFPS = defaults.bool(forKey: "debugAnchors")
        view.presentScene(coordinator.scene)
        // SpriteKit pauses the view itself when the app leaves the foreground.
        view.isPaused = defaults.bool(forKey: "paused")
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {}
}
