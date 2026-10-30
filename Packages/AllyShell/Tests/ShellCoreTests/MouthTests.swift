import AllyCore
import ShellCore
import XCTest

/// A made-up talk: the phases by seconds and the spans when her voice sounds. Her phases of speech begin with the
/// making of the first phrase (0.3–1.4 s of silence), then 1–4 phrases of 0.6–2.5 s with pauses of 0.35–0.6 s,
/// sometimes cut in the middle; half of them never sound at all — the input's own «none» mode (L127).
struct Talk {
    var script: [(at: Double, phase: SessionState)] = [], spans: [(from: Double, to: Double)] = []

    func phase(at time: Double) -> SessionState { script.last { $0.at <= time + 1e-9 }?.phase ?? .asleep }
    func sounds(at time: Double) -> Bool { spans.contains { $0.from <= time && time < $0.to } }

    /// Seconds since the last sound ended, infinite before any.
    func silence(at time: Double) -> Double {
        spans.filter { $0.to <= time }.map { time - $0.to }.min() ?? .infinity
    }

    static func made(seconds: Double, dice: inout Dice) -> Talk {
        let phases: [SessionState] = [.asleep, .greeting, .listening, .thinking, .speaking, .windingDown, .goodbye]
        var talk = Talk(), start = 0.0
        while start < seconds {
            let phase = phases[Int(dice.next() * 7) % 7]
            talk.script.append((start, phase))
            if TalkState(phase: phase).pose != .speaks {
                start += 0.2 + 2.8 * dice.next()
            } else if dice.next() < 0.5 {
                start += 0.3 + 1.7 * dice.next()
            } else {
                start = talk.speak(from: start, dice: &dice)
            }
        }
        return talk
    }

    /// The phrases of one phase of speech; the moment it ends — a cut ends it inside its last phrase, at once.
    private mutating func speak(from start: Double, dice: inout Dice) -> Double {
        var time = start + 0.3 + 1.1 * dice.next()
        for _ in 0...Int(dice.next() * 3.99) {
            let end = time + 0.6 + 1.9 * dice.next()
            spans.append((time, end))
            time = end + 0.35 + 0.25 * dice.next()
        }
        guard let last = spans.last, dice.next() < 0.3 else { return time }
        let cut = last.from + (last.to - last.from) * dice.next()
        spans[spans.count - 1] = (last.from, cut)
        return cut
    }
}

/// Her mouth and her talking pose go by the sound of her voice, not by the session's phase (examples N1–N5 signed by
/// the parent 2026-10-30): «рот двигается, а она еще ничего, короче, не сказала».
final class MouthTests: XCTestCase {
    private let thinks = Motion.Group.thinks.rawValue, talks = Motion.Group.talks.rawValue
    private let waves = Motion.Group.waves.rawValue, listens = Motion.Group.listens.rawValue

    private func spans(_ spans: (Double, Double)...) -> (Double) -> Bool {
        { time in spans.contains { $0.0 <= time && time < $0.1 } }
    }

    private func peak(_ shots: [Shot], from: Double, to: Double) -> Double {
        shots.filter { $0.time >= from && $0.time < to }.map(\.level).max() ?? 0
    }

