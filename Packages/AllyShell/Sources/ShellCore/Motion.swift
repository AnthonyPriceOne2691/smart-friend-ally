import AllyCore
import Foundation

/// Ellie alive (prototype v3, `tick`): each step moves her along the session's phase — critically damped springs on the
/// weights of her poses (ω = 11: about 0.43 s to 95%, screen rule 10), oscillation phases that accumulate their tempo,
/// blinks on a seeded schedule and, after a goodbye, the yawn and sleep of `poseBye`. Speaking has two groups — talking
/// and waving (greeting, goodbye) — and sleep two — plain and after a goodbye (dozing) — so every switch is a spring
/// between groups whose own poses run on without a break. The light and the bubbles of the screen step with her (Ш2б).
public final class Motion {
    public static let stiffness = 11.0
    /// The squash of a tap on the sleeping Ellie (prototype v3, `giggle` asleep): a soft spring that wobbles back.
    public static let squashStiffness = 11.0, squashDamping = 0.36

    /// The groups whose weights spring: the session's four poses, speaking split into talking and waving, sleep into
    /// plain and dozing off after a goodbye.
    public enum Group: Int, CaseIterable, Sendable {
        case sleeps, listens, thinks, talks, waves, dozes
    }

    /// The weight of each group in the frame, in the order of `Group`.
    public private(set) var weights = [1.0, 0, 0, 0, 0, 0]
    private var speeds = [0.0, 0, 0, 0, 0, 0], phases = Phases(), random: Random
    private var phase = SessionState.asleep, group = Group.sleeps, dozingSince = 0.0
    private var blinkAt = 2.2, doubleBlink = false, squash = 0.0, squashSpeed = 0.0
    private var glow = Glow(), bubbles: Bubbles, sleepingSince = 0.0, rise = 0.0, syllables: Syllables
    /// Her voice's level in the frame (0…1): the level passed in, or the rhythm of syllables while she speaks (Ш2в).
    public private(set) var voiceLevel = 0.0

    public init(seed: UInt64 = 1) {
        (random, bubbles, syllables) = (Random(seed: seed), Bubbles(seed: seed), Syllables(seed: seed))
    }

    public func weight(of group: Group) -> Double { weights[group.rawValue] }

    /// One step of `dt` seconds (at most 0.05 — a stalled frame does not leap) towards the pose of `phase`.
    public func step(_ dt: Double, phase next: SessionState, voice: Double? = nil, mic: Double? = nil,
                     calm: Bool = false) -> Frame {
        let dt = min(max(dt, 0), 0.05)
        enter(next)
        settle(dt)
        let speaking = TalkState(phase: phase).pose == .speaks && voice == nil
        let rhythm = syllables.step(dt, at: phases.time + dt, speaking: speaking)
        voiceLevel = voice ?? rhythm
        let pose = blended(voice: voiceLevel, mic: mic, calm: calm)
        phases.advance(dt, pose, calm: calm)
        wobble(dt)
        var frame = Frame(pose, phases: phases, blink: blink(), swing: calm ? Pose.calmSwing : 1, squash: squash)
        rise = frame.rise
        let clocks = Clocks(time: phases.time, weights: weights, sleeping: phases.time - sleepingSince,
                            dozing: phases.time - dozingSince, rise: rise, calm: calm)
        (frame.light, frame.bubbles) = (glow.step(dt, clocks), bubbles.step(dt, clocks))
        return frame
    }

    /// A tap on the sleeping Ellie: a kick to the squash spring — 1, with Reduce Motion 0.5 (prototype v3, `giggle`) —
    /// and one «Z» over her (Ш2б, the parent's answer 6).
    public func poke(calm: Bool = false) {
        squashSpeed -= calm ? 0.5 : 1
        bubbles.poke(rise: rise)
    }

    /// The squash springs back to 0 — semi-implicit Euler in substeps of ≤ 8 ms, like the poses.
    private func wobble(_ dt: Double) {
        let k = Motion.squashStiffness, damping = 2 * Motion.squashDamping * Motion.squashStiffness
        let count = max(1, Int((dt / 0.008).rounded(.up))), h = dt / Double(count)
        for _ in 0..<count {
            squashSpeed += (-k * k * squash - damping * squashSpeed) * h
            squash += squashSpeed * h
        }
    }

