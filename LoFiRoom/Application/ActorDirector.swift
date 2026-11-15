import Foundation

/// Plays a node's pack routines and tap reaction, one at a time and never mid-gesture. Everything comes from the manifest.
@MainActor
final class ActorDirector {
    private struct AnyRandom: RandomNumberGenerator {
        var base: any RandomNumberGenerator
        mutating func next() -> UInt64 { base.next() }
    }

    private let node: PackSpriteNode
    private let delay: ClosedRange<TimeInterval>
    private let timers: TimerScheduling
    private let clock: () -> TimeInterval
    private let speed: Double
    private var random: AnyRandom
    private let present: (LoadedPack) -> Void
    private var pack: LoadedPack?
    private var scheduler: RoutineScheduler?
    private var routineTimer: Cancellable?
    private(set) var isActive = false

    init(node: PackSpriteNode, delay: ClosedRange<TimeInterval>, timers: TimerScheduling,
         clock: @escaping () -> TimeInterval, speed: Double = 1,
         random: any RandomNumberGenerator = SystemRandomNumberGenerator(),
         present: @escaping (LoadedPack) -> Void) {
        self.node = node
        self.delay = delay
        self.timers = timers
        self.clock = clock
        self.speed = speed
        self.random = AnyRandom(base: random)
        self.present = present
        node.timers = timers
        node.clock = clock
    }

    func setActive(_ active: Bool) {
        isActive = active
        if active { scheduleNext() } else { cancelTimer() }
    }

    func show(_ pack: LoadedPack) {
        whenInterruptible { [self] in
            self.pack = pack
            present(pack)
            scheduler = RoutineScheduler(config: .from(pack.manifest, delay: delay))
            scheduleNext()
        }
    }

    func tapped() {
        guard let pack,
              let tap = pack.manifest.animations?.filter({ $0.value.onTap == true }).keys.sorted().first,
              !(node.isPlayingOneShot && node.currentAnimation == tap) else { return }
        whenInterruptible { [self] in
            cancelTimer()
            let before = node.currentAnimation
            let resumes = node.pack?.manifest.id == pack.manifest.id && before.map { pack.manifest.animations?[$0]?.loop != false } == true
            node.play(tap) { [self] in
                if resumes, let before { node.show(pack, animation: before) } else { present(pack) }
                scheduleNext()
            }
        }
    }

    private func whenInterruptible(_ act: @escaping @MainActor () -> Void) {
        if node.isPlayingOneShot { node.requestExit(then: act) } else { act() }
    }

    private func cancelTimer() {
        routineTimer?.cancel()
        routineTimer = nil
    }

    /// One timer at most; none when inactive or when the pack has no routines.
    private func scheduleNext() {
        cancelTimer()
        guard isActive, let pack, var scheduler, !scheduler.config.routines.isEmpty else { return }
        let (routine, wait) = scheduler.next(now: clock() * speed, random: &random)
        self.scheduler = scheduler
        routineTimer = timers.schedule(after: wait / speed) { [self] in
            routineTimer = nil
            guard let routine else { return scheduleNext() }
            node.play(routine) { [self] in
                present(pack)
                scheduleNext()
            }
        }
    }
}
