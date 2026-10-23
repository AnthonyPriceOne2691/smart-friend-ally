import ShellCore
import XCTest

final class PaletteTests: XCTestCase {
    /// Rule 9: every line on the fill it borders is ≥ 3:1; the ratios are the spec's, computed apart from this code.
    func testLinesContrastWithTheirFills() {  // V7
        let expected: [(Border, Double)] = [
            (Border(Palette.eye, on: Palette.skin), 5.95), (Border(Palette.line, on: Palette.water), 4.54),
            (Border(Palette.line, on: Palette.waterEdge), 4.32), (Border(Palette.raspberry, on: Palette.skyMid), 4.99),
            (Border(Palette.raspberry, on: Palette.skyLow), 4.33), (Border(Palette.mouth, on: Palette.skin), 3.91),
            (Border(Palette.plum, on: Palette.blossom), 11.18)
        ]
        for (border, ratio) in expected {
            XCTAssertEqual(border.line.contrast(with: border.fill), ratio, accuracy: 0.005)
        }
        XCTAssertEqual(Palette.borders.count, expected.count)
        XCTAssertTrue(Palette.borders.allSatisfy { $0.line.contrast(with: $0.fill) >= 3 })
        // Pink is a fill, never a line: #F28DB2 on #FFF0F5 is 2.06:1.
        XCTAssertEqual(Tone(0xF28DB2).contrast(with: Palette.blossom), 2.06, accuracy: 0.005)
    }
}
