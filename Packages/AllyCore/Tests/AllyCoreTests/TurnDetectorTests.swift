import AllyCore
import XCTest

/// The registry's end-of-speech timing; frames of 20 ms at 16 kHz.
let registryTiming = TurnTiming(tails: ["open": 1.8, "closed": 0.8, "counting": 2.5], tentative: 0.3, preRoll: 1.5,
                                maxTurn: 20)
let frameSeconds = 0.02

/// An event heard: its name, the time of its frame, the time it names.
struct Heard { let name: String, at: Double, time: Double }

/// The events over segments of a constant level (seconds, dBFS); her «я всё» asked before the frame at `doneAt`.
func events(_ kind: TurnKind, _ segments: [(Double, Float)], timing: TurnTiming = registryTiming,
            doneAt: Double? = nil) -> [Heard] {
    let ending = TurnEnding()
    var detector = TurnDetector(kind: kind, timing: timing, ending: ending), out: [Heard] = []
    let frames = segments.flatMap { seconds, db in
        Array(repeating: [Float](repeating: pow(10, db / 20), count: 320), count: Int((seconds / 0.02).rounded()))
    }
    for (index, samples) in frames.enumerated() {
        let at = Double(index) * frameSeconds
        if let doneAt, abs(at - doneAt) < frameSeconds / 2 { ending.ask() }
        if let event = heard(detector.process(samples, at: at), at: at) { out.append(event) }
    }
    return out
}

/// An event of the detector as the tests name it.
func heard(_ event: TurnEvent?, at: Double) -> Heard? {
    switch event {
    case .started(let time)?: Heard(name: "started", at: at, time: time)
    case .tentativeEnd(let last)?: Heard(name: "tentative", at: at, time: last)
    case .resumed(let time)?: Heard(name: "resumed", at: at, time: time)
    case let .ended(last, byLimit)?: Heard(name: byLimit ? "limit" : "ended", at: at, time: last)
    case nil: nil
    }
}

/// A model's flag per window (Silero through sherpa: 32 ms), `lag` behind the speech it marks.
struct FlagActivity: VoiceActivity {
    var flags: [Bool]
    let lag: Double

    mutating func loud(_ samples: [Float]) -> Bool? { flags.isEmpty ? false : flags.removeFirst() }

    mutating func reset() {}
}

/// The last voiced frame of each end by the tail.
func endings(_ kind: TurnKind, _ segments: [(Double, Float)]) -> [Double] {
    events(kind, segments).filter { $0.name == "ended" }.map(\.time)
}

final class TurnDetectorTests: XCTestCase {
    func testSilenceStartEndAndShift() {  // A17
        XCTAssertTrue(events(.closed, [(10, -80)]).isEmpty)
        let speech: [(Double, Float)] = [(0.5, -60), (1.0, -40), (2.0, -60)]
        let heard = events(.closed, speech), shifted = events(.closed, [(1.0, -80)] + speech)
        XCTAssertEqual([heard.filter { $0.name == "started" }.count, endings(.closed, speech).count], [1, 1])
        XCTAssertEqual(endings(.closed, speech).first ?? -1, 1.48, accuracy: 1e-6)
        XCTAssertEqual(shifted.map(\.name), heard.map(\.name))
        for (before, after) in zip(heard, shifted) { XCTAssertEqual(after.time - before.time, 1.0, accuracy: 1e-6) }
    }

    func testTailIsTheTurnKinds() {  // A25
        let pause12: [(Double, Float)] = [(0.5, -60), (1.0, -40), (1.2, -60), (1.0, -40), (3.0, -60)]
        let pause20: [(Double, Float)] = [(0.5, -60), (1.0, -40), (2.0, -60), (1.0, -40), (3.0, -60)]
        XCTAssertEqual(endings(.closed, pause12).first ?? -1, 1.48, accuracy: 1e-6)
        for kind in [TurnKind.open, .counting] { XCTAssertEqual(endings(kind, pause12).count, 1) }
        XCTAssertEqual(endings(.open, pause12).first ?? -1, 3.68, accuracy: 1e-6)
        XCTAssertEqual(endings(.counting, pause12).first ?? -1, 3.68, accuracy: 1e-6)
        XCTAssertEqual(endings(.open, pause20).first ?? -1, 1.48, accuracy: 1e-6)
        XCTAssertEqual(endings(.counting, pause20).count, 1)
        XCTAssertEqual(endings(.counting, pause20).first ?? -1, 4.48, accuracy: 1e-6)
    }

