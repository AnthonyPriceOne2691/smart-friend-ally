import Foundation

/// The bubbles of one frame (prototype v3): eight soap bubbles drifting up the sky, nine little bubbles rising in the
/// water, and twelve places for the puffs of thinking (the first 8) and the «Z» of sleep (the last 4).
public struct BubbleField: Equatable, Sendable {
    /// A sky bubble: its size (pt), centre in shares of the screen, turn (degrees) and wobble; its own rise (pt/s),
    /// sway (pt) and tempo (rad/s) — the same for the bubble all along.
    public struct Sky: Equatable, Sendable {
        public let size: Double, x: Double, y: Double, turn: Double, wobble: Double
        public let speed: Double, sway: Double, tempo: Double
    }

    /// A water bubble: radius and centre in the character's units, its own rise (units/s).
    public struct Water: Equatable, Sendable {
        public let radius: Double, x: Double, y: Double, speed: Double
    }

    /// A puff: thinking or «Z», its size (pt), centre (units round the bubble's centre), turn, scale and visibility.
    public struct Puff: Equatable, Sendable {
        public let z: Bool, size: Double, x: Double, y: Double, turn: Double, scale: Double, opacity: Double
    }

    public internal(set) var sky: [Sky] = [], water: [Water] = [], puffs: [Puff] = []

    public init() {}

    /// The bubbles of a still frame (Ш1's): sky and water risen for `t` from their places, no puffs.
    public static func still(time t: Double) -> BubbleField {
        var bubbles = Bubbles(seed: 1)
        let clocks = Clocks(time: t, weights: [0, 0, 0, 0, 0, 0], sleeping: 0, dozing: 0, rise: 0, calm: false)
        return bubbles.step(t, clocks)
    }
}

/// The bubbles' motion on the parent's screen (440 × 956 pt): the sky and the water rise and come back from below, the
/// puffs are born on the prototype's clocks and fade in over 0.28 s and out over their last 0.5 s.
struct Bubbles {
    private struct Drift {
        var left: Double, top: Double, turn: Double
        let size: Double, index: Double
    }

    private struct Slot {
        var age = 0.0, life = 0.0, x = 0.0, y = 0.0, turn = 0.0, rise = 0.0, drift = 0.0, spin = 0.0, scale = 1.0
        var wobble = 0.0, tempo = 0.0, phase = 0.0
        let z: Bool, size: Double
    }

    static let width = 440.0, height = 956.0, scale = 1.075
    /// The sky bubbles' size (pt) and place in percent of the screen (prototype `.bub`), the water bubbles' radius and
    /// place in units (`.wbub`).
    static let skyPlaces = [[88.0, 4, 10], [44, 80, 7], [118, 72, 30], [34, 20, 34], [62, 4, 58], [76, 82, 66],
                            [100, 30, 84], [40, 50, 4]]
    static let waterPlaces = [[5.5, -132, 96], [3.6, -108, -40], [7, -150, 20], [4.2, -60, 150], [3.2, -30, -160],
                              [5, 126, -120], [3.4, 146, 64], [6.4, 118, 132], [4, 60, -170]]
    private var sky: [Drift], water: [Double], slots: [Slot], random: Random, thinkClock = 0.2, zClock = 0.3

    init(seed: UInt64) {
        random = Random(seed: seed ^ 0xB0B_B1E5)
        sky = Bubbles.skyPlaces.enumerated().map { index, place in
            let lean = sin(Bubbles.phase(Double(index))) * Bubbles.sway(Double(index))
            return Drift(left: place[1] / 100 * Bubbles.width - lean, top: place[2] / 100 * Bubbles.height, turn: 0,
                         size: place[0], index: Double(index))
        }
        water = Bubbles.waterPlaces.map { $0[2] }
        slots = (0..<12).map { index in
            let thinking = index < 8
            let share = (Double(thinking ? index : index - 8) * 0.618).truncatingRemainder(dividingBy: 1)
            return Slot(z: !thinking, size: (thinking ? 14 + 12 * share : 34 + 8 * share) * Bubbles.scale)
        }
    }

    /// One step of the field; the puffs are born from the weights and the sleep clocks.
    mutating func step(_ dt: Double, _ clocks: Clocks) -> BubbleField {
        let swing = clocks.calm ? Pose.calmSwing : 1
        for index in sky.indices { drift(index, dt * swing) }
        water = water.enumerated().map { index, top in
            let next = top - Bubbles.waterSpeed(Double(index)) * dt * swing
            return next < -205 ? 205 : next
        }
        bear(dt, clocks)
        for index in slots.indices where slots[index].age < slots[index].life { age(index, dt) }
        return field(clocks.time, swing: swing)
    }

    /// A tap on the sleeping Ellie: one «Z» at once (the parent's answer 6).
    mutating func poke(rise: Double) { bearZ(rise: rise) }

    private mutating func drift(_ index: Int, _ dt: Double) {
        let place = sky[index].index
        sky[index].top -= Bubbles.skySpeed(place) * dt
        sky[index].turn += (Crown.hash(place + 9.5) - 0.5) * 16 * dt
        guard sky[index].top < -sky[index].size - 24 else { return }
        sky[index].top = Bubbles.height + 20 + random.next() * 80
        sky[index].left = random.next() * max(1, Bubbles.width - sky[index].size)
    }

