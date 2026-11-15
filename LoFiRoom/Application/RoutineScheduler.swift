import Foundation

struct RoutineConfig: Equatable {
    var routines: [String: RoutineSpec]
    var delay: ClosedRange<TimeInterval>

    /// Routines are the pack's animations that carry a `routine` spec.
    static func from(_ pack: SpritePack, delay: ClosedRange<TimeInterval>) -> RoutineConfig {
        RoutineConfig(routines: (pack.animations ?? [:]).compactMapValues(\.routine), delay: delay)
    }

    // Pacing is not art, so it lives in code.
    static let characterDelay: ClosedRange<TimeInterval> = 90...240
    static let petDelay: ClosedRange<TimeInterval> = 60...180
}

struct RoutineScheduler {
    let config: RoutineConfig
    private var lastPlayed: [String: TimeInterval] = [:]

    init(config: RoutineConfig) { self.config = config }

    /// Picks a delay uniformly in `config.delay`, then a routine by weight among those whose cooldown
    /// has passed at `now + delay`, and records it as played at that time. `routine` is nil when all are cooling down.
    mutating func next(now: TimeInterval, random: inout some RandomNumberGenerator) -> (routine: String?, delay: TimeInterval) {
        let delay = TimeInterval.random(in: config.delay, using: &random)
        let at = now + delay
        let ready = config.routines.keys.sorted().filter {
            let spec = config.routines[$0]!
            return spec.weight > 0 && lastPlayed[$0].map { at - $0 >= spec.cooldown } ?? true
        }
        var pick = Double.random(in: 0..<max(ready.reduce(0) { $0 + config.routines[$1]!.weight }, .leastNonzeroMagnitude), using: &random)
        for name in ready {
            pick -= config.routines[name]!.weight
            if pick < 0 {
                lastPlayed[name] = at
                return (name, delay)
            }
        }
        return (nil, delay)
    }
}
