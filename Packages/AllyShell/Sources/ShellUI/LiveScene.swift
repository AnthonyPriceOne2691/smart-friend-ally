#if canImport(SwiftUI)
import AllyCore
import Foundation
import ShellCore
import SwiftUI

/// The child screen alive: a timeline at the pose's frame rate (`FrameRate`: 30, 120, 30, 60, lower when the phone
/// heats up) steps `Motion` towards the session's phase and draws each frame. Reduce Motion keeps 0.4 of the swing.
/// Each new count of `pokes` is a tap on the sleeping Ellie: she squashes and wobbles back (`Motion.poke`). `sounding`
/// — her voice sounds now: the mouth and the talking pose go by it, not by the phase (mouth-sync).
public struct LiveScene: View {
    let phase: SessionState, sounding: Bool, pokes: Int, safeTop: Double, safeBottom: Double
    @State private var clock = MotionClock()
    @Environment(\.accessibilityReduceMotion) private var calm

    public init(phase: SessionState, sounding: Bool, pokes: Int = 0, safeTop: Double = 0, safeBottom: Double = 0) {
        (self.phase, self.sounding, self.pokes) = (phase, sounding, pokes)
        (self.safeTop, self.safeBottom) = (safeTop, safeBottom)
    }

    public var body: some View {
        let heat = Heat(ProcessInfo.processInfo.thermalState)
        let rate = FrameRate.perSecond(TalkState(phase: phase).pose, heat: heat)
        TimelineView(.animation(minimumInterval: 1 / rate)) { context in
            ShellScene(frame: clock.frame(at: context.date, phase: phase, sound: sounding, calm: calm),
                       safeTop: safeTop, safeBottom: safeBottom)
        }
        .onChange(of: pokes) { clock.poke(calm: calm) }
    }
}

/// The motion behind a live scene: steps by the time between the timeline's dates; the blink seed is the launch time.
final class MotionClock {
    private let motion = Motion(seed: UInt64(Date().timeIntervalSince1970))
    private var last: Date?

    func frame(at date: Date, phase: SessionState, sound: Bool, calm: Bool) -> Frame {
        let dt = last.map { date.timeIntervalSince($0) } ?? 0
        last = date
        return motion.step(dt, phase: phase, sound: sound, calm: calm)
    }

    func poke(calm: Bool) { motion.poke(calm: calm) }
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