    func testPreRollGoesWithTheStartAndTheTurnHasALimit() {  // A26
        var detector = TurnDetector(kind: .open, timing: registryTiming), preRoll = 0
        let quiet = [Float](repeating: 0.001, count: 320), loud = [Float](repeating: 0.01, count: 320)
        for index in 0..<150 where detector.process(index < 100 ? quiet : loud, at: Double(index) * 0.02) != nil {
            preRoll = detector.preRoll.count
        }
        XCTAssertGreaterThanOrEqual(Double(preRoll) * frameSeconds, 1.5)
        let long = events(.open, [(0.5, -60), (25, -40)])
        XCTAssertEqual(long.prefix(2).map(\.name), ["started", "limit"])
        XCTAssertEqual(long.count > 1 ? long[1].at - long[0].at : 0, 20, accuracy: frameSeconds)
    }

    func testDoneEndsTheTurnOnTheNextFrame() {  // U4
        let speech: [(Double, Float)] = [(0.5, -60), (1.0, -40), (3.0, -60)]
        let done = events(.open, speech, doneAt: 1.90).filter { $0.name == "ended" || $0.name == "limit" }
        XCTAssertEqual(done.map(\.name), ["ended"])
        XCTAssertEqual(done.first?.at ?? -1, 1.90, accuracy: 1e-6)
        XCTAssertEqual(done.first?.time ?? -1, 1.48, accuracy: 1e-6)
        let tail = events(.open, speech).filter { $0.name == "ended" }
        XCTAssertEqual(tail.first?.at ?? -1, 3.28, accuracy: 1e-6)
        let early = events(.open, [(1.0, -60)], doneAt: 0.30)
        XCTAssertEqual(early.map(\.name), ["ended"])
        XCTAssertEqual(early.first?.at ?? -1, 0.30, accuracy: 1e-6)
    }

    func testTheRegistrysLimitEndsContinuousSpeech() throws {  // U5
        let hearing = try Hearing.decode(Data(contentsOf: appResources.appendingPathComponent("hearing.json")))
        let long = events(.open, [(0.5, -60), (35, -40)], timing: hearing.turn)
        XCTAssertEqual(long.prefix(2).map(\.name), ["started", "limit"])
        XCTAssertEqual(long.first?.at ?? -1, 0.54, accuracy: 1e-6)
        XCTAssertEqual(long.count > 1 ? long[1].at - long[0].at : 0, 30, accuracy: frameSeconds)
    }

    /// Silero's policy (D7.2): the flag on windows 10…49 of 32 ms, 0.128 s behind the speech; the open turn's timing of
    /// the registry. Its silence counts from the speech: the tentative end and the end come 0.172 and 1.672 s after the
    /// last flagged window — on the first window that far, not one window earlier.
    func testSilenceCountsFromTheSpeechBehindTheFlag() throws {  // U18
        let hearing = try Hearing.decode(Data(contentsOf: appResources.appendingPathComponent("hearing.json")))
        let window = 0.032, flagged = 10..<50, last = Double(flagged.upperBound - 1) * window
        let flags = FlagActivity(flags: (0..<200).map(flagged.contains), lag: 0.128)
        var detector = TurnDetector(kind: .open, timing: hearing.turn, activity: flags), out: [Heard] = []
        for index in 0..<200 {
            if let event = heard(detector.process([0.1], at: Double(index) * window), at: Double(index) * window) {
                out.append(event)
            }
        }
        XCTAssertEqual(out.map(\.name), ["started", "tentative", "ended"])
        guard out.count == 3 else { return }
        XCTAssertEqual([out[1].time, out[2].time], [last - 0.128, last - 0.128])
        for (event, after) in [(out[1], 0.172), (out[2], 1.672)] {
            XCTAssertGreaterThanOrEqual(event.at - last, after - 1e-9)
            XCTAssertLessThan(event.at - window - last, after - 1e-9)
        }
    }

    func testTentativeEndAndResume() {  // A27
        let heard = events(.open, [(0.5, -60), (1.0, -40), (0.5, -60), (1.0, -40), (3.0, -60)])
        XCTAssertEqual(heard.map(\.name), ["started", "tentative", "resumed", "tentative", "ended"])
        XCTAssertEqual(heard.count == 5 ? heard[1].at - heard[1].time : 0, 0.3, accuracy: frameSeconds)
        XCTAssertEqual(heard.count == 5 ? heard[4].at - heard[4].time : 0, 1.8, accuracy: frameSeconds)
    }
}
