import Foundation

/// Pure frame/time arithmetic for one animation; no SpriteKit.
struct ActorTimeline {
    private let frames: [Int]
    private let fps: Double
    private let loops: Bool
    private let safe: Set<Int>

    init(animation: SpritePack.Animation) {
        frames = animation.frames
        fps = animation.fps
        loops = animation.loop != false
        let declared = Set(animation.safeExits ?? []).intersection(animation.frames)
        // A loop (or nil list) with no usable safe exit treats every frame as safe.
        safe = animation.safeExits == nil || (loops && declared.isEmpty) ? Set(animation.frames) : declared
    }

    var duration: TimeInterval { Double(frames.count) / fps }

    private func slot(at elapsed: TimeInterval) -> Int { Int(max(elapsed, 0) * fps + 1e-9) }

    func frameIndex(at elapsed: TimeInterval) -> Int {
        let s = slot(at: elapsed)
        return frames[loops ? s % frames.count : min(s, frames.count - 1)]
    }

    func isFinished(at elapsed: TimeInterval) -> Bool { !loops && elapsed >= duration }

    func nextSafeExit(after elapsed: TimeInterval) -> TimeInterval {
        var s = slot(at: elapsed)
        // A one-shot with no safe frame left (or past its end) exits at the end.
        while loops || s < frames.count {
            if safe.contains(frames[s % frames.count]) { return Double(s + 1) / fps }
            s += 1
        }
        return duration
    }
}
