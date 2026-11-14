import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class LoFiRoomTests: XCTestCase {
    private var repository: SpriteAssetRepository!
    private var scene: LoFiSKScene!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        repository = try SpriteAssetRepository()
        scene = try LoFiSKScene(repository: repository, showAnchors: false)
        defaults = UserDefaults(suiteName: "LoFiRoomTests")
        defaults.removePersistentDomain(forName: "LoFiRoomTests")
    }

    private func utc(_ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: hour, minute: minute, second: second))!
    }

    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    // MARK: Scaling and scene

    func testIntegerScale() {
        let safe = CGSize(width: repository.scene.safe.w!, height: repository.scene.safe.h!)
        XCTAssertEqual(safe, CGSize(width: 452, height: 328))
        func scale(_ w: CGFloat, _ h: CGFloat) -> Int { ScalePolicy.integerScale(viewPixels: CGSize(width: w, height: h), safe: safe) }
        XCTAssertEqual(scale(2388, 1668), 5)   // 11-inch iPad Pro
        XCTAssertEqual(scale(2732, 2048), 6)   // 12.9-inch
        XCTAssertEqual(scale(2752, 2064), 6)   // 13-inch
        XCTAssertEqual(scale(2360, 1640), 5)   // 10.9-inch Air
        XCTAssertEqual(scale(1668, 2388), 3)   // portrait-shaped window: letterboxed
        XCTAssertEqual(scale(100, 100), 1)     // never below 1
    }

    func testSceneManifestIsValidAndReportsProblems() {
        XCTAssertEqual(repository.scene.problems(), [])
        var broken = repository.scene
        broken.anchors["lamp"] = nil
        broken.anchors["pet-spot"]!.x = 9999
        XCTAssertEqual(broken.problems(), ["anchor 'pet-spot' is outside the safe area", "missing anchor 'lamp'"])
    }

    func testSceneScalesToWholePixelsOnThisDevice() {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1194, height: 834))
        view.presentScene(scene)
        let pixels = view.traitCollection.displayScale
        XCTAssertEqual(scene.pixelScale, ScalePolicy.integerScale(
            viewPixels: CGSize(width: 1194 * pixels, height: 834 * pixels), safe: CGSize(width: 452, height: 328)))
    }

    // MARK: Packs

    func testEveryBundledPackLoadsAndIsNearestFiltered() throws {
        let expected = ["Characters": ["Boy01", "Girl01"], "Pets": ["BlackCat", "OrangeCat"],
                        "Scenery": ["NeonCity01", "NeonCity02"], "Clocks": ["RetroDigital01"]]
        for (category, folders) in expected {
            XCTAssertEqual(repository.folders(in: category), folders)
            for folder in folders {
                let pack = try repository.load(category, folder)
                XCTAssertFalse(pack.frames.isEmpty)
                XCTAssertTrue(pack.frames.allSatisfy { $0.filteringMode == .nearest }, folder)
            }
        }
    }

    func testVariantsShareFrameSizeSoTheyRegisterOnTheSameAnchor() throws {
        for (category, a, b) in [("Characters", "Boy01", "Girl01"), ("Pets", "OrangeCat", "BlackCat"), ("Scenery", "NeonCity01", "NeonCity02")] {
            let first = try repository.load(category, a).manifest, second = try repository.load(category, b).manifest
            XCTAssertEqual(first.frame, second.frame, category)
            XCTAssertEqual(first.anchor, second.anchor, category)
        }
    }

    func testPackValidationGivesActionableErrors() throws {
        let good = try repository.load("Characters", "Boy01").manifest
        let sheet = PixelSize(w: good.frame.w * 2, h: good.frame.h)
        XCTAssertEqual(good.problems(folder: "Boy01", scene: repository.scene, sheetSize: sheet), [])

        var bad = good
        bad.perspective = "top-down"
        bad.anchor = "ceiling"
        bad.animations = ["study": .init(frames: [0, 7], fps: 1)]
        bad.fallbackAnimation = "nap"
        XCTAssertEqual(bad.problems(folder: "Boy01", scene: repository.scene, sheetSize: sheet), [
            "animation 'study' uses frame 7 but the sheet has 2 frames",
            "fallbackAnimation is missing or not one of the animations",
            "perspective 'top-down' does not match the scene's 'study-room-back-3q-v1'",
            "unknown anchor 'ceiling'",
        ])
        XCTAssertEqual(good.problems(folder: "Boy01", scene: repository.scene, sheetSize: nil), ["sheet 'sheet.png' is missing or not a readable image"])
        XCTAssertEqual(good.problems(folder: "Boy01", scene: repository.scene, sheetSize: PixelSize(w: 100, h: 3)),
                       ["sheet is 100x3, which is not a row of \(good.frame.w)x\(good.frame.h) frames"])
        XCTAssertThrowsError(try repository.load("Characters", "Nobody")) {
            XCTAssertEqual($0.localizedDescription, "Characters/Nobody: manifest.json is missing")
        }
    }

    func testMissingAnimationFallsBack() throws {
        let manifest = try repository.load("Characters", "Boy01").manifest
        XCTAssertEqual(manifest.animation(named: "stretch"), manifest.animations?["study"])
    }

    // MARK: Swapping and persistence

    func testSwappingPacksKeepsNodeCountAndSavesTheChoice() {
        let store = RoomStateStore(defaults: defaults)
        let coordinator = SceneCoordinator(repository: repository, store: store, scene: scene)
        coordinator.start(clockDriver: ClockDriver(now: { self.utc(22, 47) }, calendar: { self.calendar("UTC") }) { self.scene.clock.show($0) })
        func nodeCount(_ node: SKNode) -> Int { 1 + node.children.map(nodeCount).reduce(0, +) }
        let before = nodeCount(scene)
        let room = scene.children[0].children

        for round in 0..<100 {
            XCTAssertTrue(coordinator.select(round % 2 == 0 ? "Girl01" : "Boy01", in: "Characters"))
            XCTAssertTrue(coordinator.select(round % 2 == 0 ? "BlackCat" : "OrangeCat", in: "Pets"))
            XCTAssertTrue(coordinator.select(round % 2 == 0 ? "NeonCity02" : "NeonCity01", in: "Scenery"))
        }
        XCTAssertEqual(nodeCount(scene), before)
        XCTAssertTrue(zip(room, scene.children[0].children).allSatisfy { $0 === $1 }, "layer groups must not be rebuilt")
        XCTAssertEqual(scene.clock.text, "22:47")

        XCTAssertFalse(coordinator.select("Nobody", in: "Characters"))
        XCTAssertEqual(scene.character.pack?.manifest.id, "boy01", "a bad pack leaves the scene as it was")

        coordinator.select("Girl01", in: "Characters")
        coordinator.select("NeonCity02", in: "Scenery")
        let restored = RoomStateStore(defaults: defaults).config
        XCTAssertEqual(restored, RoomConfig(character: "Girl01", pet: "OrangeCat", scenery: "NeonCity02"))
    }

    func testSavedPackThatNoLongerExistsFallsBack() {
        let store = RoomStateStore(defaults: defaults)
        store.config.character = "Deleted01"
        let coordinator = SceneCoordinator(repository: repository, store: store, scene: scene)
        coordinator.start()
        XCTAssertEqual(scene.character.pack?.manifest.id, "boy01")
        XCTAssertEqual(store.config.character, "Boy01")
    }

    func testLayersAreOrderedBackToFront() {
        let order: [LoFiSKScene.Layer] = [.scenery, .room, .actors, .foreground, .objects, .debug]
        XCTAssertEqual(order.map(\.rawValue), order.map(\.rawValue).sorted())
        XCTAssertLessThan(scene.character.parent!.zPosition, LoFiSKScene.Layer.foreground.rawValue, "the chair back draws over the character")
        XCTAssertLessThan(scene.scenery.parent!.zPosition, LoFiSKScene.Layer.room.rawValue, "the room's window masks the scenery")
    }

    // MARK: Clock

    func testClockTextIs24HourInTheLocalZone() {
        XCTAssertEqual(ClockTime.text(for: utc(9, 59), calendar: calendar("UTC")), "09:59")
        XCTAssertEqual(ClockTime.text(for: utc(23, 59, 59), calendar: calendar("UTC")), "23:59")
        XCTAssertEqual(ClockTime.text(for: utc(0, 0), calendar: calendar("UTC")), "00:00")
        XCTAssertEqual(ClockTime.text(for: utc(15, 47), calendar: calendar("Asia/Jakarta")), "22:47")
        XCTAssertEqual(ClockTime.text(for: utc(15, 47), calendar: calendar("Asia/Kolkata")), "21:17")
        var twelveHour = calendar("America/New_York")
        twelveHour.locale = Locale(identifier: "en_US")
        XCTAssertEqual(ClockTime.text(for: utc(20, 5), calendar: twelveHour), "15:05")
    }

    func testNextMinuteBoundary() {
        XCTAssertEqual(ClockTime.nextMinute(after: utc(9, 59, 30), calendar: calendar("UTC")), utc(10, 0))
        XCTAssertEqual(ClockTime.nextMinute(after: utc(10, 0), calendar: calendar("UTC")), utc(10, 1))
        // Half-hour zones still tick on the same instant
        XCTAssertEqual(ClockTime.nextMinute(after: utc(9, 59, 30), calendar: calendar("Asia/Kolkata")), utc(10, 0))
        // US DST ends 2026-11-01 06:00 UTC: 01:59 EDT is followed by 01:00 EST
        let newYork = calendar("America/New_York")
        let beforeFallBack = Date(timeIntervalSince1970: 1_793_512_770) // 2026-11-01 05:59:30 UTC
        XCTAssertEqual(ClockTime.text(for: beforeFallBack, calendar: newYork), "01:59")
        let next = ClockTime.nextMinute(after: beforeFallBack, calendar: newYork)
        XCTAssertEqual(next.timeIntervalSince(beforeFallBack), 30)
        XCTAssertEqual(ClockTime.text(for: next, calendar: newYork), "01:00")
    }

    func testClockNodeOnlySwapsChangedGlyphs() throws {
        let clock = scene.clock
        clock.use(try repository.load("Clocks", "RetroDigital01"))
        clock.show("09:59")
        XCTAssertEqual(clock.glyphSwaps, 5)
        clock.show("09:59")
        XCTAssertEqual(clock.glyphSwaps, 5)
        clock.show("10:00")
        XCTAssertEqual(clock.glyphSwaps, 9, "the colon is untouched")
        clock.show("10:01")
        XCTAssertEqual(clock.glyphSwaps, 10)
    }

    func testClockDriverFollowsTheWallClockAndSystemTimeChanges() {
        var now = utc(15, 47, 10)
        var zone = "UTC"
        var shown: [String] = []
        let driver = ClockDriver(now: { now }, calendar: { self.calendar(zone) }) { shown.append($0) }
        driver.start()
        XCTAssertEqual(shown, ["15:47"])

        now = utc(18, 2)   // woke from a long suspend: the minute timer never fired
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        zone = "Asia/Jakarta"
        NotificationCenter.default.post(name: .NSSystemTimeZoneDidChange, object: nil)
        now = utc(18, 30)  // user changed the clock
        NotificationCenter.default.post(name: .NSSystemClockDidChange, object: nil)
        XCTAssertEqual(shown, ["15:47", "18:02", "01:02", "01:30"])

        driver.stop()
        NotificationCenter.default.post(name: .NSSystemClockDidChange, object: nil)
        XCTAssertEqual(shown.count, 4, "a stopped driver no longer listens")
    }
}
