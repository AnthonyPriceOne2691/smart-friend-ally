import AllyCore
import ShellCore
import XCTest

final class NapTests: XCTestCase {
    /// The parent's key with three points at each edge (L90); none by default — his answer «Без перерыва».
    func testTheKeyIsReadWithThreePointsAtEachEdge() {  // V24
        XCTAssertEqual(Nap().minutes, 0)
        XCTAssertNil(Nap().note)
        for (raw, minutes) in [("0", 0), ("1", 1), ("180", 180)] {
            XCTAssertEqual(Nap(raw: raw).minutes, minutes, raw)
            XCTAssertNil(Nap(raw: raw).note, raw)
        }
        for raw in ["-1", "181", "abc"] {
            XCTAssertEqual(Nap(raw: raw).minutes, 0, raw)
            XCTAssertEqual(Nap(raw: raw).note, "перерыв вне 0–180 мин — взято 0", raw)
        }
    }

    /// Only a goodbye by the limit starts a break, and it ends on its minute; by default there is none.
    func testABreakFollowsOnlyTheLimitAndEndsOnTime() throws {  // V25
        let end = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-23T17:40:00+03:00"))
        let limit = TalkState(phase: .asleep, ended: "limit")
        var none = Nap()
        none.ended(limit, at: end)
        XCTAssertFalse(none.holds(at: end + 1))
        XCTAssertNil(none.line(at: end + 1, zone: moscow))

        var nap = Nap(raw: "60")
        nap.ended(limit, at: end)
        XCTAssertTrue(nap.holds(at: end + 3599))
        XCTAssertEqual(nap.line(at: end + 3599, zone: moscow), "перерыв до 18:40")
        XCTAssertFalse(nap.holds(at: end + 3600))
        XCTAssertNil(nap.line(at: end + 3600, zone: moscow))

        for reason in ["goodbye_word", "rest", "parent", "error"] {
            var other = Nap(raw: "60")
            other.ended(TalkState(phase: .asleep, ended: reason), at: end)
            XCTAssertFalse(other.holds(at: end + 1), reason)
        }
        var running = Nap(raw: "60")
        running.ended(TalkState(phase: .speaking), at: end)
        running.ended(TalkState(phase: .asleep), at: end)
        XCTAssertFalse(running.holds(at: end + 1))

        nap.ended(limit, at: end + 7200)
        XCTAssertEqual(nap.line(at: end + 7300, zone: moscow), "перерыв до 20:40")
    }
}
