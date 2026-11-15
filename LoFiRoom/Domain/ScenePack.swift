import Foundation

struct PixelSize: Codable, Equatable { var w: Int, h: Int }
struct PixelPoint: Codable, Equatable { var x: Int, y: Int }

/// The room: canvas, safe area, anchors and fixed art. Logical pixels, origin bottom-left.
/// Packs refer to anchors by ID only and are placed with their bottom-left corner on the anchor.
struct ScenePack: Codable, Equatable {
    struct Anchor: Codable, Equatable { var x: Int, y: Int, w: Int?, h: Int? }
    struct Foreground: Codable, Equatable { var image: String, anchor: String }
    /// A looping one-row sheet drawn behind the room's glass (rain).
    struct Effect: Codable, Equatable { var sheet: String; var frame: PixelSize; var fps: Double; var anchor: String }

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

    static let requiredAnchors = ["desk-seat", "pet-spot", "clock-slot", "lamp", "computer", "window-rect", "window-mask"]

    func roomImage(for scene: ResolvedScene) -> String {
        rooms?["\(scene.phase.rawValue)-\(scene.lampOn ? "on" : "off")"] ?? room
    }

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
        problems += foreground.filter { anchors[$0.anchor] == nil }.map { "foreground '\($0.image)' uses unknown anchor '\($0.anchor)'" }
        return problems.sorted()
    }
}
