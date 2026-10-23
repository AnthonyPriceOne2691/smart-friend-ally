import AllyCore
import ShellCore
import XCTest

let phases: [SessionState] = [.asleep, .greeting, .listening, .thinking, .speaking, .windingDown, .goodbye]
let moments = stride(from: 0.0, through: 60, by: 0.25).map { $0 }

final class PoseTests: XCTestCase {
    func testAsleepEyesShutGillsDownSlowBreath() {  // V1
        for t in moments {
            let pose = Pose.at(.asleep, time: t), frame = Frame.at(.asleep, time: t)
            XCTAssertEqual(pose.eyesShut, 1)
            XCTAssertEqual(frame.eyeballs, 0)
            XCTAssertEqual(frame.lids, 1)
            XCTAssertEqual([pose.gillLift, pose.gillSpread], [-16, -4])
            XCTAssertEqual(pose.headTilt, 9, accuracy: 1)
            XCTAssertEqual([pose.mouthOpen, pose.smile, pose.bodyY], [0, 0.8, 10])
        }
        let period = 2 * Double.pi / 1.3
        XCTAssertEqual(period, 4.83, accuracy: 0.005)
        XCTAssertGreaterThanOrEqual(period, 3)  // rule 10: a resting loop of 3 s or longer
        let breaths = stride(from: 0.0, to: period, by: 0.01).map { Frame.at(.asleep, time: $0).breath }
        XCTAssertEqual(breaths.max() ?? 0, 0.028, accuracy: 0.0001)
        XCTAssertEqual(breaths.min() ?? 0, -0.028, accuracy: 0.0001)
        XCTAssertEqual(Frame.at(.asleep, time: 1 + period).breath, Frame.at(.asleep, time: 1).breath, accuracy: 1e-9)
    }

    func testListeningGillsUpHandsFoldedWindingDownSame() {  // V2
        let levels: [(mic: Double?, flutter: Double)] = [(0, 0), (1, 5), (nil, 2.5)]
        for (mic, flutter) in levels {
            for t in moments {
                let pose = Pose.at(.listening, time: t, mic: mic)
                XCTAssertEqual([pose.gillLift, pose.gillSpread, pose.gillScale, pose.gillFlutter],
                               [8, 10, 1.06, flutter])
                XCTAssertEqual(pose.headTilt, 8, accuracy: 1.2)
                XCTAssertEqual([pose.eyeWide, pose.browY, pose.armLeft, pose.armRight, pose.mouthOpen],
                               [1.06, -3, -32, 32, 0])
                XCTAssertEqual(Pose.at(.windingDown, time: t, mic: mic), pose)
                XCTAssertEqual(Frame.at(.windingDown, time: t, mic: mic), Frame.at(.listening, time: t, mic: mic))
            }
        }
        XCTAssertEqual(Gill.spread.map { $0 * 10 }, [10, 3, -6])
    }

    func testThinkingEyesUpHandAtChin() {  // V3
        for t in moments {
            let pose = Pose.at(.thinking, time: t)
            XCTAssertEqual(pose.eyeY, -7.5)
            XCTAssertEqual(pose.eyeX, 4, accuracy: 1.2)
            XCTAssertEqual(pose.armRight, 126, accuracy: 3)
            XCTAssertEqual([pose.armLeft, pose.mouthWidth, pose.smile, pose.gillCount], [18, 0.6, 0.6, 1])
        }
    }

    func testSpeakingMouthFollowsVoiceGreetingWaves() {  // V4
        for (voice, mouth) in [(0.0, 0.05), (0.5, 0.525), (1.0, 1.0)] {
            for t in moments {
                let pose = Pose.at(.speaking, time: t, voice: voice)
                XCTAssertEqual(pose.mouthOpen, mouth, accuracy: 1e-9)
                XCTAssertEqual(pose.gillLift, 2 + 3 * voice, accuracy: 1e-9)
                XCTAssertGreaterThanOrEqual(pose.armLeft, 24 + 9 * voice - 1e-9)
                XCTAssertLessThanOrEqual(pose.armLeft, 24 + 30 * voice + 1e-9)
            }
        }
        XCTAssertEqual(Pose.at(.speaking, time: 3).mouthOpen, 0.62, accuracy: 1e-9)
        for phase in [SessionState.greeting, .goodbye] {
            for t in moments {
                XCTAssertEqual(Pose.at(phase, time: t).armRight, -128, accuracy: 20 + 1e-9)
            }
            let crest = 1 / (4 * 1.3)  // a quarter of a wave at 1.3 Hz
            XCTAssertEqual(Pose.at(phase, time: crest).armRight, -108, accuracy: 1e-9)
            XCTAssertEqual(Pose.at(phase, time: 3 * crest).armRight, -148, accuracy: 1e-9)
        }
    }

    func testPoseFollowsTheSessionsGrouping() {  // V5
        let expected: [SessionState: TalkState.Pose] = [
            .asleep: .sleeps, .listening: .listens, .windingDown: .listens, .thinking: .thinks,
            .greeting: .speaks, .speaking: .speaks, .goodbye: .speaks
        ]
        XCTAssertEqual(Set(phases), Set(expected.keys))
        for phase in phases {
            XCTAssertEqual(TalkState(phase: phase).pose, expected[phase])
        }
        for t in moments {
            var greeting = Pose.at(.greeting, time: t), goodbye = Pose.at(.goodbye, time: t)
            var speaking = Pose.at(.speaking, time: t)
            (greeting.armRight, goodbye.armRight, speaking.armRight) = (0, 0, 0)
            XCTAssertEqual(greeting, speaking)
            XCTAssertEqual(goodbye, speaking)
            XCTAssertEqual(Pose.at(.windingDown, time: t), Pose.at(.listening, time: t))
            XCTAssertEqual(phases.filter { Pose.at($0, time: t).eyesShut == 1 }, [.asleep])
            XCTAssertEqual(phases.filter { Pose.at($0, time: t).gillCount == 1 }, [.thinking])
        }
    }

    /// No part jumps between two frames 1/120 s apart within a phase — a property, no expected numbers in it.
    func testNothingJumpsBetweenFrames() {  // V9
        let step = 1.0 / 120
        for phase in phases {
            for level in [Double?.none, 0, 1] {
                var previous = Frame.at(phase, time: 0, voice: level, mic: level)
                for index in 1...3600 {
                    let frame = Frame.at(phase, time: Double(index) * step, voice: level, mic: level)
                    assertClose(frame.angles, previous.angles, within: 1.5, phase)
                    assertClose(frame.offsets, previous.offsets, within: 0.5, phase)
                    assertClose(frame.shares, previous.shares, within: 0.05, phase)
                    previous = frame
                }
            }
        }
    }

    private func assertClose(_ now: [Double], _ before: [Double], within bound: Double, _ phase: SessionState) {
        let jump = zip(now, before).map { abs($0 - $1) }.max() ?? 0
        if jump > bound { XCTFail("\(phase): jump \(jump) > \(bound)") }
    }
}
