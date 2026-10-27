import AllyCore
import ShellCore
import XCTest

/// Moscow, without daylight saving: the zone of the examples, the same on Linux and the Mac.
let moscow = TimeZone(secondsFromGMT: 3 * 3600) ?? .current

final class TapTests: XCTestCase {
    /// The bubble is the only target, and the phase says what a touch on it does (rules 2–4, «я всё» — D7).
    func testOnlyTheBubbleIsATargetAndThePhaseSaysWhatATapDoes() {  // V22
        let phone = Layout(width: 440, height: 956, safeTop: 62, safeBottom: 34)
        XCTAssertTrue(phone.hits(x: 220, y: 535))
        XCTAssertTrue(phone.hits(x: 220, y: 724))
        for (x, y) in [(220.0, 726.0), (30, 535), (220, 900), (402, 84)] {
            XCTAssertFalse(phone.hits(x: x, y: y), "\(x), \(y)")
        }
        let expected: [SessionState: Tap] = [.asleep: .wake, .listening: .done, .windingDown: .done, .thinking: .ignore,
                                             .goodbye: .ignore, .paused: .ignore]
        for (phase, action) in expected {
            XCTAssertEqual(Tap.action(phase), action, "\(phase)")
        }
    }

    /// While Elly greets or answers, a tap on her cuts her, as her speech over the voice does (D6.2).
    func testATapWhileEllieSpeaksCutsHer() {
        XCTAssertEqual([SessionState.greeting, .speaking].map(Tap.action), [.bargeIn, .bargeIn])  // X14
    }

    /// The adult's label speaks the console's words for the term (R); without a term there is none.
    func testTheAdultLabelIsTheConsolesTerm() throws {  // V26
        let until = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-29T21:00:00+03:00"))
        XCTAssertEqual(Tap.label(until: until, zone: moscow), "при родителе · до 29.10 в 21:00")
        XCTAssertNil(Tap.label(until: nil, zone: moscow))
    }
}
