import ShellCore
import XCTest

final class PaletteTests: XCTestCase {
    /// Rule 9: every line on the fill it borders is ≥ 3:1; the ratios are the spec's, computed apart from this code.
    /// The rim on the sky moved to F1 with the pink sky (app-glass, signed 2026-10-27).
    func testLinesContrastWithTheirFills() {  // V7
        let expected: [(Border, Double)] = [
            (Border(Palette.eye, on: Palette.skin), 5.95), (Border(Palette.line, on: Palette.water), 4.54),
            (Border(Palette.line, on: Palette.waterEdge), 4.32), (Border(Palette.mouth, on: Palette.skin), 3.91),
            (Border(Palette.plum, on: Palette.blossom), 11.18)
        ]
        for (border, ratio) in expected {
            XCTAssertEqual(border.line.contrast(with: border.fill), ratio, accuracy: 0.005)
        }
        XCTAssertEqual(Palette.borders.count, expected.count + Palette.skyTones.count)
        XCTAssertTrue(Palette.borders.allSatisfy { $0.line.contrast(with: $0.fill) >= 3 })
        // Pink is a fill, never a line: #F28DB2 on #FFF0F5 is 2.06:1.
        XCTAssertEqual(Tone(0xF28DB2).contrast(with: Palette.blossom), 2.06, accuracy: 0.005)
    }

    /// The pink sky: its tones top to bottom with their shares of the height, the lights, and on each of the seven
    /// tones the raspberry rim ≥ 3:1 and the plum ≥ 4.5:1 — the ratios computed for the spec apart from this code.
    func testThePinkSkyKeepsRuleNine() {  // F1
        XCTAssertEqual(Palette.sky.map { $0.tone.rgb }, [0xDCEEFF, 0xF1E2FF, 0xFFDCEB, 0xFFD6C8])
        XCTAssertEqual(Palette.sky.map { $0.at }, [0, 0.3, 0.62, 1])
        XCTAssertEqual(Palette.skyLights.map(\.tone.rgb), [0xCFE6FF, 0xE3D3FF, 0xFFD3BF, 0xFFFFFF])
        let rims = [4.95, 4.77, 4.67, 4.39, 4.59, 4.20, 4.29], plums = [10.41, 10.02, 9.80, 9.23, 9.64, 8.83, 9.00]
        XCTAssertEqual(Palette.skyTones.map(\.rgb),
                       [0xDCEEFF, 0xF1E2FF, 0xFFDCEB, 0xFFD6C8, 0xCFE6FF, 0xE3D3FF, 0xFFD3BF])
        for (index, tone) in Palette.skyTones.enumerated() {
            XCTAssertEqual(Palette.raspberry.contrast(with: tone), rims[index], accuracy: 0.005)
            XCTAssertEqual(Palette.plum.contrast(with: tone), plums[index], accuracy: 0.005)
            XCTAssertGreaterThanOrEqual(Palette.plum.contrast(with: tone), 4.5)
        }
        XCTAssertTrue(Palette.skyTones.allSatisfy { tone in
            Palette.borders.contains { $0.line == Palette.raspberry && $0.fill == tone }
        })
    }
}
