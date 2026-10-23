import AllyCore
import ShellCore
import XCTest

final class FrameRateTests: XCTestCase {
    /// The parent's answer 5: asleep 30, listening 120, thinking 30, speaking 60; heat lowers it, Reduce Motion not.
    func testFramesPerSecondByPoseAndHeat() {  // V16
        let expected: [SessionState: Double] = [.asleep: 30, .listening: 120, .windingDown: 120, .thinking: 30,
                                                .greeting: 60, .speaking: 60, .goodbye: 60]
        for (phase, rate) in expected {
            let pose = TalkState(phase: phase).pose
            XCTAssertEqual(FrameRate.perSecond(pose, heat: .nominal), rate, "\(phase)")
            XCTAssertEqual(FrameRate.perSecond(pose, heat: .fair), rate, "\(phase)")
            XCTAssertEqual(FrameRate.perSecond(pose, heat: .serious), min(rate, 30), "\(phase)")
            XCTAssertEqual(FrameRate.perSecond(pose, heat: .critical), 15, "\(phase)")
        }
    }
}
