import Foundation

/// How often an animation is picked as an idle routine: relative weight and minimum seconds between plays.
struct RoutineSpec: Codable, Equatable { var weight: Double; var cooldown: TimeInterval }

/// Manifest of one swappable pack: a character, pet, scenery or clock skin.
/// The sheet is a single row of equally sized frames.
struct SpritePack: Codable, Equatable {
    struct Animation: Codable, Equatable {
        var frames: [Int]
        var fps: Double
        var routine: RoutineSpec?
        var onTap: Bool?
    }

    var id: String
    var type: String
    var packVersion: Int
    var perspective: String
    var anchor: String
    var sheet: String
    var frame: PixelSize
    var animations: [String: Animation]?
    var fallbackAnimation: String?
    // Clock skins only
    var glyphs: String?
    var bezel: String?
    var slots: [PixelPoint]?

    var isClock: Bool { type == "clock" }

    /// The requested animation, or the pack's fallback when it does not have that one.
    func animation(named name: String) -> Animation? {
        animations?[name] ?? fallbackAnimation.flatMap { animations?[$0] }
    }

    /// Human-readable problems; empty means the pack fits the scene. `sheetSize` is nil when the sheet is missing.
    func problems(folder: String, scene: ScenePack, sheetSize: PixelSize?) -> [String] {
        var problems: [String] = []
        if id != folder.lowercased() { problems.append("id '\(id)' must match its folder name '\(folder)'") }
        if perspective != scene.perspective {
            problems.append("perspective '\(perspective)' does not match the scene's '\(scene.perspective)'")
        }
        if scene.anchors[anchor] == nil { problems.append("unknown anchor '\(anchor)'") }
        guard let sheetSize else { return problems + ["sheet '\(sheet)' is missing or not a readable image"] }
        guard frame.w > 0, frame.h == sheetSize.h, sheetSize.w % frame.w == 0 else {
            return problems + ["sheet is \(sheetSize.w)x\(sheetSize.h), which is not a row of \(frame.w)x\(frame.h) frames"]
        }
        let frameCount = sheetSize.w / frame.w
        if isClock {
            if glyphs?.count != frameCount { problems.append("clock needs one glyph name per frame (\(frameCount))") }
            if slots?.count != 5 { problems.append("clock needs 5 glyph slots (HH:mm)") }
            if bezel == nil { problems.append("clock needs a bezel image") }
            for required in "0123456789:" where glyphs?.contains(required) == false {
                problems.append("clock is missing glyph '\(required)'")
            }
        } else {
            let animations = animations ?? [:]
            if animations.isEmpty { problems.append("no animations") }
            if fallbackAnimation.flatMap({ animations[$0] }) == nil { problems.append("fallbackAnimation is missing or not one of the animations") }
            for (name, animation) in animations {
                if animation.fps <= 0 || animation.frames.isEmpty { problems.append("animation '\(name)' needs frames and a positive fps") }
                for index in animation.frames where !(0..<frameCount).contains(index) {
                    problems.append("animation '\(name)' uses frame \(index) but the sheet has \(frameCount) frames")
                }
            }
        }
        return problems.sorted()
    }
}
