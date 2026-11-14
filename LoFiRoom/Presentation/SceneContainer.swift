import SpriteKit
import SwiftUI

/// Hosts the SpriteKit scene. A wrapped SKView (not SpriteView) so frame rate and pause are directly controllable.
/// Launch arguments: `-fps 12`, `-paused YES`, `-debugAnchors YES` (anchor overlay + FPS counter), and
/// `-character Girl01`, `-pet BlackCat`, `-scenery NeonCity02` to choose packs (the choice is saved).
struct SceneContainer: UIViewRepresentable {
    func makeCoordinator() -> SceneCoordinator {
        let defaults = UserDefaults.standard
        do {
            let repository = try SpriteAssetRepository()
            let scene = try LoFiSKScene(repository: repository, showAnchors: defaults.bool(forKey: "debugAnchors"))
            let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(), scene: scene)
            coordinator.start()
            for (category, argument) in [("Characters", "character"), ("Pets", "pet"), ("Scenery", "scenery")] {
                if let folder = defaults.string(forKey: argument) { coordinator.select(folder, in: category) }
            }
            return coordinator
        } catch {
            // The room itself ships in the bundle; if it cannot load, the build is broken.
            fatalError(error.localizedDescription)
        }
    }

    func makeUIView(context: Context) -> SKView {
        let defaults = UserDefaults.standard
        let view = SKView()
        view.ignoresSiblingOrder = true
        let fps = defaults.integer(forKey: "fps")
        view.preferredFramesPerSecond = fps > 0 ? fps : 30
        view.showsFPS = defaults.bool(forKey: "debugAnchors")
        view.presentScene(context.coordinator.scene)
        // SpriteKit pauses the view itself when the app leaves the foreground.
        view.isPaused = defaults.bool(forKey: "paused")
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {}
}
