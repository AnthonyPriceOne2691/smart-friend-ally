import ShellCore
import XCTest

final class LayoutTests: XCTestCase {
    /// The parent's phone (440×956 pt, safe 62 and 34) and a narrow 320×568 screen where both limits of rule 2 bite.
    func testBubbleKeepsTheChildZonesFree() {  // V6
        let phone = Layout(width: 440, height: 956, safeTop: 62, safeBottom: 34)
        XCTAssertEqual(phone.diameter, 378.4, accuracy: 0.001)
        XCTAssertEqual(phone.centre.x, 220, accuracy: 0.001)
        XCTAssertEqual(phone.centre.y, 535, accuracy: 0.001)
        XCTAssertEqual(phone.bottomGap, 231.8, accuracy: 0.001)
        XCTAssertEqual(phone.sideGap, 30.8, accuracy: 0.001)
        XCTAssertEqual(phone.stopTarget.midX, 402, accuracy: 0.001)
        XCTAssertEqual(phone.stopTarget.midY, 84, accuracy: 0.001)
        XCTAssertEqual(phone.stopTarget.width, 44)
        XCTAssertEqual(phone.centre.y - phone.diameter / 2 - phone.stopTarget.maxY, 239.8, accuracy: 0.001)

        let narrow = Layout(width: 320, height: 568, safeTop: 20, safeBottom: 0)
        XCTAssertEqual(narrow.diameter, 272, accuracy: 0.001)
        XCTAssertEqual(narrow.sideGap, 24, accuracy: 0.001)
        XCTAssertEqual(narrow.centre.y, 292, accuracy: 0.001)
        XCTAssertEqual(narrow.bottomGap, 140, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(Layout(width: 200, height: 400).diameter, 240)
    }
}
