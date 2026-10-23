import AllyCore
import Foundation

/// Every number the drawing reads for one phase of the session at one moment: the pose functions of prototype v3
/// (`poseListen`, `poseThink`, `poseSpeak`, sleep at the end of `poseBye`), approved by the parent 2026-10-17. Units —
/// the character's grid, 400 across the bubble; angles in degrees; amplitudes and rates feed `Frame`.
public struct Pose: Equatable, Sendable {
    public var headTilt = 0.0, headX = 0.0, headY = 0.0
    public var eyeX = 0.0, eyeY = 0.0, eyeWide = 1.0, eyesShut = 0.0
    public var mouthOpen = 0.0, mouthWidth = 1.0, mouthX = 0.0, smile = 1.0, browY = 0.0, browTilt = 0.0
    public var armLeft = 20.0, armRight = -20.0
    public var gillLift = 0.0, gillSpread = 0.0, gillWave = 5.0, gillRate = 0.9, gillFlutter = 0.0, gillCount = 0.0
    public var gillPulse = 0.0, gillScale = 1.0
    public var tailWave = 3.0, tailRate = 1.1, float = 6.0, floatRate = 1.4, bodyY = 0.0, lean = 0.0, near = 0.0
    public var breath = 0.016, breathRate = 1.9, blush = 0.75

    /// The levels the session does not give yet (D2.2): her voice while Ellie listens, Ellie's own when she speaks.
    public static let defaultMic = 0.5, defaultVoice = 0.6

    /// The pose of a phase: the body follows the session's own grouping (`TalkState.pose`, D2.2), the phase adds the
    /// wave of the greeting and the goodbye. `windingDown` looks exactly like `listening`: the screen shows no time.
    public static func at(_ phase: SessionState, time t: Double, voice: Double? = nil, mic: Double? = nil) -> Pose {
        switch TalkState(phase: phase).pose {
        case .sleeps: return asleep(t)
        case .listens: return listening(t, level: mic ?? defaultMic)
        case .thinks: return thinking(t)
        case .speaks: return speaking(t, level: voice ?? defaultVoice, waving: phase == .greeting || phase == .goodbye)
        }
    }

    /// Eyes shut in arcs, gills lowered, head bowed, a slow breath of 2π/1.3 ≈ 4.8 s.
    static func asleep(_ t: Double) -> Pose {
        Pose(headTilt: 9 + sin(t * 0.6), headX: 3, headY: 6, eyeY: 2, eyesShut: 1, mouthWidth: 0.75, mouthX: 1,
             smile: 0.8, browY: 1, armLeft: 10, armRight: -10, gillLift: -16, gillSpread: -4, gillWave: 1.5,
             gillRate: 0.5, gillScale: 0.96, tailWave: 1, tailRate: 0.6, float: 2.5, floatRate: 0.7, bodyY: 10,
             breath: 0.028, breathRate: 1.3, blush: 0.6)
    }

    /// Gills up, spread and fluttering with her voice; head tilted to the child, hands folded, mouth closed.
    static func listening(_ t: Double, level a: Double) -> Pose {
        Pose(headTilt: 8 + 1.2 * sin(t * 0.9), headX: 2, headY: 2 + 1.6 * sin(t * 2.6) + a * 0.8, eyeY: 1,
             eyeWide: 1.06, mouthWidth: 0.9, browY: -3, armLeft: -32, armRight: 32, gillLift: 8, gillSpread: 10,
             gillWave: 2.5, gillRate: 1.4, gillFlutter: 5 * a, gillScale: 1.06, tailWave: 2, float: 3, floatRate: 1,
             bodyY: 2, near: 0.03, breath: 0.012, breathRate: 2, blush: 0.85)
    }

    /// Eyes up and aside, a hand at her chin, the gills wiggling one by one as if counting.
    static func thinking(_ t: Double) -> Pose {
        Pose(headTilt: 5 + 1.2 * sin(t * 0.8), headX: 1, headY: -2, eyeX: 4 + 1.2 * sin(t * 0.5), eyeY: -7.5,
             eyeWide: 0.96, mouthWidth: 0.6, mouthX: 2, smile: 0.6, browY: -2, browTilt: -3, armLeft: 18,
             armRight: 126 + 3 * sin(t * 1.3), gillLift: 2, gillWave: 1.5, gillRate: 0.8, gillCount: 1, tailWave: 2,
             float: 4.5, floatRate: 0.9, lean: 1, breath: 0.014, breathRate: 1.8, blush: 0.65)
    }

    /// Mouth, hands and gills follow her voice; while greeting and saying goodbye the right hand waves at 1.3 Hz.
    static func speaking(_ t: Double, level a: Double, waving: Bool) -> Pose {
        let talking = -24 - 30 * a * (0.65 + 0.35 * sin(t * 3.1 + 2)), wave = -128 + 20 * sin(t * 2 * .pi * 1.3)
        return Pose(headTilt: 2.5 * sin(t * 1.5) + a * 2, headY: -a * 2.2, eyeWide: 1 + a * 0.04,
                    mouthOpen: 0.05 + 0.95 * a, mouthWidth: 1 - 0.14 * a * (0.5 + 0.5 * sin(t * 11)),
                    browY: -1.5 * a, armLeft: 24 + 30 * a * (0.65 + 0.35 * sin(t * 3.1)),
                    armRight: waving ? wave : talking, gillLift: 2 + 3 * a, gillSpread: 2, gillWave: 3, gillRate: 1.6,
                    gillPulse: 0.09 * a, tailWave: 4, tailRate: 2, float: 4.5, floatRate: 1.5, breath: 0.012,
                    breathRate: 2.2, blush: 0.85)
    }
}
