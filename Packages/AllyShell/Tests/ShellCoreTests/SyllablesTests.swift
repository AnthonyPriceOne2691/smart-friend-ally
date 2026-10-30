import AllyCore
import ShellCore
import XCTest

final class SyllablesTests: XCTestCase {
    /// 10 s of speech without a voice level, seed 1: the syllables, words and phrases of the example and the mouth
    /// over them.
    func testTheMouthGoesBySyllablesWordsAndPhrases() {  // V34
        var rhythm = Syllables(seed: 1), heard: [Syllables.Syllable] = [], mouth: [(time: Double, open: Double)] = []
        for index in 1...1200 {
            let time = Double(index) * step
            mouth.append((time, 0.05 + 0.95 * rhythm.step(step, at: time, speaking: true)))
            if let now = rhythm.current, heard.last != now { heard.append(now) }
        }
        let spoken = heard.filter { $0.start < 10 }, gaps = zip(spoken, spoken.dropFirst()).map { $1.start - $0.end }
        XCTAssertTrue((39...44).contains(spoken.count), "\(spoken.count) syllables")
        XCTAssertTrue(spoken.allSatisfy { (0.16...0.22).contains($0.end - $0.start) && (0.62...1).contains($0.peak) })
        XCTAssertTrue(gaps.allSatisfy { gap in [0, 0.06, 0.36].contains { abs(gap - $0) < 1e-9 } }, "\(gaps)")
        let words = runs(gaps, longer: 0.03), phrases = runs(gaps, longer: 0.2)
        XCTAssertTrue(words.allSatisfy { (1...4).contains($0) }, "\(words)")
        XCTAssertTrue(phrases.count >= 3 && phrases.dropLast().allSatisfy { (8...14).contains($0) }
                      && (phrases.last ?? 0) <= 14, "\(phrases)")
        for second in 0..<10 {
            let opens = mouth.filter { $0.time > Double(second) && $0.time <= Double(second + 1) }.map(\.open)
            XCTAssertGreaterThanOrEqual(opens.max() ?? 0, 0.55, "second \(second)")
        }
        for (last, next) in zip(spoken, spoken.dropFirst()) where next.start - last.end > 0.2 && next.start <= 10 {
            let opens = mouth.filter { $0.time > last.end && $0.time < next.start }.map(\.open)
            XCTAssertLessThanOrEqual(opens.min() ?? 1, 0.1, "the phrase's pause at \(last.end)")
        }
        XCTAssertLessThanOrEqual(zip(mouth, mouth.dropFirst()).map { abs($1.open - $0.open) }.max() ?? 1, 0.09)
    }

    /// In `Motion` the rhythm — the generator above with the same seed — leads her mouth, head, hands and gills while
    /// she greets, speaks and says goodbye, and fades to 0 in the other phases; a voice level passed in goes as is.
    func testTheRhythmLeadsHerOnlyWhileSheSpeaks() {  // V34
        let motion = Motion(seed: 1)
        var rhythm = Syllables(seed: 1), time = 0.0
        for phase in [SessionState.greeting, .speaking, .goodbye, .listening, .thinking] {
            let speaks = [.greeting, .speaking, .goodbye].contains(phase)
            for index in 1...360 {
                time += step
                let pose = motion.step(step, phase: phase).pose, level = motion.voiceLevel
                XCTAssertEqual(level, rhythm.step(step, at: time, speaking: speaks), accuracy: 1e-12, "\(phase)")
                guard index > 120 else { continue }
                guard speaks else {
                    XCTAssertLessThanOrEqual(level, 0.001, "\(phase)")
                    continue
                }
                XCTAssertEqual(pose.mouthOpen, 0.05 + 0.95 * level, accuracy: 0.01)
                XCTAssertEqual(pose.headY, -2.2 * level, accuracy: 0.01)
                XCTAssertEqual(pose.gillLift, 2 + 3 * level, accuracy: 0.01)
                XCTAssertTrue(level < 0.1 || (8.9...30.1).contains((pose.armLeft - 24) / level), "\(phase)")
            }
        }
        for _ in 1...120 { _ = motion.step(step, phase: .speaking, voice: 0.3) }
        XCTAssertEqual(motion.voiceLevel, 0.3)
        XCTAssertEqual(motion.step(step, phase: .speaking, voice: 0.3).pose.mouthOpen, 0.335, accuracy: 0.01)
    }

    /// Lengths of the runs of syllables between gaps longer than `pause`; the last one may be cut by the end.
    private func runs(_ gaps: [Double], longer pause: Double) -> [Int] {
        var runs = [1]
        for gap in gaps {
            if gap > pause { runs.append(1) } else { runs[runs.count - 1] += 1 }
        }
        return runs
    }
}
