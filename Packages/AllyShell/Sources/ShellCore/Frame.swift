import AllyCore
import Foundation

/// One of her six feathery gills — the mood crown: where it grows on the head, its resting angle and length
/// (prototype v3, `GILLS`). The right side mirrors the left.
public struct Gill: Sendable {
    public let side: Double, row: Int, x: Double, y: Double, base: Double, length: Double

    /// How far each row opens with `Pose.gillSpread`: the top row the most, the bottom row closes.
    public static let spread = [1.0, 0.3, -0.6]

    public static let all: [Gill] = [-1.0, 1.0].flatMap { side in
        [(-76.0, -80.0, 208.0, 1.6), (-90, -60, 186, 1.5), (-94, -38, 163, 1.3)].enumerated().map { row, gill in
            Gill(side: side, row: row, x: gill.0 * -side, y: gill.1, base: gill.2, length: gill.3)
        }
    }
}

/// One frame of the friend: the pose of a phase at time t turned into the motion of her parts (prototype v3, `tick`).
/// The drawing only turns, moves, scales and fades parts by these numbers.
public struct Frame: Equatable, Sendable {
    public let pose: Pose
    /// The float of the body (units, + is down) and the breath (the torso stretches by it, the head rides it ×90).
    public let rise: Double, breath: Double
    /// The tail's turn and every gill's turn from its resting angle, degrees; gill length factors.
    public let tail: Double, gills: [Double], gillScales: [Double]
    /// How open the eyes are, how visible the eyeballs and the closed lids.
    public let eyeOpen: Double, eyeballs: Double, lids: Double
    public let shadowScale: Double, shadowOpacity: Double

    public static func at(_ phase: SessionState, time t: Double, voice: Double? = nil, mic: Double? = nil) -> Frame {
        Frame(Pose.at(phase, time: t, voice: voice, mic: mic), time: t)
    }

    public init(_ pose: Pose, time t: Double) {
        self.pose = pose
        rise = -sin(t * pose.floatRate) * pose.float + pose.bodyY
        breath = sin(t * pose.breathRate) * pose.breath
        tail = pose.tailWave * sin(t * pose.tailRate)
        let count = t * 1.4, counted = Int(count) % Gill.all.count, part = count - floor(count)
        gills = Gill.all.enumerated().map { index, gill in
            let shift = gill.side > 0 ? 0.7 : 0, row = Double(gill.row)
            let wave = pose.gillWave * sin(t * pose.gillRate - row * 0.9 - shift)
            let flutter = pose.gillFlutter * sin(t * 17 + row * 1.7 + shift * 2)
            let counting = index == counted ? pose.gillCount * 12 * sin(.pi * part) : 0
            return pose.gillLift + Gill.spread[gill.row] * pose.gillSpread + wave + flutter + counting
        }
        gillScales = Gill.all.map { pose.gillScale + pose.gillPulse * (1 - 0.25 * Double($0.row)) }
        let shut = pose.eyesShut
        eyeOpen = max(0.04, 1 - 0.94 * smoothstep(0.1, 0.9, shut))
        eyeballs = 1 - smoothstep(0.45, 0.85, shut)
        lids = smoothstep(0.35, 0.8, shut)
        shadowScale = 1 + rise * 0.005
        shadowOpacity = min(max(1 + rise * 0.012, 0.35), 1)
    }

    /// Turns, degrees: head, hands, tail, the six gills, the lean.
    public var angles: [Double] { [pose.headTilt, pose.armLeft, pose.armRight, tail, pose.lean] + gills }
    /// Moves, units: float, head, eyes, brows and how far the breath lifts the head.
    public var offsets: [Double] {
        [rise, pose.headX, pose.headY, pose.eyeX, pose.eyeY, pose.browY, breath * 90]
    }
    /// Shares from 0 to about 1: breath, eyes, mouth, smile, gill lengths, shadow, blush, nearness.
    public var shares: [Double] {
        [breath, eyeOpen, eyeballs, lids, pose.mouthOpen, pose.mouthWidth, pose.smile, shadowScale, shadowOpacity,
         pose.blush, pose.near, pose.eyeWide] + gillScales
    }
}

/// Hermite step from 0 at `edge0` to 1 at `edge1` (prototype v3, `smooth`).
func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}
