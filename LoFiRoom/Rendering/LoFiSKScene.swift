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

        let room = SKSpriteNode(texture: try repository.sceneTexture(manifest.room))
        room.anchorPoint = .zero
        groups[.room]!.addChild(room)
        for piece in manifest.foreground {
            let node = SKSpriteNode(texture: try repository.sceneTexture(piece.image))
            node.anchorPoint = .zero
            node.position = point(piece.anchor)
            groups[.foreground]!.addChild(node)
        }
        groups[.scenery]!.addChild(scenery)
        groups[.actors]!.addChild(character)
        pet.zPosition = 1
        groups[.actors]!.addChild(pet)
        groups[.objects]!.addChild(clock)
        if showAnchors { addAnchorOverlay() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) { layout() }
    override func didChangeSize(_ oldSize: CGSize) { layout() }

    /// Puts a loaded pack on screen, routed by its type. The room and the other packs are untouched.
    func show(_ pack: LoadedPack) {
        let position = point(pack.manifest.anchor)
        switch pack.manifest.type {
        case "character":
            character.position = position
            character.show(pack, animation: "study")
        case "pet":
            pet.position = position
            pet.show(pack, animation: "sleep")
        case "scenery":
            scenery.position = position
            scenery.show(pack, animation: "idle")
        case "clock":
            clock.position = position
            clock.use(pack)
        default:
            break
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
    }
}
