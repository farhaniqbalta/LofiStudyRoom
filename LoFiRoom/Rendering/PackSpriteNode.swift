import SpriteKit

/// Draws whichever character, pet or scenery pack it is given. Swapping replaces textures; the node stays.
final class PackSpriteNode: SKSpriteNode {
    private(set) var pack: LoadedPack?

    func show(_ pack: LoadedPack, animation name: String) {
        self.pack = pack
        removeAllActions()
        anchorPoint = .zero
        size = CGSize(width: pack.manifest.frame.w, height: pack.manifest.frame.h)
        guard let animation = pack.manifest.animation(named: name) else {
            texture = pack.frames.first
            return
        }
        let frames = animation.frames.map { pack.frames[$0] }
        texture = frames[0]
        // A one-frame animation is a still: no action, so SpriteKit has nothing to tick.
        if frames.count > 1 {
            run(.repeatForever(.animate(with: frames, timePerFrame: 1 / animation.fps)))
        }
    }
}
