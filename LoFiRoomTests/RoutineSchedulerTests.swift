import XCTest
@testable import LoFiRoom

private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@MainActor
final class RoutineSchedulerTests: XCTestCase {
    private var root: URL!
    private var defaults: UserDefaults!
    private var timers: FakeTimers!

    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        _ = try FixtureScene.make(in: root)
        defaults = UserDefaults(suiteName: "RoutineSchedulerTests")
        defaults.removePersistentDomain(forName: "RoutineSchedulerTests")
        timers = FakeTimers()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: Scheduler

    func testWeightsFavourHeavierRoutines() {
        var scheduler = RoutineScheduler(config: RoutineConfig(
            routines: ["a": RoutineSpec(weight: 3, cooldown: 0), "b": RoutineSpec(weight: 1, cooldown: 0)], delay: 1...1))
        var random = SplitMix64(state: 1)
        var counts: [String: Int] = [:]
        var now = 0.0
        for _ in 0..<1000 {
            let pick = scheduler.next(now: now, random: &random)
            now += pick.delay
            if let name = pick.routine { counts[name, default: 0] += 1 }
        }
        XCTAssertGreaterThan(counts["b", default: 0], 0)
        XCTAssertGreaterThanOrEqual(counts["a", default: 0], 2 * counts["b", default: 0])
    }

    func testCooldownIsRespected() {
        var scheduler = RoutineScheduler(config: RoutineConfig(
            routines: ["a": RoutineSpec(weight: 1, cooldown: 100)], delay: 10...10))
        var random = SplitMix64(state: 2)
        var now = 0.0
        var playedAt: [Double] = []
        for _ in 0..<100 {
            if scheduler.next(now: now, random: &random).routine != nil { playedAt.append(now + 10) }
            now += 10
        }
        XCTAssertFalse(playedAt.isEmpty)
        for (earlier, later) in zip(playedAt, playedAt.dropFirst()) { XCTAssertGreaterThanOrEqual(later - earlier, 100) }
    }

    func testDelayIsWithinRange() {
        var scheduler = RoutineScheduler(config: RoutineConfig(
            routines: ["a": RoutineSpec(weight: 1, cooldown: 0)], delay: RoutineConfig.characterDelay))
        var random = SplitMix64(state: 3)
        for i in 0..<200 {
            XCTAssertTrue(RoutineConfig.characterDelay.contains(scheduler.next(now: Double(i), random: &random).delay))
        }
    }

    func testConfigComesFromTheManifest() throws {
        let repository = try SpriteAssetRepository(root: root)
        let typist = try repository.load("Characters", "Typist").manifest
        XCTAssertEqual(Set(RoutineConfig.from(typist, delay: 1...2).routines.keys), ["sip", "lean"])
        let nappy = try repository.load("Pets", "Nappy").manifest
        XCTAssertTrue(RoutineConfig.from(nappy, delay: 1...2).routines.isEmpty)
    }

    // MARK: Director and coordinator

    private func coordinator() throws -> SceneCoordinator {
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let fake = timers!
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                           timers: fake, clock: { fake.now }, routineSpeed: 1)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return coordinator
    }

    /// Steps one second at a time until the character plays a routine; returns its name.
    private func advanceIntoRoutine(_ coordinator: SceneCoordinator) throws -> String {
        for _ in 0..<1000 {
            timers.advance(by: 1)
            if let name = coordinator.scene.character.currentAnimation, name != "type" { return name }
        }
        XCTFail("no routine started within the allowed time")
        throw CancellationError()
    }

    func testFixtureRoutinesUseOnlyDeclaredNames() throws {
        let coordinator = try coordinator()
        var seen: Set<String> = []
        for _ in 0..<3000 {
            timers.advance(by: 1)
            seen.insert(coordinator.scene.character.currentAnimation ?? "")
            XCTAssertEqual(coordinator.scene.pet.currentAnimation, "nap")
        }
        XCTAssertTrue(seen.isSubset(of: ["type", "sip", "lean"]), "\(seen)")
        XCTAssertTrue(seen.contains("sip") && seen.contains("lean"), "\(seen)")
    }

    func testPetWithoutRoutinesSchedulesNoTimer() throws {
        _ = try coordinator()
        XCTAssertEqual(timers.pendingDelays.count, 1)
    }

    func testInactiveSchedulesNothingAndReactivatingSchedulesOnce() throws {
        let coordinator = try coordinator()
        coordinator.setActive(false)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
        coordinator.setActive(true)
        coordinator.setActive(true)
        XCTAssertEqual(timers.pendingDelays.count, 1)
    }

    func testPetTapPlaysReactionThenReturnsToRest() throws {
        let coordinator = try coordinator()
        coordinator.petTapped()
        XCTAssertEqual(coordinator.scene.pet.currentAnimation, "purr")
        timers.advance(by: 0.5)
        coordinator.petTapped()
        timers.advance(by: 0.6)
        XCTAssertEqual(coordinator.scene.pet.currentAnimation, "nap", "the second tap did not restart the reaction")
    }

    func testSwapDuringOneShotWaitsForItsSafeExit() throws {
        let coordinator = try coordinator()
        let typist2 = root.appendingPathComponent("Characters/Typist2")
        try FileManager.default.copyItem(at: root.appendingPathComponent("Characters/Typist"), to: typist2)
        let manifestURL = typist2.appendingPathComponent("manifest.json")
        var manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as! [String: Any]
        manifest["id"] = "typist2"
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)

        _ = try advanceIntoRoutine(coordinator)
        XCTAssertTrue(coordinator.select("Typist2", in: "Characters"))
        XCTAssertEqual(coordinator.scene.character.pack?.manifest.id, "typist")
        timers.advance(by: 1.1)
        XCTAssertEqual(coordinator.scene.character.pack?.manifest.id, "typist2")
        var seenRoutine = false
        for _ in 0..<1000 where !seenRoutine {
            timers.advance(by: 1)
            seenRoutine = coordinator.scene.character.currentAnimation != "type"
        }
        XCTAssertTrue(seenRoutine, "the routine chain continues after the swap")
    }

    func testSwapAtRestIsImmediate() throws {
        let coordinator = try coordinator()
        let typist2 = root.appendingPathComponent("Characters/Typist2")
        try FileManager.default.copyItem(at: root.appendingPathComponent("Characters/Typist"), to: typist2)
        let manifestURL = typist2.appendingPathComponent("manifest.json")
        var manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as! [String: Any]
        manifest["id"] = "typist2"
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)
        XCTAssertTrue(coordinator.select("Typist2", in: "Characters"))
        XCTAssertEqual(coordinator.scene.character.pack?.manifest.id, "typist2")
    }

    func testOneShotFinishingWhileInactiveSchedulesNothing() throws {
        let coordinator = try coordinator()
        _ = try advanceIntoRoutine(coordinator)
        coordinator.setActive(false)
        timers.advance(by: 2)
        XCTAssertEqual(coordinator.scene.character.currentAnimation, "type")
        XCTAssertTrue(timers.pendingDelays.isEmpty)
    }
}
