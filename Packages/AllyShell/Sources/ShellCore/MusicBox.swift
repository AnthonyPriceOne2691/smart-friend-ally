import Foundation

/// «Шкатулка Элли» (background-music, the parent's pick 2026-10-29): a music box over a marimba, a seamless loop of
/// 43.6 s made by code — sines that decay, tails and echo wrapping to the start. The arithmetic is the generator's the
/// parent heard, step for step, plain + − × ÷ only: the same bytes on Linux, the Mac and the phone (Y10). Hot loops are
/// `while` over raw pointers: the phone's debug build renders it too, and iterators there cost fourteen times as much.
public enum MusicBox {
    public static let rate = 44_100
    static let beat = 60.0 / 88.0, ln2 = 0.6931471805599453
    /// Frames of the loop: 16 bars of 4 beats.
    public static let frames = Int((Double(16 * 4) * beat * Double(rate)).rounded(.toNearestOrEven))

    /// An instrument: partials, the attack and the length of a note in seconds.
    struct Voice {
        let partials: [Partial], attack: Double, length: Double
    }

    /// A partial: its ratio to the pitch, amplitude and decay in seconds.
    struct Partial {
        let ratio: Double, amplitude: Double, decay: Double

        init(_ ratio: Double, _ amplitude: Double, _ decay: Double) {
            (self.ratio, self.amplitude, self.decay) = (ratio, amplitude, decay)
        }
    }

    static let voices = [
        Voice(partials: [Partial(1, 1, 0.55), Partial(4, 0.22, 0.12), Partial(9.9, 0.04, 0.04)], attack: 0.003,
              length: 1.6),  // marimba
        Voice(partials: [Partial(1, 1, 0.9), Partial(2, 0.25, 0.4), Partial(3, 0.06, 0.2)], attack: 0.012,
              length: 2),  // bass
        Voice(partials: [Partial(1, 1, 1.1), Partial(2, 0.12, 0.5), Partial(6.27, 0.18, 0.12),
                         Partial(17.55, 0.03, 0.04)], attack: 0.004, length: 2.6)  // music box
    ]

    /// The loop as 16-bit stereo, left and right interleaved — the samples of the WAV the parent chose.
    public static func render() -> [Int16] {
        var buses: [(pan: Double, samples: [Float])] = [], tones: [Int: [Float]] = [:]
        for note in MusicScore.notes() {
            let key = note.voice * 1000 + note.midi, sound = tones[key] ?? tone(voices[note.voice], midi: note.midi)
            tones[key] = sound
            if !buses.contains(where: { $0.pan == note.pan }) {
                buses.append((note.pan, [Float](repeating: 0, count: frames)))
            }
            let bus = buses.firstIndex { $0.pan == note.pan } ?? 0
            add(sound, to: &buses[bus].samples, at: Int((note.start * Double(rate)).rounded(.toNearestOrEven)),
                gain: note.gain)
        }
        var left = [Float](repeating: 0, count: frames), right = left
        for bus in buses {
            let (toRight, toLeft) = sincos(bus.pan * Double.pi / 2)
            add(bus.samples, to: &left, at: 0, gain: toLeft)
            add(bus.samples, to: &right, at: 0, gain: toRight)
        }
        left = echo(left, taps: [(0.083, 0.22), (0.191, 0.14), (0.307, 0.08)])
        right = echo(right, taps: [(0.097, 0.22), (0.211, 0.14), (0.331, 0.08)])
        return interleave(left, right)
    }

    /// `sound` × `gain` added into `bus` from `at`, around the loop; each sum is rounded to a float, as the
    /// generator's.
    static func add(_ sound: [Float], to bus: inout [Float], at: Int, gain: Double) {
        let (length, loop) = (sound.count, bus.count)
        sound.withUnsafeBufferPointer { source in
            bus.withUnsafeMutableBufferPointer { target in
                guard let from = source.baseAddress, let into = target.baseAddress else { return }
                var (offset, slot) = (0, at)
                while offset < length {
                    if slot == loop { slot = 0 }
                    into[slot] = Float(Double(into[slot]) + gain * Double(from[offset]))
                    (offset, slot) = (offset + 1, slot + 1)
                }
            }
        }
    }

