import QuartzCore
import SpriteKit

/// Draws whichever character, pet or scenery pack it is given. Swapping replaces textures; the node stays.
final class PackSpriteNode: SKSpriteNode {
    private(set) var pack: LoadedPack?

    /// The animation actually playing; the fallback's name when the requested one is missing.
    private(set) var currentAnimation: String?

    var timers: TimerScheduling = LiveTimers()
    var clock: () -> TimeInterval = CACurrentMediaTime
    private var startTime: TimeInterval = 0
    private var pending: Cancellable?

    /// True while the current animation is a one-shot that has not finished yet.
    var isPlayingOneShot: Bool {
        guard let name = currentAnimation, let animation = pack?.manifest.animations?[name], animation.loop == false else { return false }
        return !ActorTimeline(animation: animation).isFinished(at: clock() - startTime)
    }

    /// Plays a one-shot of the current pack, then calls `next` (the caller decides what follows).
    /// Anything that is not a one-shot there changes nothing and calls `next` at once.
    func play(_ name: String, then next: @escaping @MainActor () -> Void) {
        guard let pack, let animation = pack.manifest.animations?[name], animation.loop == false else { return next() }
        show(pack, animation: name)
        pending = timers.schedule(after: ActorTimeline(animation: animation).duration, next)
    }

    /// Calls `then` when the current animation next reaches a safe exit frame; a newer request replaces it.
    func requestExit(then: @escaping @MainActor () -> Void) {
        pending?.cancel()
        pending = nil
        guard let pack, let name = currentAnimation, let animation = pack.manifest.animations?[name] else { return then() }
        let elapsed = clock() - startTime
        pending = timers.schedule(after: ActorTimeline(animation: animation).nextSafeExit(after: elapsed) - elapsed, then)
    }

    func show(_ pack: LoadedPack) {
        show(pack, animation: pack.manifest.fallbackAnimation ?? "")
    }

    func show(_ pack: LoadedPack, animation name: String) {
        self.pack = pack
        currentAnimation = pack.manifest.animations?[name] != nil ? name : pack.manifest.fallbackAnimation
        removeAllActions()
        pending?.cancel()
        pending = nil
        startTime = clock()
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
            let animate = SKAction.animate(with: frames, timePerFrame: 1 / animation.fps, resize: false, restore: false)
            run(animation.loop == false ? animate : .repeatForever(animate))
        }
    }
}
