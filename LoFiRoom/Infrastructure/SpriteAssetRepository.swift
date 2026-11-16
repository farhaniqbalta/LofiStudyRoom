import SpriteKit
import UIKit

struct PackError: LocalizedError, Equatable {
    var errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

/// A pack ready to draw. Textures are owned by whoever holds this, so a replaced pack is freed with its node.
struct LoadedPack {
    var manifest: SpritePack
    var frames: [SKTexture]
    var bezel: SKTexture?
}

/// Reads packs from `Assets/<Category>/<Folder>/` in the bundle and validates them against the scene.
@MainActor
final class SpriteAssetRepository {
    let root: URL
    let scene: ScenePack
    private let sceneFolder: URL

    /// `art-sets.json` beside the packs: which art sets exist (A, B, ...) and which one is active.
    private struct ArtSets: Decodable {
        struct Entry: Decodable { var scene: String }
        var active: String
        var sets: [String: Entry]
    }

    /// The scene is, in order: `sceneName`; the scene of `artSet`; the scene of the registry's active set;
    /// the first scene folder (roots without a registry, such as test fixtures).
    init(root: URL = Bundle.main.resourceURL!.appendingPathComponent("Assets"), sceneName: String? = nil, artSet: String? = nil) throws {
        self.root = root
        // A missing registry is allowed (test fixtures); one that exists but cannot be decoded is an error.
        var registry: ArtSets?
        if let data = try? Data(contentsOf: root.appendingPathComponent("art-sets.json")) {
            do { registry = try JSONDecoder().decode(ArtSets.self, from: data) } catch { throw PackError("art-sets.json is invalid (\(error))") }
        }
        var registered: String?
        if let key = artSet ?? registry?.active {
            guard let entry = registry?.sets[key] else { throw PackError("art-sets.json has no art set '\(key)'") }
            registered = entry.scene
        }
        let sceneName = try sceneName ?? registered ?? FileManager.default
            .contentsOfDirectory(at: root.appendingPathComponent("Scenes"), includingPropertiesForKeys: nil)
            .filter(\.hasDirectoryPath).map(\.lastPathComponent).min() ?? { throw PackError("Scenes: no scene folder found") }()
        sceneFolder = root.appendingPathComponent("Scenes/\(sceneName)")
        scene = try Self.decode(ScenePack.self, in: sceneFolder, label: "Scenes/\(sceneName)")
        let problems = scene.problems()
        if !problems.isEmpty { throw PackError("Scenes/\(sceneName): " + problems.joined(separator: "; ")) }
    }

    /// Folder names of the packs in a category, sorted.
    func folders(in category: String) -> [String] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: root.appendingPathComponent(category), includingPropertiesForKeys: nil)) ?? []
        return urls.filter { url in
            url.hasDirectoryPath
                && (try? Self.decode(SpritePack.self, in: url, label: ""))?.perspective == scene.perspective
        }.map(\.lastPathComponent).sorted()
    }

    func sceneTexture(_ file: String) throws -> SKTexture {
        guard let texture = Self.texture(at: sceneFolder.appendingPathComponent(file)) else {
            throw PackError("Scenes: image '\(file)' is missing or not a readable image")
        }
        return texture
    }

    func load(_ category: String, _ folder: String) throws -> LoadedPack {
        let label = "\(category)/\(folder)"
        let directory = root.appendingPathComponent(label)
        let manifest = try Self.decode(SpritePack.self, in: directory, label: label)
        let sheet = Self.texture(at: directory.appendingPathComponent(manifest.sheet))
        let sheetSize = sheet.map { PixelSize(w: Int($0.size().width), h: Int($0.size().height)) }
        let problems = manifest.problems(folder: folder, scene: scene, sheetSize: sheetSize)
        guard problems.isEmpty, let sheet, let sheetSize else { throw PackError("\(label): " + problems.joined(separator: "; ")) }

        let frames = Self.frames(of: sheet, count: sheetSize.w / manifest.frame.w)
        var bezel: SKTexture?
        if let file = manifest.bezel {
            bezel = Self.texture(at: directory.appendingPathComponent(file))
            if bezel == nil { throw PackError("\(label): bezel '\(file)' is missing or not a readable image") }
        }
        return LoadedPack(manifest: manifest, frames: frames, bezel: bezel)
    }

    /// Cuts a one-row sheet into equal nearest-filtered frames.
    static func frames(of sheet: SKTexture, count: Int) -> [SKTexture] {
        (0..<count).map { index in
            let frame = SKTexture(rect: CGRect(x: CGFloat(index) / CGFloat(count), y: 0, width: 1 / CGFloat(count), height: 1), in: sheet)
            frame.filteringMode = .nearest
            return frame
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, in directory: URL, label: String) throws -> T {
        let url = directory.appendingPathComponent("manifest.json")
        guard let data = try? Data(contentsOf: url) else { throw PackError("\(label): manifest.json is missing") }
        do { return try JSONDecoder().decode(type, from: data) } catch {
            throw PackError("\(label): manifest.json is invalid (\(error))")
        }
    }

    /// Every texture goes through here so nothing is ever bilinear-filtered.
    private static func texture(at url: URL) -> SKTexture? {
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}
