import Combine
import XCTest
@testable import LoFiRoom

@MainActor
final class PowerPolicyTests: XCTestCase {
    func testFramesPerSecond() {
        for thermal in [ProcessInfo.ThermalState.nominal, .fair] {
            XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 30, lowPower: false, thermal: thermal), 30)
        }
        XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 30, lowPower: true, thermal: .nominal), 15)
        XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 30, lowPower: false, thermal: .serious), 15)
        XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 30, lowPower: false, thermal: .critical), 15)
        XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 6, lowPower: true, thermal: .nominal), 6)
        XCTAssertEqual(PowerPolicy.framesPerSecond(requested: 12, lowPower: false, thermal: .critical), 12)
    }

    func testIdleTimerOnlyWhileActiveAndChosen() {
        XCTAssertTrue(PowerPolicy.idleTimerDisabled(keepAwake: true, active: true))
        XCTAssertFalse(PowerPolicy.idleTimerDisabled(keepAwake: true, active: false))
        XCTAssertFalse(PowerPolicy.idleTimerDisabled(keepAwake: false, active: true))
        XCTAssertFalse(PowerPolicy.idleTimerDisabled(keepAwake: false, active: false))
    }

    private func coordinator(timers: FakeTimers) throws -> (SceneCoordinator, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        _ = try FixtureScene.make(in: root)
        let defaults = UserDefaults(suiteName: "PowerPolicyTests")!
        defaults.removePersistentDomain(forName: "PowerPolicyTests")
        let repository = try SpriteAssetRepository(root: root)
        let scene = try LoFiSKScene(repository: repository, showAnchors: false)
        let coordinator = SceneCoordinator(repository: repository, store: RoomStateStore(defaults: defaults), scene: scene,
                                           timers: timers, clock: { timers.now }, routineSpeed: 1)
        coordinator.start(clockDriver: ClockDriver { scene.clock.show($0) })
        return (coordinator, root)
    }

    func testSetActivePublishesAndIsIdempotent() throws {
        let timers = FakeTimers()
        let (coordinator, root) = try coordinator(timers: timers)
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertTrue(coordinator.isActive)
        XCTAssertEqual(timers.pendingDelays.count, 1)
        coordinator.setActive(true)
        XCTAssertEqual(timers.pendingDelays.count, 1)
        coordinator.setActive(false)
        XCTAssertFalse(coordinator.isActive)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
        coordinator.setActive(false)
        XCTAssertFalse(coordinator.isActive)
        XCTAssertTrue(timers.pendingDelays.isEmpty)
        coordinator.setActive(true)
        XCTAssertEqual(timers.pendingDelays.count, 1)
    }

    func testPowerStateChangedPublishes() throws {
        let timers = FakeTimers()
        let (coordinator, root) = try coordinator(timers: timers)
        defer { try? FileManager.default.removeItem(at: root) }
        var emitted = 0
        let sub = coordinator.objectWillChange.sink { emitted += 1 }
        coordinator.powerStateChanged(lowPower: true, thermal: .serious)
        XCTAssertTrue(coordinator.lowPower)
        XCTAssertEqual(coordinator.thermal, .serious)
        XCTAssertGreaterThan(emitted, 0)
        sub.cancel()
    }
}
