import AllyVoiceFX
import XCTest

final class SilenceTrimTests: XCTestCase {
    private let rate = 44100, trim = SilenceTrim.standard

    private func silence(_ seconds: Double, level: Float = 0) -> [Float] {
        [Float](repeating: level, count: Int(seconds * Double(rate)))
    }

    private func speech(_ seconds: Double, level: Float = 0.3) -> [Float] {
        (0..<Int(seconds * Double(rate))).map { level * sin(Float($0) * 0.05) }
    }

    func testTheEndsGoAndTheMarginsStay() throws {
        // G1: 0.6 s + 1 s of speech + 0.7 s → 30 ms + the speech + 80 ms, the frames' rounding aside
        let out = try trim.apply(silence(0.6) + speech(1) + silence(0.7), rate: rate)
        XCTAssertEqual(Double(out.count) / Double(rate), 1.11, accuracy: 0.011)
        XCTAssertEqual(out.prefix(Int(0.02 * Double(rate))).map(abs).max() ?? 1, 0, accuracy: 1e-6)
    }

    func testThePausesInsideStay() throws {
        // G2: a pause of 0.4 s between two words stays: only the ends are the synthesis's own
        let sentence = silence(0.5) + speech(0.5) + silence(0.4) + speech(0.5) + silence(0.5)
        let out = try trim.apply(sentence, rate: rate)
        XCTAssertEqual(Double(out.count) / Double(rate), 1.51, accuracy: 0.011)
    }

    func testASentenceWithNothingAboveTheFloorStaysWhole() throws {
        // G3: silence, an empty sentence and one shorter than a frame come back as they went in — never less
        XCTAssertEqual(try trim.apply(silence(0.5), rate: rate).count, Int(0.5 * Double(rate)))
        XCTAssertEqual(try trim.apply([], rate: rate), [])
        XCTAssertEqual(try trim.apply([0.5, -0.5, 0.25], rate: rate), [0.5, -0.5, 0.25])
    }

    func testTheBreathGoesAndAQuietWordStays() throws {
        // G4: a breath at −56 dB of the peak is not speech; a word that starts at −42 dB is
        let breath = silence(0.3, level: 0.3 * 0.0016), word = speech(0.3, level: 0.3 * 0.008 * 1.414)
        let breathed = try trim.apply(silence(0.2) + breath + speech(0.5), rate: rate)
        XCTAssertEqual(Double(breathed.count) / Double(rate), 0.53, accuracy: 0.011)
        let hummed = try trim.apply(silence(0.2) + word + speech(0.5), rate: rate)
        XCTAssertEqual(Double(hummed.count) / Double(rate), 0.83, accuracy: 0.011)
    }

    func testTheMarginsStopAtTheSentence() throws {
        // G5: speech from the first sample to the last: nothing is cut and nothing runs past the ends
        let whole = speech(0.5)
        XCTAssertEqual(try trim.span(whole, rate: rate), 0..<whole.count)
    }

    func testABadRateIsAnError() {
        // G11: a zero rate is an error, not a crash and not an empty sentence
        XCTAssertThrowsError(try trim.apply([0.5], rate: 0)) { XCTAssertEqual($0 as? VoiceFXError, .badRate(0)) }
    }
}
