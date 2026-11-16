import Foundation

enum RainSoundMode: String, Codable, CaseIterable { case off, whenRaining, always }

enum AmbientSound {
    static func shouldPlay(mode: RainSoundMode, sky: Sky, active: Bool) -> Bool {
        guard active else { return false }
        switch mode {
        case .off: return false
        case .always: return true
        case .whenRaining: return sky == .rain
        }
    }
}