    func testWhileTheFirstPhraseIsMadeSheThinksWithHerMouthShut() {  // N1
        let shots = film([(0, .thinking), (2, .speaking)], for: 4.6, sound: spans((2.9, 4.4)))
        for shot in shots where shot.time >= 2 && shot.time < 2.9 {
            XCTAssertLessThanOrEqual(shot.level, 0.02, "\(shot.time)")
            XCTAssertLessThanOrEqual(shot.frame.pose.mouthOpen, 0.02, "\(shot.time)")
            XCTAssertGreaterThanOrEqual(shot.weights[thinks], 0.9, "\(shot.time)")
        }
        XCTAssertGreaterThanOrEqual(peak(shots, from: 2.9, to: 3.4), 0.6)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 3.5).weights[talks], 0.9)
    }

    func testBetweenPhrasesHerMouthIsShutAndSheStaysTalking() {  // N2
        let shots = film([(0, .thinking), (2, .speaking)], for: 6.5, sound: spans((2.9, 4.4), (4.85, 6.0)))
        for shot in shots where shot.time >= 4.52 && shot.time < 4.85 {
            XCTAssertLessThanOrEqual(shot.level, 0.05, "\(shot.time)")
            XCTAssertGreaterThanOrEqual(shot.weights[talks], 0.9, "\(shot.time)")
        }
        XCTAssertGreaterThanOrEqual(peak(shots, from: 4.85, to: 5.35), 0.6)
    }

    /// The cut falls where her mouth is widest in this seed; the stop puts her to sleep 0.1 s later (the spec's 1.5 s
    /// and 1.6 s after the phrase began to be made).
    func testACutClosesHerMouthAtOnce() {  // N3
        let open = film([(0, .thinking), (2, .speaking)], for: 4.4, sound: spans((2.9, 4.4)))
        let widest = open.filter { $0.time > 3 }.max { $0.level < $1.level }
        let cut = widest?.time ?? 3.5, level = widest?.level ?? 0
        XCTAssertGreaterThanOrEqual(level, 0.6)
        let shots = film([(0, .thinking), (2, .speaking), (cut + 0.1, .asleep)], for: cut + 1, sound: spans((2.9, cut)))
        XCTAssertEqual(shot(shots, at: cut).level, level, accuracy: 0.11)
        XCTAssertLessThanOrEqual(shot(shots, at: cut + 0.12).level, 0.05)
    }

    func testShePreparesHerGreetingAwakeWithoutWaving() {  // N4
        let shots = film([(0, .asleep), (2, .greeting)], for: 5, sound: spans((3.1, 5)))
        for shot in shots where shot.time >= 2 && shot.time < 3.1 {
            XCTAssertLessThanOrEqual(shot.level, 0.02, "\(shot.time)")
            XCTAssertLessThanOrEqual(shot.weights[waves], 0.1, "\(shot.time)")
        }
        XCTAssertGreaterThanOrEqual(shot(shots, at: 3.05).weights[listens], 0.9)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 3.05).frame.eyeOpen, 0.95)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 3.7).weights[waves], 0.9)
        XCTAssertGreaterThanOrEqual(peak(shots, from: 3.1, to: 3.6), 0.6)
    }

    /// 200 talks of 30 s with a fixed seed, every other with a voice level passed in: out of the sound and 0.12 s after
    /// it the mouth is shut (the yawn after a goodbye is not speech), and in the sound it does open.
    func testTheMouthOpensOnlyWhileHerVoiceSounds() {  // N5
        var dice = Dice(seed: 2030), widest = 0.0
        let dozes = Motion.Group.dozes.rawValue
        for scenario in 0..<200 {
            let talk = Talk.made(seconds: 30, dice: &dice), voice = scenario.isMultiple(of: 2) ? nil : dice.next()
            let motion = Motion(seed: UInt64(scenario))
            for index in 0..<Int(30 / step) {
                let time = Double(index) * step, sound = talk.sounds(at: time)
                let pose = motion.step(step, phase: talk.phase(at: time), sound: sound, voice: voice).pose
                if sound, voice == nil { widest = max(widest, motion.voiceLevel) }
                guard !sound, talk.silence(at: time + step) > 0.12 else { continue }
                XCTAssertLessThanOrEqual(motion.voiceLevel, 0.05, "scenario \(scenario) at \(time)")
                guard motion.weights[dozes] < 0.01 else { continue }
                XCTAssertLessThanOrEqual(pose.mouthOpen, 0.1, "scenario \(scenario) at \(time)")
            }
        }
        XCTAssertGreaterThanOrEqual(widest, 0.6)
    }
}
