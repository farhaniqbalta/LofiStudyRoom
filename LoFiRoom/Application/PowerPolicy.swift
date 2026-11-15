import Foundation

enum PowerPolicy {
    static let reducedFramesPerSecond = 15

    /// `requested` normally; capped at 15 when Low Power Mode is on or the thermal state is .serious or .critical.
    static func framesPerSecond(requested: Int, lowPower: Bool, thermal: ProcessInfo.ThermalState) -> Int {
        lowPower || thermal == .serious || thermal == .critical ? min(requested, reducedFramesPerSecond) : requested
    }

    /// The screen is kept awake only while the app is active and the user chose it.
    static func idleTimerDisabled(keepAwake: Bool, active: Bool) -> Bool { keepAwake && active }
}
