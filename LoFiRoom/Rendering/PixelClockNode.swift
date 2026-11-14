import SpriteKit

/// The in-world clock: a bezel and five glyph sprites (HH:mm). Only glyphs that changed get a new texture.
final class PixelClockNode: SKNode {
    private let bezel = SKSpriteNode()
    private let digits = (0..<5).map { _ in SKSpriteNode() }
    private var pack: LoadedPack?
    private(set) var text = ""
    /// Number of glyph textures replaced so far; lets tests prove unchanged digits are left alone.
    private(set) var glyphSwaps = 0

    override init() {
        super.init()
        bezel.anchorPoint = .zero
        addChild(bezel)
        for digit in digits {
            digit.anchorPoint = .zero
            digit.zPosition = 1
            addChild(digit)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func use(_ pack: LoadedPack) {
        self.pack = pack
        bezel.texture = pack.bezel
        bezel.size = pack.bezel?.size() ?? .zero
        for (digit, slot) in zip(digits, pack.manifest.slots ?? []) {
            digit.position = CGPoint(x: slot.x, y: slot.y)
            digit.size = CGSize(width: pack.manifest.frame.w, height: pack.manifest.frame.h)
        }
        let current = text
        text = ""
        show(current)
    }

    /// `newText` is "HH:mm". Characters the skin has no glyph for are left blank.
    func show(_ newText: String) {
        guard let pack, let glyphs = pack.manifest.glyphs.map(Array.init) else { return }
        let old = Array(text), new = Array(newText)
        for (index, digit) in digits.enumerated() where index < new.count {
            if index < old.count, old[index] == new[index] { continue }
            digit.texture = glyphs.firstIndex(of: new[index]).map { pack.frames[$0] }
            glyphSwaps += 1
        }
        text = newText
    }
}
