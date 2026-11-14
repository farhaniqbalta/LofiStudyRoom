import CoreGraphics

/// Largest whole-number scale at which the safe scene fits the view, in device pixels.
/// Anything the canvas does not cover is letterboxed; the room is never re-composed.
enum ScalePolicy {
    static func integerScale(viewPixels: CGSize, safe: CGSize) -> Int {
        max(1, Int(min(viewPixels.width / safe.width, viewPixels.height / safe.height)))
    }
}
