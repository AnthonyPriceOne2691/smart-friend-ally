#if canImport(SwiftUI)
import AllyCore
import Foundation
import ShellCore
import SwiftUI

/// The child screen alive: a timeline at the pose's frame rate (`FrameRate`: 30, 120, 30, 60, lower when the phone
/// heats up) steps `Motion` towards the session's phase and draws each frame. Reduce Motion keeps 0.4 of the swing.
public struct LiveScene: View {
    let phase: SessionState, safeTop: Double, safeBottom: Double
    @State private var clock = MotionClock()
    @Environment(\.accessibilityReduceMotion) private var calm

    public init(phase: SessionState, safeTop: Double = 0, safeBottom: Double = 0) {
        (self.phase, self.safeTop, self.safeBottom) = (phase, safeTop, safeBottom)
    }

    public var body: some View {
        let heat = Heat(ProcessInfo.processInfo.thermalState)
        let rate = FrameRate.perSecond(TalkState(phase: phase).pose, heat: heat)
        TimelineView(.animation(minimumInterval: 1 / rate)) { context in
            ShellScene(frame: clock.frame(at: context.date, phase: phase, calm: calm), safeTop: safeTop,
                       safeBottom: safeBottom)
        }
    }
}

/// The motion behind a live scene: steps by the time between the timeline's dates; the blink seed is the launch time.
final class MotionClock {
    private let motion = Motion(seed: UInt64(Date().timeIntervalSince1970))
    private var last: Date?

    func frame(at date: Date, phase: SessionState, calm: Bool) -> Frame {
        let dt = last.map { date.timeIntervalSince($0) } ?? 0
        last = date
        return motion.step(dt, phase: phase, calm: calm)
    }
}

extension Heat {
    /// The platform's thermal state in the core's four steps.
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .serious
        }
    }
}
#endif