    /// A new phase: asleep after a goodbye dozes off with a yawn (its clock restarts only once the dozing has faded);
    /// waking up restarts the blinks (the first one 2.2 s later).
    private func enter(_ next: SessionState) {
        guard next != phase else { return }
        group = Motion.group(of: next, after: phase)
        if group == .dozes, weight(of: .dozes) < 0.01 { dozingSince = phases.time }
        if group == .sleeps, weight(of: .sleeps) < 0.01 { sleepingSince = phases.time }
        if phase == .asleep { (blinkAt, doubleBlink) = (phases.time + 2.2, false) }
        phase = next
    }

    static func group(of phase: SessionState, after previous: SessionState) -> Group {
        switch TalkState(phase: phase).pose {
        case .sleeps: return previous == .goodbye ? .dozes : .sleeps
        case .listens: return .listens
        case .thinks: return .thinks
        case .speaks: return phase == .greeting || phase == .goodbye ? .waves : .talks
        }
    }

    /// Springs towards 1 for the phase's group and 0 for the others — semi-implicit Euler in substeps of ≤ 8 ms.
    private func settle(_ dt: Double) {
        let target = group.rawValue, k = Motion.stiffness
        let count = max(1, Int((dt / 0.008).rounded(.up))), h = dt / Double(count)
        for index in weights.indices {
            let goal = index == target ? 1.0 : 0
            for _ in 0..<count {
                speeds[index] += (k * k * (goal - weights[index]) - 2 * k * speeds[index]) * h
                weights[index] += speeds[index] * h
            }
        }
    }

    private func blended(voice: Double, mic: Double?, calm: Bool) -> Pose {
        let t = phases.time
        let parts = Group.allCases.map { group in
            let target: Pose
            switch group {
            case .sleeps: target = Pose.at(.sleeps, time: t, calm: calm)
            case .dozes: target = goodbyeSleep(t - dozingSince, voice: voice, calm: calm)
            case .listens: target = Pose.at(.listens, time: t, mic: mic, calm: calm)
            case .thinks: target = Pose.at(.thinks, time: t, calm: calm)
            case .talks, .waves: target = Pose.at(.speaks, time: t, voice: voice, wave: group == .waves ? 1 : 0,
                                                  calm: calm)
            }
            return (pose: target, weight: weights[group.rawValue])
        }
        return Pose.blend(parts)
    }

    /// After the goodbye: the waving pose, then the yawn (in 0.3–0.9 s, out 1.6–2.4 s), then sleep (1.7–3.3 s).
    private func goodbyeSleep(_ s: Double, voice: Double, calm: Bool) -> Pose {
        let awake = Pose.at(.speaks, time: phases.time, voice: voice, wave: 1, calm: calm)
        let yawning = smoothstep(0.3, 0.9, s) * (1 - smoothstep(1.6, 2.4, s)), sleeping = smoothstep(1.7, 3.3, s)
        return Pose.mix(Pose.mix(awake, Pose.yawn, yawning), Pose.at(.sleeps, time: phases.time, calm: calm), sleeping)
    }

    /// Blinks (prototype v3): 0.18 s each — 40% closing, 60% opening; the next one 2.6–5.6 s after the last ends,
    /// one in five doubled 0.08 s later.
    private func blink() -> Double {
        let t = phases.time
        if t > blinkAt + 0.2 {
            if doubleBlink { (doubleBlink, blinkAt) = (false, t + 0.08) } else {
                blinkAt = t + 2.6 + 3 * random.next()
                doubleBlink = random.next() < 0.2
            }
        }
        let u = (t - blinkAt) / 0.18
        guard u >= 0, u <= 1 else { return 0 }
        return u < 0.4 ? smoothstep(0, 1, u / 0.4) : 1 - smoothstep(0, 1, (u - 0.4) / 0.6)
    }
}

/// SplitMix64: a small reproducible generator — the tests fix the seed, the phone seeds it with the launch time.
struct Random {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    /// A number in [0, 1).
    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double((mixed ^ (mixed >> 31)) >> 11) / Double(UInt64(1) << 53)
    }
}
