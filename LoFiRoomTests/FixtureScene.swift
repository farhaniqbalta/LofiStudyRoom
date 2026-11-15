import UIKit

/// A synthetic, deliberately different scene used to prove the engine does not depend on the bundled art:
/// another canvas size, other anchors, other perspective, other animation names, no optional extras.
enum FixtureScene {
    static let name = "FixtureRoom"
    static let perspective = "fixture-profile-v1"

    /// Writes the fixture packs under `root` (an empty temporary folder) and returns `root`.
    static func make(in root: URL) throws -> URL {
        let anchors: [String: [String: Int]] = [
            "desk-seat": ["x": 200, "y": 40, "w": 20, "h": 30],
            "pet-spot": ["x": 60, "y": 80, "w": 12, "h": 8],
            "clock-slot": ["x": 150, "y": 90, "w": 25, "h": 10],
            "lamp": ["x": 120, "y": 90],
            "computer": ["x": 180, "y": 100],
            "window-rect": ["x": 20, "y": 120, "w": 100, "h": 80],
            "window-mask": ["x": 20, "y": 120, "w": 100, "h": 80],
        ]
        try write(root, "Scenes/\(name)", manifest: [
            "id": "fixtureroom", "perspective": perspective,
            "canvas": ["w": 320, "h": 240], "safe": ["x": 10, "y": 10, "w": 300, "h": 220],
            "anchors": anchors, "room": "room.png", "foreground": [Any](),
        ], images: ["room.png": image(w: 320, h: 240, frames: 1, color: .darkGray)])

        try pack(root, "Characters/Typist", type: "character", anchor: "desk-seat", frame: (20, 30), frames: 3, animations: [
            "type": ["frames": [0], "fps": 1],
            "sip": ["frames": [1], "fps": 1, "loop": false, "routine": ["weight": 1, "cooldown": 10]],
            "lean": ["frames": [2], "fps": 1, "loop": false, "routine": ["weight": 1, "cooldown": 10]],
        ], fallback: "type")
        try pack(root, "Pets/Nappy", type: "pet", anchor: "pet-spot", frame: (12, 8), frames: 2, animations: [
            "nap": ["frames": [0], "fps": 1],
            "purr": ["frames": [1], "fps": 1, "loop": false, "onTap": true],
        ], fallback: "nap")
        try pack(root, "Scenery/Skyline", type: "scenery", anchor: "window-rect", frame: (100, 80), frames: 1, animations: [
            "still": ["frames": [0], "fps": 1],
        ], fallback: "still")
        try write(root, "Clocks/Mini", manifest: [
            "id": "mini", "type": "clock", "packVersion": 1, "perspective": perspective, "anchor": "clock-slot",
            "sheet": "sheet.png", "frame": ["w": 4, "h": 6], "glyphs": "0123456789:", "bezel": "bezel.png",
            "slots": [0, 5, 10, 13, 18].map { ["x": $0 + 1, "y": 2] },
        ], images: ["sheet.png": image(w: 4, h: 6, frames: 11, color: .cyan), "bezel.png": image(w: 25, h: 10, frames: 1, color: .black)])
        return root
    }

    private static func pack(_ root: URL, _ path: String, type: String, anchor: String, frame: (Int, Int), frames: Int,
                             animations: [String: Any], fallback: String) throws {
        try write(root, path, manifest: [
            "id": String(path.split(separator: "/").last!).lowercased(), "type": type, "packVersion": 1,
            "perspective": perspective, "anchor": anchor, "sheet": "sheet.png", "frame": ["w": frame.0, "h": frame.1],
            "animations": animations, "fallbackAnimation": fallback,
        ], images: ["sheet.png": image(w: frame.0, h: frame.1, frames: frames, color: .orange)])
    }

    private static func write(_ root: URL, _ path: String, manifest: [String: Any], images: [String: Data]) throws {
        let folder = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: manifest).write(to: folder.appendingPathComponent("manifest.json"))
        for (file, data) in images { try data.write(to: folder.appendingPathComponent(file)) }
    }

    /// A one-row sheet of solid frames at 1 pixel per point.
    private static func image(w: Int, h: Int, frames: Int, color: UIColor) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w * frames, height: h), format: format).pngData { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: w * frames, height: h))
        }
    }
}
