import SpriteKit

/// The room, built from independent layers. No per-frame logic, no physics.
///
/// Draw order (zPosition), back to front:
///   scenery     city seen through the window; future rain and trains go in this group
///   room        fixed room art; its glass is transparent, so it is the window mask for everything behind it
///   actors      character, then pet
///   foreground  room pieces in front of the actors (the chair back)
///   objects     in-world objects: the clock
///   debug       anchor overlay
final class LoFiSKScene: SKScene {
    enum Layer: CGFloat { case scenery = 0, room = 10, actors = 20, foreground = 30, objects = 40, debug = 100 }

    let manifest: ScenePack
    /// Origin is the canvas' bottom-left corner, so children use manifest coordinates directly.
    private let canvas = SKNode()
    private var groups: [Layer: SKNode] = [:]
    private(set) var pixelScale = 1

    let roomSprite = SKSpriteNode()
    private var roomTextures: [String: SKTexture] = [:]
    private var rainSprite: SKSpriteNode?
    private var rainFrames: [SKTexture] = []
    private var reduceMotion = false
    private(set) var applied: ResolvedScene?
    /// 0 when there is no rain effect or it is not raining.
    private(set) var rainFramesPerSecond: Double = 0

    let scenery = PackSpriteNode()
    let character = PackSpriteNode()
    let pet = PackSpriteNode()
    let clock = PixelClockNode()

    init(repository: SpriteAssetRepository, showAnchors: Bool) throws {
        manifest = repository.scene
        super.init(size: CGSize(width: manifest.canvas.w, height: manifest.canvas.h))
        scaleMode = .resizeFill
        backgroundColor = .black
        addChild(canvas)
        for layer in [Layer.scenery, .room, .actors, .foreground, .objects, .debug] {
            let group = SKNode()
            group.zPosition = layer.rawValue
            canvas.addChild(group)
            groups[layer] = group
        }

        for file in Set((manifest.rooms ?? [:]).values).union([manifest.room]) {
            roomTextures[file] = try repository.sceneTexture(file)
        }
        roomSprite.texture = roomTextures[manifest.room]
        roomSprite.size = roomSprite.texture!.size()
        roomSprite.anchorPoint = .zero
        groups[.room]!.addChild(roomSprite)
        for piece in manifest.foreground {
            let node = SKSpriteNode(texture: try repository.sceneTexture(piece.image))
            node.anchorPoint = .zero
            node.position = point(piece.anchor)
            groups[.foreground]!.addChild(node)
        }
        groups[.scenery]!.addChild(scenery)
        if let rain = manifest.rain {
            let sheet = try repository.sceneTexture(rain.sheet)
            rainFrames = SpriteAssetRepository.frames(of: sheet, count: Int(sheet.size().width) / rain.frame.w)
            let node = SKSpriteNode(texture: rainFrames.first, size: CGSize(width: rain.frame.w, height: rain.frame.h))
            node.anchorPoint = .zero
            node.position = point(rain.anchor)
            node.zPosition = 1
            node.isHidden = true
            groups[.scenery]!.addChild(node)
            rainSprite = node
        }
        groups[.actors]!.addChild(character)
        pet.zPosition = 1
        groups[.actors]!.addChild(pet)
        groups[.objects]!.addChild(clock)
        if showAnchors { addAnchorOverlay() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Called after every layout, so overlays can follow the canvas.
    var onLayout: (() -> Void)?

    /// A manifest hotspot in the SKView's UIKit coordinates (points, origin top-left); nil if unknown or not in a view.
    func viewRect(forHotspot name: String) -> CGRect? {
        guard let view, let h = manifest.hotspots?[name], let w = h.w, let height = h.h else { return nil }
        func toView(_ x: Int, _ y: Int) -> CGPoint { convertPoint(toView: canvas.convert(CGPoint(x: x, y: y), to: self)) }
        let a = toView(h.x, h.y), b = toView(h.x + w, h.y + height)
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    override func didMove(to view: SKView) { layout() }
    override func didChangeSize(_ oldSize: CGSize) { layout() }

    /// Puts a loaded pack on screen, routed by its type. The room and the other packs are untouched.
    func show(_ pack: LoadedPack) {
        let position = point(pack.manifest.anchor)
        switch pack.manifest.type {
        case "character":
            character.position = position
            character.show(pack)
        case "pet":
            pet.position = position
            pet.show(pack)
        case "scenery":
            scenery.position = position
            if let applied, let name = pack.manifest.animation(forPhase: applied.phase) {
                scenery.show(pack, animation: name)
            } else {
                scenery.show(pack)
            }
        case "clock":
            clock.position = position
            clock.use(pack)
        default:
            break
        }
    }

    /// Swaps state in place: room texture, rain on or off, scenery picture. Never adds or removes nodes.
    func apply(_ resolved: ResolvedScene, reduceMotion: Bool) {
        guard resolved != applied || reduceMotion != self.reduceMotion else { return }
        applied = resolved
        self.reduceMotion = reduceMotion
        roomSprite.texture = roomTextures[manifest.roomImage(for: resolved)]
        if let rain = manifest.rain, let rainSprite, resolved.sky == .rain {
            rainFramesPerSecond = reduceMotion ? rain.fps / 2 : rain.fps
            rainSprite.isHidden = false
            rainSprite.removeAllActions()
            rainSprite.run(.repeatForever(.animate(with: rainFrames, timePerFrame: 1 / rainFramesPerSecond, resize: false, restore: false)))
        } else {
            rainFramesPerSecond = 0
            rainSprite?.isHidden = true
            rainSprite?.removeAllActions()
        }
        if let pack = scenery.pack, let name = pack.manifest.animation(forPhase: resolved.phase), name != scenery.currentAnimation {
            scenery.show(pack, animation: name)
        }
    }

    private func point(_ id: String) -> CGPoint {
        // Anchor IDs are validated when the scene and each pack load.
        let a = manifest.anchors[id]!
        return CGPoint(x: a.x, y: a.y)
    }

    /// Debug: safe rectangle in green, anchors in magenta.
    private func addAnchorOverlay() {
        func mark(_ a: ScenePack.Anchor, _ color: SKColor) {
            let size = CGSize(width: a.w ?? 3, height: a.h ?? 3)
            let node = SKSpriteNode(color: color.withAlphaComponent(a.w == nil ? 1 : 0.3), size: size)
            node.anchorPoint = a.w == nil ? CGPoint(x: 0.5, y: 0.5) : .zero
            node.position = CGPoint(x: a.x, y: a.y)
            groups[.debug]!.addChild(node)
        }
        mark(manifest.safe, .green)
        manifest.anchors.values.forEach { mark($0, .magenta) }
    }

    /// Integer-scales the canvas and centres it on a whole device pixel.
    private func layout() {
        guard let view else { return }
        let pixelsPerPoint = view.traitCollection.displayScale
        pixelScale = ScalePolicy.integerScale(
            viewPixels: CGSize(width: size.width * pixelsPerPoint, height: size.height * pixelsPerPoint),
            safe: CGSize(width: manifest.safe.w ?? 0, height: manifest.safe.h ?? 0))
        let scale = CGFloat(pixelScale) / pixelsPerPoint
        canvas.setScale(scale)
        func snap(_ v: CGFloat) -> CGFloat { (v * pixelsPerPoint).rounded() / pixelsPerPoint }
        canvas.position = CGPoint(x: snap((size.width - CGFloat(manifest.canvas.w) * scale) / 2),
                                  y: snap((size.height - CGFloat(manifest.canvas.h) * scale) / 2))
        onLayout?()
    }
}
