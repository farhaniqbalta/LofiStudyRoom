import SpriteKit
import XCTest
@testable import LoFiRoom

/// Packs exported by `Tools/aseprite_export.py` into `ArtLab/aseprite/out` (a resource of this test bundle)
/// must load through the real repository next to the bundled scene, without being part of the app.
@MainActor
final class AsepritePipelineTests: XCTestCase {
    func testAsepriteExportsLoadBesideBundledPacks() throws {
        let files = FileManager.default
        let root = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? files.removeItem(at: root) }
        try files.copyItem(at: Bundle.main.resourceURL!.appendingPathComponent("Assets"), to: root)
        let exported = try XCTUnwrap(Bundle(for: Self.self).resourceURL).appendingPathComponent("out")
        var loaded = 0
        let repository = try SpriteAssetRepository(root: root)
        for category in try files.contentsOfDirectory(atPath: exported.path) {
            for folder in try files.contentsOfDirectory(atPath: exported.appendingPathComponent(category).path) {
                try files.copyItem(at: exported.appendingPathComponent("\(category)/\(folder)"), to: root.appendingPathComponent("\(category)/\(folder)"))
                XCTAssertTrue(repository.folders(in: category).contains(folder), "\(folder) is not offered for the scene")
                let pack = try repository.load(category, folder)
                XCTAssertFalse(pack.frames.isEmpty)
                loaded += 1
            }
        }
        XCTAssertGreaterThan(loaded, 0, "no exported packs in the test bundle")

        // The demonstration pack: tag-derived and sidecar-derived animations both arrive intact.
        let cat = try repository.load("Pets", "OrangeCatAse")
        XCTAssertEqual(cat.frames.count, 7)
        XCTAssertEqual(cat.manifest.frame, PixelSize(w: 37, h: 28))
        XCTAssertEqual(cat.manifest.animations?["sleep"]?.frames, [0, 1])
        XCTAssertEqual(cat.manifest.animations?["sleep"]?.fps, 0.5)
        XCTAssertEqual(cat.manifest.animations?["twitch"]?.frames, [5, 6, 5])
        XCTAssertEqual(cat.manifest.animations?["twitch"]?.routine, RoutineSpec(weight: 1, cooldown: 120))
        XCTAssertEqual(cat.manifest.animations?["react"]?.onTap, true)
    }
}
