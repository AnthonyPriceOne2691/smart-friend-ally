import AllyCore
import Foundation

/// The light of one frame (prototype v3, «the bubble and its moods»): night over the sky and in the water, the lilac
/// of thinking, the glow round the bubble and the 28 pearls of listening, the bubble's float, the moon's stars and the
/// sky's glints. Shares are 0…1 unless said otherwise.
public struct Light: Equatable, Sendable {
    /// The pearls ring the bubble at 0.545 of its diameter, each 3.2% of it across at size 1.
    public static let pearlCount = 28, pearlRing = 0.545, pearlSize = 0.032

    /// Night, the lilac of thinking, the glow and its scale, how visible the pearls are, the float of the bubble (pt).
    public internal(set) var night = 1.0, think = 0.0, aura = 0.28, auraScale = 1.0, pearlsShown = 0.0, bob = 0.0
    /// The pearls' sizes, the brightness of the nine stars and of the six glints of the sky.
    public internal(set) var pearls = [Double](repeating: 0.4, count: pearlCount)
    public internal(set) var stars = [Double](repeating: 0.55, count: 9), glints = [Double](repeating: 0.6, count: 6)

    public init() {}

    /// The floor's shadow shrinks as the bubble floats down and grows as it rises.
    public var floor: Double { 1 - bob * 0.012 }

    /// The pulse of listening — soft and by rhythm until the microphone gives a level (the parent's answer 3).
    public static func pulse(_ t: Double) -> Double { 0.35 + 0.25 * (0.5 + 0.5 * sin(2 * .pi * t / 2.4)) }

    /// A still light of one phase at `t` (Ш1's frames): night in sleep, the lilac in thinking, the glow in listening.
    public static func still(_ phase: SessionState, time t: Double) -> Light {
        let pose = TalkState(phase: phase).pose
        var light = Light()
        light.night = pose == .sleeps ? 1 : 0
        light.shine(t, think: pose == .thinks ? 1 : 0, listen: pose == .listens ? 1 : 0, calm: false)
        return light
    }

    /// Everything but the night, which keeps its own pace (`Glow`), from the weights of thinking and listening at `t`.
    mutating func shine(_ t: Double, think weight: Double, listen shown: Double, calm: Bool) {
        let swing = calm ? Pose.calmSwing : 1, level = Light.pulse(t)
        think = 0.9 * weight
        aura = 0.28 + shown * (0.15 + 0.55 * level)
        auraScale = 1 + level * shown * 0.06 * swing
        pearlsShown = smoothstep(0.02, 0.5, shown)
        let reach: Double = calm ? 0.5 : 1, base: Double = 0.6 + 0.4 * shown
        pearls = (0..<Light.pearlCount).map { (index: Int) -> Double in
            let place = Double(index), wave: Double = 0.5 + 0.5 * noise(t * 2.2 + place * 0.61)
            let swell: Double = level * wave + 0.1 * sin(t * 2.6 - place * 0.5) * level
            return (0.4 + 1.1 * min(max(swell, 0), 1) * reach) * base
        }
        bob = sin(t * 0.8) * 3.5 * swing
        stars = (0..<9).map { (index: Int) -> Double in
            let place = Double(index), tempo: Double = 0.6 + 0.4 * Crown.hash(place + 21)
            return 0.55 + 0.4 * sin(t * tempo + place * 1.7)
        }
        glints = (0..<6).map { (index: Int) -> Double in
            let tempo: Double = 0.5 + 0.5 * Crown.hash(Double(index) + 3)
            return 0.6 + 0.22 * sin(t * tempo * swing)
        }
    }
}

/// The night's own pace (prototype `follow`, 1.6 a second): it comes with sleep, and after a goodbye only once the
/// yawn is over; the rest of the light follows the weights at once.
struct Glow {
    private var light = Light()

    mutating func step(_ dt: Double, _ clocks: Clocks) -> Light {
        let weight = { (group: Motion.Group) in clocks.weights[group.rawValue] }
        let sleep = weight(.sleeps) + weight(.dozes) * smoothstep(1.5, 3.8, clocks.dozing)
        light.night += (sleep - light.night) * (1 - exp(-1.6 * dt))
        light.shine(clocks.time, think: weight(.thinks), listen: weight(.listens), calm: clocks.calm)
        return light
    }
}

/// What the light and the bubbles of a step need from the motion: the time, the groups' weights, how long she has slept
/// plainly and after a goodbye, where her body floats, Reduce Motion.
struct Clocks {
    let time: Double, weights: [Double], sleeping: Double, dozing: Double, rise: Double, calm: Bool
}

/// The prototype's value noise: a smooth step between fixed pseudo-random numbers at whole x.
func noise(_ x: Double) -> Double {
    let whole = floor(x), part = x - whole, ease = part * part * part * (part * (part * 6 - 15) + 10)
    return Crown.hash(whole) + (Crown.hash(whole + 1) - Crown.hash(whole)) * ease
}
