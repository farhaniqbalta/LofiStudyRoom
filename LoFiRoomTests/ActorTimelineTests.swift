import SpriteKit
import XCTest
@testable import LoFiRoom

@MainActor
final class ActorTimelineTests: XCTestCase {
    private func anim(_ frames: [Int], fps: Double, loop: Bool? = nil, safe: [Int]? = nil) -> SpritePack.Animation {
        .init(frames: frames, fps: fps, loop: loop, safeExits: safe)
    }

    private func pack(_ animations: [String: SpritePack.Animation], fallback: String) throws -> LoadedPack {
        let manifest = try SpriteAssetRepository().load("Characters", "Boy01").manifest
        var m = manifest
        m.animations = animations
        m.fallbackAnimation = fallback
        return LoadedPack(manifest: m, frames: (0..<8).map { _ in SKTexture() }, bezel: nil)
    }

    private func node(_ fake: FakeTimers) -> PackSpriteNode {
        let node = PackSpriteNode()
        node.timers = fake
        node.clock = { fake.now }
        return node
    }

    func testLoopFrameIndex() {
        let t = ActorTimeline(animation: anim([4, 5, 6], fps: 2))
        XCTAssertEqual(t.frameIndex(at: 0), 4)
        XCTAssertEqual(t.frameIndex(at: 0.5), 5)
        XCTAssertEqual(t.frameIndex(at: 1.49), 6)
        XCTAssertEqual(t.frameIndex(at: 1.5), 4)
    }

    func testOneShotClampsAndFinishes() {
        let t = ActorTimeline(animation: anim([0, 1, 2], fps: 2, loop: false))
        XCTAssertEqual(t.frameIndex(at: 10), 2)
        XCTAssertFalse(t.isFinished(at: 1.49))
        XCTAssertTrue(t.isFinished(at: 1.5))
        XCTAssertFalse(ActorTimeline(animation: anim([0, 1, 2], fps: 2)).isFinished(at: 100))
    }

    func testNextSafeExit() {
        let loop = ActorTimeline(animation: anim([0, 1, 2, 3], fps: 1, safe: [0, 3]))
        XCTAssertEqual(loop.nextSafeExit(after: 0.2), 1.0, accuracy: 0.0001)
        XCTAssertEqual(loop.nextSafeExit(after: 1.0), 4.0, accuracy: 0.0001)
        XCTAssertEqual(loop.nextSafeExit(after: 4.1), 5.0, accuracy: 0.0001)
        let shot = ActorTimeline(animation: anim([0, 1, 2, 3], fps: 1, loop: false, safe: [0, 3]))
        XCTAssertEqual(shot.nextSafeExit(after: 4.1), 4.0, accuracy: 0.0001)
        let all = ActorTimeline(animation: anim([0, 1, 2, 3], fps: 1))
        XCTAssertEqual(all.nextSafeExit(after: 0.2), 1.0, accuracy: 0.0001)
        XCTAssertEqual(all.nextSafeExit(after: 1.0), 2.0, accuracy: 0.0001)
    }

    func testSafeExitMustBeAFrame() throws {
        let repository = try SpriteAssetRepository()
        var bad = try repository.load("Characters", "Boy01").manifest
        let sheet = PixelSize(w: bad.frame.w * 2, h: bad.frame.h)
        bad.animations = ["study": anim([0, 1], fps: 1, safe: [9])]
        bad.fallbackAnimation = "study"
        XCTAssertEqual(bad.problems(folder: "Boy01", scene: repository.scene, sheetSize: sheet),
                       ["animation 'study' safe exit 9 is not one of its frames"])
    }

    func testOneShotCallsThenAfterItsDuration() throws {
        let fake = FakeTimers(), node = node(fake)
        node.show(try pack(["rest": anim([0], fps: 1), "sip": anim([1, 2], fps: 2, loop: false)], fallback: "rest"))
        var ran = 0
        node.play("sip") { ran += 1 }
        XCTAssertEqual(node.currentAnimation, "sip")
        fake.advance(by: 0.99)
        XCTAssertEqual(ran, 0)
        fake.advance(by: 0.01)
        XCTAssertEqual(ran, 1)
        fake.advance(by: 5)
        XCTAssertEqual(ran, 1)
    }

    func testPlayOfMissingOrLoopingAnimationCallsThenImmediately() throws {
        let fake = FakeTimers(), node = node(fake)
        node.show(try pack(["rest": anim([0, 1], fps: 1)], fallback: "rest"))
        var ran = 0
        node.play("nope") { ran += 1 }
        node.play("rest") { ran += 1 }
        XCTAssertEqual(ran, 2)
        XCTAssertEqual(node.currentAnimation, "rest")
        XCTAssertEqual(fake.pendingDelays, [])
    }

    func testRequestExitWaitsForTheNextSafeFrame() throws {
        let fake = FakeTimers(), node = node(fake)
        node.show(try pack(["rest": anim([0, 1, 2, 3], fps: 1, safe: [0, 3])], fallback: "rest"))
        fake.advance(by: 1.2)
        var ran = false
        node.requestExit { ran = true }
        XCTAssertEqual(fake.pendingDelays.count, 1)
        XCTAssertEqual(fake.pendingDelays[0], 2.8, accuracy: 0.0001)
        fake.advance(by: 2.79)
        XCTAssertFalse(ran)
        fake.advance(by: 0.01)
        XCTAssertTrue(ran)
    }

    func testSecondExitRequestReplacesTheFirst() throws {
        let fake = FakeTimers(), node = node(fake)
        node.show(try pack(["rest": anim([0, 1], fps: 1)], fallback: "rest"))
        var log: [Int] = []
        node.requestExit { log.append(1) }
        node.requestExit { log.append(2) }
        XCTAssertEqual(fake.pendingDelays.count, 1)
        fake.advance(by: 10)
        XCTAssertEqual(log, [2])
    }

    func testShowCancelsPendingCallbacks() throws {
        let fake = FakeTimers(), node = node(fake)
        let p = try pack(["rest": anim([0], fps: 1), "sip": anim([1, 2], fps: 2, loop: false)], fallback: "rest")
        node.show(p)
        var ran = false
        node.play("sip") { ran = true }
        node.show(p, animation: "rest")
        fake.advance(by: 10)
        XCTAssertFalse(ran)
    }

    func testFixtureOneShotsDecode() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try FixtureScene.make(in: root)
        let typist = try SpriteAssetRepository(root: root).load("Characters", "Typist").manifest
        XCTAssertEqual(typist.animations?["sip"]?.loop, false)
        XCTAssertNil(typist.animations?["type"]?.loop)
    }
}
