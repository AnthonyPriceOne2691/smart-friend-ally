import AllyCore
import ShellCore
import XCTest

/// One recorded frame of a motion: when, what was drawn, the weights of the groups.
struct Shot {
    let time: Double, frame: Frame, weights: [Double]
}

let step = 1.0 / 120

/// Steps a motion at 1/120 s along a script of (from second, phase) and records every frame.
func film(_ script: [(at: Double, phase: SessionState)], for seconds: Double, seed: UInt64 = 1, voice: Double? = nil,
          mic: Double? = nil, calm: Bool = false) -> [Shot] {
    let motion = Motion(seed: seed)
    return (0..<Int((seconds / step).rounded())).map { index in
        let start = Double(index) * step
        let phase = script.last { $0.at <= start + 1e-9 }?.phase ?? .asleep
        let frame = motion.step(step, phase: phase, voice: voice, mic: mic, calm: calm)
        return Shot(time: start + step, frame: frame, weights: motion.weights)
    }
}

/// The frame at second `t` of a film (frames come every 1/120 s).
func shot(_ shots: [Shot], at t: Double) -> Shot { shots[Int((t / step).rounded()) - 1] }

final class MotionTests: XCTestCase {
    func testPosesBlendLikeACriticallyDampedSpring() {  // V11
        let shots = film([(0, .listening), (2, .thinking)], for: 3)
        let thinks = Motion.Group.thinks.rawValue
        XCTAssertEqual(shot(shots, at: 2.1).weights[thinks], 0.30, accuracy: 0.02)
        XCTAssertEqual(shot(shots, at: 2.25).weights[thinks], 0.76, accuracy: 0.02)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 2.45).weights[thinks], 0.95)
        for frame in shots {
            XCTAssertTrue(frame.weights.allSatisfy { $0 >= -1e-9 && $0 <= 1 + 1e-9 }, "\(frame.time)")
            XCTAssertEqual(frame.weights.reduce(0, +), 1, accuracy: 0.001)
        }
    }

    /// Random scripts with a fixed seed: nothing jumps between two frames, switches included — a property.
    func testNothingJumpsAcrossPhaseSwitches() {  // V12
        var dice = Dice(seed: 2026)
        let phases: [SessionState] = [.asleep, .greeting, .listening, .thinking, .speaking, .windingDown, .goodbye]
        for scenario in 0..<100 {
            var script: [(at: Double, phase: SessionState)] = [], start = 0.0
            while start < 20 {
                script.append((start, phases[Int(dice.next() * 7) % 7]))
                start += 0.2 + 2.8 * dice.next()
            }
            let shots = film(script, for: 20, seed: UInt64(scenario), voice: dice.next(), mic: dice.next())
            for (before, after) in zip(shots, shots.dropFirst()) {
                let jumps = [jump(after.frame.angles, before.frame.angles) / 12,
                             jump(after.frame.offsets, before.frame.offsets) / 3,
                             jump(after.frame.shares, before.frame.shares) / 0.15,
                             abs(after.frame.eyeOpen - before.frame.eyeOpen) / 0.35]
                if let worst = jumps.max(), worst > 1 {
                    return XCTFail("scenario \(scenario) at \(after.time): \(jumps)")
                }
            }
        }
    }

    func testBlinksOnScheduleAndNeverInSleep() {  // V13
        let shots = film([(0, .asleep), (1, .listening)], for: 61, seed: 7)
        var starts: [Double] = [], lows: [Double] = [], ends: [Double] = []
        for (before, now) in zip(shots, shots.dropFirst()) where now.time > 1.5 {
            if now.frame.eyeOpen < 0.95, before.frame.eyeOpen >= 0.95 { starts.append(now.time); lows.append(1) }
            if now.frame.eyeOpen < 0.95, let last = lows.indices.last {
                lows[last] = min(lows[last], now.frame.eyeOpen)
            }
            if now.frame.eyeOpen >= 0.95, before.frame.eyeOpen < 0.95 { ends.append(now.time) }
        }
        XCTAssertTrue((10...26).contains(starts.count), "\(starts.count) blinks")
        XCTAssertEqual(starts.first ?? 0, 1 + 2.2, accuracy: 0.03)
        XCTAssertTrue(lows.allSatisfy { $0 < 0.1 })
        XCTAssertTrue(zip(starts, ends).allSatisfy { $1 - $0 <= 0.18 })
        let gaps = zip(starts, starts.dropFirst()).map { $1 - $0 }
        let doubles = gaps.filter { (0.26...0.31).contains($0) }
        XCTAssertTrue(gaps.allSatisfy { (0.26...0.31).contains($0) || (2.78...5.85).contains($0) }, "\(gaps)")
        XCTAssertLessThanOrEqual(doubles.count * 3, starts.count)
        for frame in film([(0, .asleep)], for: 20, seed: 7) {
            XCTAssertEqual(frame.frame.eyeOpen, 0.06, accuracy: 1e-9)
        }
    }

    func testWakingOpensEyesAndWaves() {  // V14
        let shots = film([(0, .asleep), (5, .greeting)], for: 8)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 5.45).frame.eyeOpen, 0.95)
        XCTAssertGreaterThanOrEqual(shot(shots, at: 5.45).frame.pose.gillLift, 2.5)
        for frame in shots where frame.time >= 5.6 {
            XCTAssertEqual(frame.frame.pose.armRight, -128, accuracy: 22, "\(frame.time)")
        }
    }

    func testGoodbyeYawnsThenSleepsAndAStopDoesNot() {  // V15
        let goodbye = film([(0, .goodbye), (2, .asleep)], for: 6)
        let yawn = shot(goodbye, at: 3.2).frame.pose
        XCTAssertGreaterThanOrEqual(yawn.mouthOpen, 0.9)
        XCTAssertGreaterThanOrEqual(yawn.mouthTall, 1.5)
        XCTAssertGreaterThanOrEqual(yawn.armLeft, 140)
        XCTAssertLessThanOrEqual(yawn.armRight, -140)
        XCTAssertGreaterThanOrEqual(yawn.eyesShut, 0.85)
        let asleep = shot(goodbye, at: 5.5).frame.pose
        XCTAssertEqual(asleep.eyesShut, 1, accuracy: 0.01)
        XCTAssertEqual(asleep.gillLift, -16, accuracy: 0.5)
        XCTAssertLessThanOrEqual(asleep.mouthOpen, 0.02)
        let stopped = film([(0, .speaking), (2, .asleep)], for: 6).filter { $0.time > 2 }
        XCTAssertTrue(stopped.allSatisfy { abs($0.frame.pose.mouthTall - 1) < 1e-9 })
        let mouths = stopped.map(\.frame.pose.mouthOpen)
        XCTAssertTrue(zip(mouths, mouths.dropFirst()).allSatisfy { $1 <= $0 + 1e-6 })
    }

    func testReduceMotionKeepsTwoFifthsOfTheSwing() {  // V17
        let calm = Swing(calm: true), full = Swing(calm: false)
        XCTAssertTrue(calm.head.lowerBound >= 7.52 - 1e-6 && calm.head.upperBound <= 8.48 + 1e-6, "\(calm.head)")
        XCTAssertTrue(calm.rise.lowerBound >= 0.8 - 1e-6 && calm.rise.upperBound <= 3.2 + 1e-6, "\(calm.rise)")
        XCTAssertEqual(calm.gill, 2 * 1.0, accuracy: 0.05)
        XCTAssertEqual(full.gill, 2 * 2.5, accuracy: 0.05)
        XCTAssertGreaterThan(full.head.upperBound - full.head.lowerBound, 2)
        let pose = film([(0, .listening)], for: 2, calm: true).last?.frame.pose
        XCTAssertEqual(pose?.gillLift ?? 0, 8, accuracy: 1e-3)
        XCTAssertEqual(pose?.armLeft ?? 0, -32, accuracy: 1e-3)
        XCTAssertEqual(pose?.armRight ?? 0, 32, accuracy: 1e-3)
    }

    private func jump(_ now: [Double], _ before: [Double]) -> Double {
        zip(now, before).map { abs($0 - $1) }.max() ?? 0
    }
}

/// How far listening swings over 1…30 s: the head's tilt, the float, the top gill (no voice, so no flutter).
struct Swing {
    let head: ClosedRange<Double>, rise: ClosedRange<Double>, gill: Double

    init(calm: Bool) {
        let shots = film([(0, .listening)], for: 30, mic: 0, calm: calm).filter { $0.time >= 1 }
        let heads = shots.map(\.frame.pose.headTilt), rises = shots.map(\.frame.rise)
        let gills = shots.map { $0.frame.gills[0] }
        head = (heads.min() ?? 0)...(heads.max() ?? 0)
        rise = (rises.min() ?? 0)...(rises.max() ?? 0)
        gill = (gills.max() ?? 0) - (gills.min() ?? 0)
    }
}

/// A small fixed-seed generator for test scripts.
struct Dice {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}
