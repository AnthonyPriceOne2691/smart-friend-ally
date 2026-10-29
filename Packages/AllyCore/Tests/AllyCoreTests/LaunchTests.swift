@testable import AllyCore
import XCTest

/// The first screens and the child session's listener without the lock (child-open; examples J2, J3, J4, J6 signed by
/// the parent 2026-10-29). The lock's fixtures — `Lock`, `fixtureSurface` — are the ones of `ReleaseGateTests`.
final class LaunchTests: XCTestCase {
    func testAReadyWarmUpOpensEllieAtOnce() {  // J2
        XCTAssertEqual(Launch.after(ready: true, build: ReleaseGate.Build(surface: fixtureSurface)), .child)
    }

    func testANotReadyWarmUpOrABrokenSelfTestOpensTheConsole() {  // J3
        XCTAssertEqual(Launch.after(ready: false, build: ReleaseGate.Build(surface: fixtureSurface)), .console)
        XCTAssertEqual(Launch.after(ready: true, build: ReleaseGate.Build(surface: fixtureSurface, router: false)),
                       .console)
        XCTAssertEqual(Launch.after(ready: true, build: ReleaseGate.Build(surface: fixtureSurface, contract: false)),
                       .console)
    }

    func testWithoutAValidExceptionEllieOpensAndTheChildSessionIsSupervised() throws {  // J4
        let lock = try Lock()
        let other = ReleaseSurface(contract: "fnv1a:other", router: fixtureSurface.router,
                                   persona: fixtureSurface.persona, model: fixtureSurface.model)
        let closed = [try lock.access(nil), try lock.access(try lock.file(), now: "2026-10-30T12:00:00+03:00"),
                      try lock.access(try lock.file(surface: other))]
        for access in closed {
            XCTAssertFalse(access.open, "\(access)")  // the lock R kept the child screen closed here
            XCTAssertEqual(Launch.after(ready: true, build: lock.build), .child)
            XCTAssertEqual(ReleaseGate.audience(access), .supervised, "\(access)")
        }
        XCTAssertEqual(ReleaseGate.audience(try lock.access(try lock.file())), .supervised)
        XCTAssertEqual(ReleaseGate.audience(.child), .child)  // J4 — the signed acceptance: no words kept
    }

    func testTheLoadingLineSaysTheWholeAndEachStageInTenths() {  // J6
        XCTAssertEqual(LoadingLine.text(total: 18.44, stages: [("модель", 12.06), ("голос", 2.31), ("слух", 1.38)]),
                       "загрузка: 18,4 с · модель 12,1 · голос 2,3 · слух 1,4")
        XCTAssertEqual(LoadingLine.text(total: 0.04, stages: []), "загрузка: 0,0 с")
    }
}
