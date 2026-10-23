import AllyCore
import XCTest

/// Samples of 16 kHz: `seconds` at one level.
func stretch(_ seconds: Double, _ level: Int16) -> [Int16] { Array(repeating: level, count: Int(seconds * 16_000)) }

final class RecognitionTests: XCTestCase {
    func testTheRecognizerHearsFromThePreRollNotBeforeTheOpening() throws {  // U25
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
        // U25: the flag is the detector's — the phrase hears of her start through `TurnEnding` on the frame it rose
        let heard = BatchPhrase(preRoll: 1.5) { _ in "" }
        var detector = TurnDetector(kind: .open, timing: registryTiming,
                                    ending: TurnEnding { if case .started = $0 { heard.started() } })
        var flag: Int?
        for (index, start) in stride(from: 0, to: all.count, by: 320).enumerated() {
            let frame = Array(all[start..<min(start + 320, all.count)])
            heard.feed(frame)
            if case .started? = detector.process(BatchPhrase.floats(frame), at: Double(index) * 0.02) { flag = index }
        }
        XCTAssertEqual(heard.heard.count, all.count - ((try XCTUnwrap(flag) + 1) * 320 - 24_000))
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
        phrase.resumed()  // U26: she spoke again, and the limit or «я всё» came before another pause — no stale text
        phrase.feed(stretch(0.5, 900))
        XCTAssertNotEqual(phrase.finish(), second)
        XCTAssertEqual(phrase.decodes, 3)
        let untold = BatchPhrase(preRoll: 1.5) { _ in "тишина" }
        XCTAssertEqual(untold.finish(), "тишина")
        XCTAssertEqual(untold.decodes, 1)
        XCTAssertEqual(count { $0 }, 3)
    }
}
