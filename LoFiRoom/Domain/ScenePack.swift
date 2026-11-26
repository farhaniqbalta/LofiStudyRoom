import Foundation

struct PixelSize: Codable, Equatable { var w: Int, h: Int }
struct PixelPoint: Codable, Equatable { var x: Int, y: Int }

/// An optional pixel-art music player: sprites drawn in the room, with text and cover art laid over its slots.
struct MusicSkin: Codable, Equatable {
    struct Icons: Codable, Equatable { var sheet: String; var frame: PixelSize; var names: [String] }
    var panel: String
    var frame: ScenePack.Anchor
    var icons: Icons
    var slots: [String: ScenePack.Anchor]
    var textColor: String
    var dimColor: String
    var notes: ScenePack.Effect?
    static let requiredSlots = ["artwork", "title", "artist", "attribution", "previous", "toggle", "next", "close", "message", "action"]
    static let requiredIcons = ["previous", "play", "pause", "next", "close"]
}

/// The room: canvas, safe area, anchors and fixed art. Logical pixels, origin bottom-left.
/// Packs refer to anchors by ID only and are placed with their bottom-left corner on the anchor.
struct ScenePack: Codable, Equatable {
    struct Anchor: Codable, Equatable { var x: Int, y: Int, w: Int?, h: Int? }
    struct Foreground: Codable, Equatable { var image: String, anchor: String }
    /// A looping one-row sheet drawn behind the room's glass (rain).
    struct Effect: Codable, Equatable { var sheet: String; var frame: PixelSize; var fps: Double; var anchor: String }
    /// How much the character and pet take on a colour (multiplied in), so actors drawn under one light match the room.
    struct Tint: Codable, Equatable {
        var color: String
        var amount: Double
        /// `#RRGGBB` as 0...255 components; nil when malformed.
        var rgb: (r: Int, g: Int, b: Int)? {
            guard color.count == 7, color.hasPrefix("#"), let v = Int(color.dropFirst(), radix: 16) else { return nil }
            return (v >> 16 & 255, v >> 8 & 255, v & 255)
        }
    }

    var id: String
    var perspective: String
    var canvas: PixelSize
    var safe: Anchor
    var anchors: [String: Anchor]
    var room: String
    /// Room pieces drawn in front of the actors (the chair back), so bodies are occluded by real layers.
    var foreground: [Foreground]
    /// "<phase>-<on|off>" to image file; a missing key falls back to `room`.
    var rooms: [String: String]?
    var rain: Effect?
    var hotspots: [String: Anchor]?
    var music: MusicSkin?
    /// "<phase>-<on|off>" to an actor tint; a missing key means no tint.
    var actorTints: [String: Tint]?

    static let requiredAnchors = ["desk-seat", "pet-spot", "clock-slot", "lamp", "computer", "window-rect", "window-mask"]

    static func stateKey(_ scene: ResolvedScene) -> String { "\(scene.phase.rawValue)-\(scene.lampOn ? "on" : "off")" }

    func roomImage(for scene: ResolvedScene) -> String { rooms?[Self.stateKey(scene)] ?? room }

    func actorTint(for scene: ResolvedScene) -> Tint? { actorTints?[Self.stateKey(scene)] }

    /// Human-readable problems; empty means valid.
    func problems() -> [String] {
        var problems = Self.requiredAnchors.filter { anchors[$0] == nil }.map { "missing anchor '\($0)'" }
        // Anchors must stay inside the safe rectangle: the only area visible on every iPad shape.
        let maxX = safe.x + (safe.w ?? 0), maxY = safe.y + (safe.h ?? 0)
        func outside(_ a: Anchor) -> Bool { a.x < safe.x || a.y < safe.y || a.x + (a.w ?? 0) > maxX || a.y + (a.h ?? 0) > maxY }
        for (id, a) in anchors where outside(a) { problems.append("anchor '\(id)' is outside the safe area") }
        if let rain, anchors[rain.anchor] == nil { problems.append("rain uses unknown anchor '\(rain.anchor)'") }
        for (name, h) in hotspots ?? [:] {
            if h.w == nil || h.h == nil { problems.append("hotspot '\(name)' needs a width and height") }
            if outside(h) { problems.append("hotspot '\(name)' is outside the safe area") }
        }
        if let music {
            if outside(music.frame) { problems.append("music frame is outside the safe area") }
            let f = music.frame
            for name in MusicSkin.requiredSlots {
                guard let s = music.slots[name] else { problems.append("music is missing slot '\(name)'"); continue }
                if s.w == nil || s.h == nil { problems.append("music slot '\(name)' needs a width and height") }
                if s.x < f.x || s.y < f.y || s.x + (s.w ?? 0) > f.x + (f.w ?? 0) || s.y + (s.h ?? 0) > f.y + (f.h ?? 0) {
                    problems.append("music slot '\(name)' is outside the music frame")
                }
            }
            problems += MusicSkin.requiredIcons.filter { !music.icons.names.contains($0) }.map { "music is missing icon '\($0)'" }
            if music.icons.frame.w <= 0 || music.icons.frame.h <= 0 { problems.append("music icons frame needs a positive width and height") }
            if let notes = music.notes {
                if notes.frame.w <= 0 || notes.frame.h <= 0 { problems.append("music notes frame needs a positive width and height") }
                if notes.fps <= 0 { problems.append("music notes need a positive fps") }
            }
            if let notes = music.notes, anchors[notes.anchor] == nil { problems.append("music notes use unknown anchor '\(notes.anchor)'") }
        }
        let stateKeys = Set(["day", "night"].flatMap { p in ["on", "off"].map { "\(p)-\($0)" } })
        for (key, tint) in actorTints ?? [:] {
            if !stateKeys.contains(key) { problems.append("actor tint '\(key)' is not <day|night>-<on|off>") }
            if tint.rgb == nil { problems.append("actor tint '\(key)' color must be #RRGGBB") }
            if !(0...1).contains(tint.amount) { problems.append("actor tint '\(key)' amount must be between 0 and 1") }
        }
        problems += foreground.filter { anchors[$0.anchor] == nil }.map { "foreground '\($0.image)' uses unknown anchor '\($0.anchor)'" }
        return problems.sorted()
    }
}
