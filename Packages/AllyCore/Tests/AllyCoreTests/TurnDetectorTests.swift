import AllyCore
import XCTest

/// The registry's end-of-speech timing; frames of 20 ms at 16 kHz.
let registryTiming = TurnTiming(tails: ["open": 1.8, "closed": 0.8, "counting": 2.5], tentative: 0.3, preRoll: 1.5,
                                maxTurn: 20)
let frameSeconds = 0.02

/// An event heard: its name, the time of its frame, the time it names.
struct Heard { let name: String, at: Double, time: Double }

/// The events over segments of a constant level (seconds, dBFS).
func events(_ kind: TurnKind, _ segments: [(Double, Float)]) -> [Heard] {
    var detector = TurnDetector(kind: kind, timing: registryTiming), out: [Heard] = []
    let frames = segments.flatMap { seconds, db in
        Array(repeating: [Float](repeating: pow(10, db / 20), count: 320), count: Int((seconds / 0.02).rounded()))
    }
    for (index, samples) in frames.enumerated() {
        let at = Double(index) * frameSeconds
        switch detector.process(samples, at: at) {
        case .started(let time)?: out.append(Heard(name: "started", at: at, time: time))
        case .tentativeEnd(let last)?: out.append(Heard(name: "tentative", at: at, time: last))
        case .resumed(let time)?: out.append(Heard(name: "resumed", at: at, time: time))
        case let .ended(last, byLimit)?: out.append(Heard(name: byLimit ? "limit" : "ended", at: at, time: last))
        case nil: break
        }
    }
    return out
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

    func testTentativeEndAndResume() {  // A27
        let heard = events(.open, [(0.5, -60), (1.0, -40), (0.5, -60), (1.0, -40), (3.0, -60)])
        XCTAssertEqual(heard.map(\.name), ["started", "tentative", "resumed", "tentative", "ended"])
        XCTAssertEqual(heard.count == 5 ? heard[1].at - heard[1].time : 0, 0.3, accuracy: frameSeconds)
        XCTAssertEqual(heard.count == 5 ? heard[4].at - heard[4].time : 0, 1.8, accuracy: frameSeconds)
    }
}
