import ShellCore
import XCTest

final class CrownTests: XCTestCase {
    /// Prototype v3's crown: its flowers, leaves and glints; the rows mirror across her head; seated above the brows.
    func testTheCrownIsThePrototypesAndSitsInTheMiddleOfHerHead() {  // V19
        let kinds = Dictionary(grouping: Crown.flowers, by: \.kind).mapValues(\.count)
        XCTAssertEqual([kinds[.rose], kinds[.carnation], kinds[.lisianthus]], [7, 7, 8])
        for flower in Crown.flowers {
            let gap = Crown.flowers.map { abs($0.x + flower.x) + abs($0.y - flower.y) }.min() ?? .infinity
            XCTAssertLessThanOrEqual(gap, 0.2, "no mirror for \(flower.x), \(flower.y)")
        }
        XCTAssertEqual(Crown.flowers.filter { abs($0.x) <= 0.1 }.count, 2)
        XCTAssertEqual(Crown.flowers.map(\.x).reduce(0, +) / Double(Crown.flowers.count), 0, accuracy: 0.1)
        XCTAssertEqual([Crown.leaves.count, Crown.leaves.filter(\.dark).count], [22, 11])
        XCTAssertEqual([Crown.leafLength, Crown.leafWidth], [8.2, 3.8])
        let stars = Crown.glints.filter(\.star), dots = Crown.glints.filter { !$0.star }
        XCTAssertEqual([stars.count, dots.count], [44, 12])
        XCTAssertEqual((0..<3).map { tone in stars.filter { $0.tone == tone }.count }, [11, 22, 11])
        let seat = seated()
        XCTAssertEqual(seat.left, -68.8, accuracy: 0.5)
        XCTAssertEqual(seat.right, 78.9, accuracy: 0.5)
        XCTAssertEqual(seat.top, -143, accuracy: 0.5)
        XCTAssertEqual(seat.bottom, -85.7, accuracy: 0.5)
        XCTAssertLessThan(seat.bottom, -74 - 5)  // above the brows even in a yawn (brows at −74, −5 higher)
    }

    /// Each glint at its own tempo, never all at once; Reduce Motion holds them still — a relation, not values.
    func testGlintsTwinkleOutOfStepAndStandStillWithReduceMotion() {  // V20
        let count = Crown.glints.count
        var lows = [Double](repeating: 1, count: count), highs = [Double](repeating: 0, count: count)
        var spread = Double.infinity
        for frame in 0..<(60 * 120) {
            let bright = (0..<count).map { Crown.twinkle($0, at: Double(frame) / 120) }
            spread = min(spread, (bright.max() ?? 0) - (bright.min() ?? 0))
            lows = zip(lows, bright).map { min($0, $1) }
            highs = zip(highs, bright).map { max($0, $1) }
        }
        XCTAssertGreaterThanOrEqual(spread, 0.5)
        XCTAssertTrue(lows.allSatisfy { $0 >= 0.35 - 1e-9 && $0 <= 0.40 }, "\(lows)")
        XCTAssertTrue(highs.allSatisfy { $0 >= 0.95 && $0 <= 1 + 1e-9 }, "\(highs)")
        XCTAssertTrue((0..<count).allSatisfy { (1.4...3.2).contains(Crown.tempo($0)) })
        XCTAssertTrue((0..<count).allSatisfy { Crown.twinkle($0, at: 7.3, calm: true) == 0.8 })
    }

    /// The crown's extent on her head: every leaf, flower box and glint, seated by 0.8 about (0; −120).
    private func seated() -> Extent {
        var xs: [Double] = [], ys: [Double] = []
        let add = { (x: Double, y: Double, reach: Double) in
            xs += [x - reach, x + reach]
            ys += [y - reach, y + reach]
        }
        Crown.leaves.forEach { add($0.x, $0.y, Crown.leafLength) }
        Crown.flowers.forEach { add($0.x, $0.y, $0.width / 2) }
        Crown.glints.forEach { add($0.x, $0.y, $0.star ? $0.size / 2 : $0.size) }
        let seat = { (y: Double) in Crown.pivotY + Crown.scale * (y - Crown.pivotY) }
        return Extent(left: (xs.min() ?? 0) * Crown.scale, right: (xs.max() ?? 0) * Crown.scale,
                      top: seat(ys.min() ?? 0), bottom: seat(ys.max() ?? 0))
    }
}

/// A box in head units.
struct Extent {
    let left: Double, right: Double, top: Double, bottom: Double
}