    /// One note of an instrument: its partials turn by a step and decay; a soft attack and a soft end.
    static func tone(_ voice: Voice, midi: Int) -> [Float] {
        let pitch = 440.0 * pow2(Double(midi - 69) / 12), count = Int(voice.length * Double(rate))
        let attack = Int(voice.attack * Double(rate)), tail = Int(0.05 * Double(rate))
        var out = [Float](repeating: 0, count: count)
        out.withUnsafeMutableBufferPointer { buffer in
            guard let out = buffer.baseAddress else { return }
            for partial in voice.partials where pitch * partial.ratio <= Double(rate) / 2.2 {
                let (step, turn) = sincos(2 * Double.pi * (pitch * partial.ratio) / Double(rate))
                let fade = seriesExp(-1.0 / (partial.decay * Double(rate)))
                var (level, sine, cosine, index) = (partial.amplitude, 0.0, 1.0, 0)
                while index < count {
                    out[index] = Float(Double(out[index]) + level * sine)
                    level *= fade
                    (sine, cosine, index) = (sine * turn + cosine * step, cosine * turn - sine * step, index + 1)
                }
            }
            for index in 0..<min(attack, count) {
                out[index] = Float(Double(out[index]) * (Double(index) / Double(attack)))
            }
            for index in 0..<tail {
                out[count - 1 - index] = Float(Double(out[count - 1 - index]) * (Double(index) / Double(tail)))
            }
        }
        return out
    }

    /// A soft room: taps read around the loop, so the echo of its end sounds at its start.
    static func echo(_ channel: [Float], taps: [(delay: Double, gain: Double)]) -> [Float] {
        var out = channel
        for tap in taps {
            let split = channel.count - Int(tap.delay * Double(rate))
            add(Array(channel[split...] + channel[..<split]), to: &out, at: 0, gain: tap.gain)
        }
        return out
    }

    /// The loudest sample scaled to 0,70, then 16 bits by truncation.
    static func interleave(_ left: [Float], _ right: [Float]) -> [Int16] {
        let count = left.count
        var out = [Int16](repeating: 0, count: 2 * count)
        left.withUnsafeBufferPointer { left in
            right.withUnsafeBufferPointer { right in
                out.withUnsafeMutableBufferPointer { buffer in
                    guard let lefts = left.baseAddress, let rights = right.baseAddress, let out = buffer.baseAddress
                    else { return }
                    var (peak, index) = (0.0, 0)
                    while index < count {
                        peak = max(peak, abs(Double(lefts[index])), abs(Double(rights[index])))
                        index += 1
                    }
                    let scale = 0.70 / peak
                    index = 0
                    while index < count {
                        out[2 * index] = Int16(Double(lefts[index]) * scale * 32767)
                        out[2 * index + 1] = Int16(Double(rights[index]) * scale * 32767)
                        index += 1
                    }
                }
            }
        }
        return out
    }

    /// e^x by its series.
    static func seriesExp(_ x: Double) -> Double {
        var (term, total) = (1.0, 1.0)
        for n in 1..<30 {
            term = term * x / Double(n)
            total += term
        }
        return total
    }

    /// (sin x, cos x) by their series.
    static func sincos(_ x: Double) -> (Double, Double) {
        var (sine, cosine, term) = (0.0, 1.0, 1.0)
        for n in 1..<40 {
            term = term * x / Double(n)
            switch n % 4 {
            case 1: sine += term
            case 2: cosine -= term
            case 3: sine -= term
            default: cosine += term
            }
        }
        return (sine, cosine)
    }

    /// 2^x: the whole part by exact doubling, the rest by the series.
    static func pow2(_ x: Double) -> Double {
        var whole = Int(x.rounded(.down)), value = seriesExp((x - Double(whole)) * ln2)
        while whole > 0 { (value, whole) = (value * 2, whole - 1) }
        while whole < 0 { (value, whole) = (value * 0.5, whole + 1) }
        return value
    }
}
