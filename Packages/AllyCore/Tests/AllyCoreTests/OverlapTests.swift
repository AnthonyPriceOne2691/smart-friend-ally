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

    /// The voice's sound comes from the player: a sentence of 1 s from 0.05 s, then one from 2.05 s cut by a stop at
    /// 2.5 s. Her 300 ms of speech while it sounds counts, 0.5 s after its end counts, 1.0 s after does not; the cut
    /// one's end is the stop's moment, and a player that returns late still ends the voice at its last sample.
    func testTheVoicesWindowComesFromThePlayersSound() async throws {  // X18
        let clock = TestClock(), overlap = try XCTUnwrap(try shipped().overlap)
        let counter = Locked(OverlapCounter(overlap)), ends = Locked([Double]())
        let sounding = { (player: SoundPlayer) in
            SoundingPlayer(player, clock: clock, began: { counter { $0.voiceStarted() } },
                           ended: { end in counter { $0.voiceEnded(at: end) }; ends { $0.append(end) } })
        }
        let player = sounding(ClockPlayer(clock: clock))
        let first = Task { await player.play([Float](repeating: 0.1, count: 1000), rate: 1000) }
        await eventually { clock.sleeping == 1 }
        counter { (counter: inout OverlapCounter) in speak(&counter, from: 0.5, for: 0.3) }
        XCTAssertEqual(counter { $0.take() }, 1)
        clock.advance(by: 1.05)
        _ = await first.value
        XCTAssertEqual(ends { $0 }.first ?? -1, 1.05, accuracy: 1e-9)
        counter { (counter: inout OverlapCounter) in speak(&counter, from: 1.55, for: 0.3) }
        XCTAssertEqual(counter { $0.take() }, 1)
        counter { (counter: inout OverlapCounter) in speak(&counter, from: 2.05, for: 0.3) }
        XCTAssertEqual(counter { $0.take() }, 0)
        clock.advance(to: 2.0)
        let second = Task { await player.play([Float](repeating: 0.1, count: 1000), rate: 1000) }
        await eventually { clock.sleeping == 1 }
        clock.advance(by: 0.5)
        player.stop()
        let cut = await second.value
        XCTAssertTrue(cut.cut)
        XCTAssertEqual(ends { $0 }.last ?? -1, 2.5, accuracy: 0.002)  // whole frames played: within one at 1 kHz
        _ = await sounding(LatePlayer(clock: clock, sound: 1.0, returnsAfter: 1.25)).play([0.1], rate: 1000)
        XCTAssertEqual(ends { $0 }.last ?? -1, 2.5 + 1.0, accuracy: 1e-9)
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

/// A player double whose sound lasts `sound` seconds from now but whose `play` returns `returnsAfter` seconds later —
/// as a real buffer's completion comes after its last sample.
final class LatePlayer: SoundPlayer, @unchecked Sendable {
    private let clock: TestClock, sound: Double, returnsAfter: Double

    init(clock: TestClock, sound: Double, returnsAfter: Double) {
        (self.clock, self.sound, self.returnsAfter) = (clock, sound, returnsAfter)
    }

    func play(_ samples: [Float], rate: Int) async -> Played {
        let started = clock.now()
        clock.advance(by: returnsAfter)
        return Played(started: started, frames: Int(sound * Double(rate)), cut: false)
    }

    func stop() {}
}
