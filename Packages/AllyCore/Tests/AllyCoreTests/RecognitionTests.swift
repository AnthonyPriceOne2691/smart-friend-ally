import AllyCore
import XCTest

/// Samples of 16 kHz: `seconds` at one level.
func stretch(_ seconds: Double, _ level: Int16) -> [Int16] { Array(repeating: level, count: Int(seconds * 16_000)) }

final class RecognitionTests: XCTestCase {
    func testTheRecognizerHearsFromThePreRollNotBeforeTheOpening() {  // U25
        let late = BatchPhrase(preRoll: 1.5) { _ in "" }, all = stretch(5, 0) + stretch(2, 1_000) + stretch(1.2, 0)
        late.feed(Array(all[..<80_000]))
        late.started()
        late.feed(Array(all[80_000...]))
        XCTAssertEqual(late.heard.count, Int(4.7 * 16_000))
        XCTAssertEqual(late.heard, Array(all[56_000...]))
        let early = BatchPhrase(preRoll: 1.5) { _ in "" }
        let quick = stretch(0.2, 0) + stretch(2, 1_000) + stretch(1.2, 0)
        early.feed(Array(quick[..<3_200]))
        early.started()
        early.feed(Array(quick[3_200...]))
        XCTAssertEqual(early.heard, quick)
        XCTAssertEqual(BatchPhrase.floats([-32_768, 16_384, 0, 32_767]), [-1, 0.5, 0, Float(32_767) / 32_768])
    }

    func testOneDecodingATurnUnlessHerSpeechCameBack() {  // U26
        let count = Locked(0)
        let phrase = BatchPhrase(preRoll: 1.5) { samples in
            count { $0 += 1 }
            return "отсчётов \(samples.count)"
        }
        phrase.feed(stretch(1, 0))
        phrase.started()
        phrase.feed(stretch(1, 900))
        let first = phrase.tentative()
        XCTAssertEqual(phrase.finish(), first)
        XCTAssertEqual(phrase.decodes, 1)
        phrase.resumed()
        phrase.feed(stretch(0.5, 900))
        let second = phrase.tentative()
        XCTAssertNotEqual(second, first)
        XCTAssertEqual(phrase.finish(), second)
        XCTAssertEqual(phrase.decodes, 2)
        let untold = BatchPhrase(preRoll: 1.5) { _ in "тишина" }
        XCTAssertEqual(untold.finish(), "тишина")
        XCTAssertEqual(untold.decodes, 1)
        XCTAssertEqual(count { $0 }, 2)
    }
}
