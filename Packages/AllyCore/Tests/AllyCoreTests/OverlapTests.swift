import AllyCore
import XCTest

/// D6.1 `duplex-audio`, the core: her speech over Elly's voice is only counted, and the microphone's ring reaches the
/// listening after the voice only with her speech in it. Frames are synthetic, 20 ms, on virtual time; the settings are
/// the shipped registry's.
final class OverlapTests: XCTestCase {
    private let frame = 0.02

    private func shipped() throws -> Hearing {
        try Hearing.decode(Data(contentsOf: appResources.appendingPathComponent("hearing.json")))
    }

    /// A run of her speech from `start` for `seconds`, framed by silence, fed to the counter.
    private func speak(_ counter: inout OverlapCounter, from start: Double, for seconds: Double) {
        let frames = Int((seconds / frame).rounded())
        for index in -2..<(frames + 2) {
            let time = start + Double(index) * frame
            counter.frame(speech: (0..<frames).contains(index), at: time, length: frame)
        }
    }

    func testOnlyEnoughSpeechOverTheVoiceIsCounted() throws {  // X18
        let overlap = try XCTUnwrap(try shipped().overlap)
        var counter = OverlapCounter(overlap)
        counter.voiceStarted()
        speak(&counter, from: 10.0, for: 0.3)
        XCTAssertEqual(counter.take(), 1)
        speak(&counter, from: 11.0, for: 0.2)
        XCTAssertEqual(counter.take(), 0)
        counter.voiceEnded(at: 12.0)
        speak(&counter, from: 12.5, for: 0.3)
        XCTAssertEqual(counter.take(), 1)
        counter.voiceStarted()
        counter.voiceEnded(at: 20.0)
        speak(&counter, from: 21.0, for: 0.3)
        XCTAssertEqual(counter.take(), 0)
        // The same 250 ms rule when the activity's flag rises only after that much speech (Silero): the rise counts.
        var silero = OverlapCounter(overlap, flagMinimum: 0.25)
        silero.voiceStarted()
        speak(&silero, from: 30.0, for: 0.04)
        XCTAssertEqual(silero.take(), 1)
    }

    /// 20 ms frames of a quiet remainder of Elly's voice, then her speech; `flag` — when the activity flags it.
    private func filledRing(speechFrom speech: Double?, flagFrom flag: Double?, until end: Double) throws
        -> (ring: VoiceRing<[Float]>, timing: TurnTiming) {
        let hearing = try shipped(), overlap = try XCTUnwrap(hearing.overlap)
        var ring = VoiceRing<[Float]>(seconds: hearing.turn.preRoll, lead: overlap.lead)
        for index in 0..<Int((end / frame).rounded()) {
            let time = Double(index) * frame, loud = speech.map { time >= $0 - 1e-9 } ?? false
            let samples = (0..<320).map { Float(sin(Double($0) * 0.3)) * (loud ? 0.3 : 0.001) }
            ring.add(samples, at: time, speech: flag.map { time >= $0 - 1e-9 } ?? false)
        }
        return (ring, hearing.turn)
    }

    func testHerSpeechOverTheVoiceReachesTheListeningFromItsFirstSyllable() throws {  // X11
        // She began at 9.0 s, a second before the voice ended; the activity flagged her 0.4 s late.
        var (ring, timing) = try filledRing(speechFrom: 9.0, flagFrom: 9.4, until: 10.0)
        let pieces = ring.handOver()
        XCTAssertEqual(pieces.count, 70)  // from 9.4 − 0.8 = 8.6 s to the voice's end
        XCTAssertTrue(ring.handOver().isEmpty)
        var detector = TurnDetector(kind: .open, timing: timing)
        var started: Double?
        for (index, samples) in pieces.enumerated() {
            if case .started(let at) = detector.process(samples, at: 8.6 + Double(index) * frame) { started = at }
        }
        XCTAssertEqual(started ?? -1, 9.04, accuracy: 1e-9)
        let loud = { (samples: [Float]) in samples.contains { abs($0) > 0.01 } }
        XCTAssertEqual(pieces.firstIndex(where: loud), 20)  // 8.6 s + 20 frames = 9.0 s, her first syllable
        XCTAssertEqual(detector.preRoll.count, 23)  // 8.6 … 9.04 s: the detector's pre-roll holds it too
        XCTAssertEqual(detector.preRoll.firstIndex(where: loud), 20)
    }

    func testARingWithoutHerSpeechStaysOutOfTheListening() throws {  // X19
        var (ring, _) = try filledRing(speechFrom: nil, flagFrom: nil, until: 10.0)
        XCTAssertTrue(ring.handOver().isEmpty)
        var (loud, _) = try filledRing(speechFrom: 9.0, flagFrom: 9.4, until: 10.0)
        loud.clear()
        XCTAssertTrue(loud.handOver().isEmpty)
    }
}
