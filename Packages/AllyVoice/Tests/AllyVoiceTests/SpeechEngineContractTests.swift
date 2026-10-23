import AllyVoice
import XCTest

/// The contract of `SpeechEngine`: what the app may rely on from any engine. Supertonic and a double pass the same
/// checks, so another engine is another implementation, not another app.
final class SpeechEngineContractTests: XCTestCase {
    func testDoubleKeepsTheContract() throws { // Z7
        try checkContract(ToneEngine())
    }

    func testSupertonicKeepsTheContract() throws { // Z7
        try checkContract(try Fixtures.engine())
    }

    private func checkContract(_ engine: SpeechEngine, file: StaticString = #filePath, line: UInt = #line) throws {
        for empty in ["", "   ", "\n"] {
            XCTAssertThrowsError(try engine.synthesize(empty, voice: VoicePreset()), file: file, line: line) { error in
                XCTAssertEqual(error as? SpeechError, .emptyText, file: file, line: line)
            }
        }
        XCTAssertThrowsError(try engine.synthesize("Привет!", voice: VoicePreset(speed: 0.5)), file: file, line: line)
        let audio = try engine.synthesize("Привет! Это я, Элли.", voice: VoicePreset())
        XCTAssertEqual(audio.rate, 44_100, file: file, line: line)
        XCTAssertGreaterThan(audio.duration, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(Double(audio.samples.count), audio.duration * 44_100, file: file, line: line)
        XCTAssertTrue(audio.samples.allSatisfy(\.isFinite), file: file, line: line)
    }
}

/// A double of the engine: a quiet tone, 60 ms a character, with the same refusals.
struct ToneEngine: SpeechEngine {
    func synthesize(_ text: String, voice: VoicePreset) throws -> SpeechAudio {
        guard voice.speed >= VoicePreset.minSpeed else { throw SpeechError.speedBelowFloor(voice.speed) }
        guard text.contains(where: { !$0.isWhitespace }) else { throw SpeechError.emptyText }
        let seconds = 0.06 * Double(text.count) / voice.speed, count = Int(seconds * 44_100)
        let samples = (0..<count).map { Float(0.1 * sin(2 * Double.pi * 440 * Double($0) / 44_100)) }
        return SpeechAudio(samples: samples, rate: 44_100, duration: seconds)
    }
}