    /// Thinking — every 0.6 s (1.1 with Reduce Motion) while thinking weighs over half; «Z» — every 1.7 s in sleep:
    /// after a goodbye from 2.6 s, plain sleep from 1 s; the first comes 0.3 s after the clock starts (`zTimer`).
    private mutating func bear(_ dt: Double, _ clocks: Clocks) {
        let weight = { (group: Motion.Group) in clocks.weights[group.rawValue] }
        if weight(.thinks) > 0.5 {
            thinkClock -= dt
            if thinkClock <= 0 {
                thinkClock = clocks.calm ? 1.1 : 0.6
                bearThought(rise: clocks.rise)
            }
        }
        let dozing = weight(.dozes) > 0.6 && clocks.dozing > 2.6
        let sleeping = weight(.sleeps) > 0.6 && clocks.sleeping > 1
        guard dozing || sleeping else {
            zClock = 0.3
            return
        }
        zClock -= dt
        if zClock <= 0 {
            zClock = 1.7
            bearZ(rise: clocks.rise)
        }
    }

    private mutating func bearThought(rise: Double) {
        guard let index = slots.indices.first(where: { !slots[$0].z && slots[$0].age >= slots[$0].life }) else {
            return
        }
        let size = slots[index].size
        slots[index] = Slot(life: draw(2.2, 2.8), x: draw(38, 72), y: draw(-128, -108) - 8 + rise, rise: -draw(26, 38),
                            drift: draw(4, 14), spin: draw(-15, 15), scale: draw(0.6, 1.05), wobble: 6,
                            tempo: draw(1.8, 2.8), phase: draw(0, 2 * .pi), z: false, size: size)
    }

    private mutating func bearZ(rise: Double) {
        guard let index = slots.indices.first(where: { slots[$0].z && slots[$0].age >= slots[$0].life }) else { return }
        let size = slots[index].size
        slots[index] = Slot(life: 3.6, x: draw(56, 70), y: -104 - 8 + rise, turn: draw(-12, 6), rise: -20, drift: 12,
                            spin: 5, wobble: 8, tempo: 1.6, phase: draw(0, 2 * .pi), z: true, size: size)
    }

    private mutating func draw(_ low: Double, _ high: Double) -> Double { low + (high - low) * random.next() }

    private mutating func age(_ index: Int, _ dt: Double) {
        slots[index].age += dt
        slots[index].x += slots[index].drift * dt
        slots[index].y += slots[index].rise * dt
        slots[index].turn += slots[index].spin * dt
    }

    private func field(_ t: Double, swing: Double) -> BubbleField {
        var field = BubbleField()
        field.sky = sky.map { drift in
            let place = drift.index, phase = Bubbles.phase(place), sway = Bubbles.sway(place)
            let left = drift.left + sin(t * Bubbles.tempo(place) + phase) * sway * swing
            return BubbleField.Sky(size: drift.size, x: (left + drift.size / 2) / Bubbles.width,
                                   y: (drift.top + drift.size / 2) / Bubbles.height, turn: drift.turn,
                                   wobble: sin(t * 0.9 + phase) * 0.025 * swing, speed: Bubbles.skySpeed(place),
                                   sway: sway, tempo: Bubbles.tempo(place))
        }
        field.water = water.enumerated().map { index, top in
            let place = Double(index), spot = Bubbles.waterPlaces[index]
            let phase = Crown.hash(place + 71) * 2 * .pi, tempo = 0.6 + 0.6 * Crown.hash(place + 61)
            return BubbleField.Water(radius: spot[0], x: spot[1] + (sin(t * tempo + phase) - sin(phase)) * 5 * swing,
                                     y: top, speed: Bubbles.waterSpeed(place))
        }
        field.puffs = slots.map(puff)
        return field
    }

    private func puff(_ slot: Slot) -> BubbleField.Puff {
        guard slot.age < slot.life else {
            return BubbleField.Puff(z: slot.z, size: slot.size, x: 0, y: 0, turn: 0, scale: 0, opacity: 0)
        }
        let share = slot.age / slot.life, lean = sin(slot.age * slot.tempo + slot.phase) * slot.wobble
        let grown = slot.z ? 0.5 + 0.7 * smoothstep(0, 1, share)
            : slot.age < 0.4 ? Bubbles.backOut(slot.age / 0.4) : 1 - 0.12 * share
        let shown = smoothstep(0, 0.28, slot.age) * (1 - smoothstep(slot.life - 0.5, slot.life, slot.age))
        return BubbleField.Puff(z: slot.z, size: slot.size, x: slot.x + lean, y: slot.y, turn: slot.turn,
                                scale: slot.scale * grown, opacity: shown)
    }

    static func skySpeed(_ place: Double) -> Double { 4 + 5 * Crown.hash(place + 1.5) }
    static func sway(_ place: Double) -> Double { 6 + 6 * Crown.hash(place + 2.5) }
    static func tempo(_ place: Double) -> Double { 0.2 + 0.2 * Crown.hash(place + 4.5) }
    static func phase(_ place: Double) -> Double { Crown.hash(place + 6.5) * 2 * .pi }
    static func waterSpeed(_ place: Double) -> Double { 8 + 10 * Crown.hash(place + 51) }

    /// The prototype's spring-in: from 0 past 1 and back to 1.
    static func backOut(_ share: Double) -> Double {
        let back = share - 1
        return 1 + 2.4 * back * back * back + 1.4 * back * back
    }
}
