import Foundation

/// Her mouth by syllables while she speaks and the voice gives no level (the parent's answer 3 to the series):
/// syllables of 0.16–0.22 s with peaks 0.62–1.0 under a sin^0.75 envelope, a word's pause of 0.06 s after 1–4
/// syllables, a phrase's of 0.36 s after 8–14; the level follows the envelope at 26 a second up and 16 down
/// (prototype `speechRaw`, without its noise flutter: with it a frame's step reaches 0.094 at the bound 0.09).
/// Chance comes from its own seeded generator, like the blinks. Out of speech the mouth closes (mouth-sync).
public struct Syllables: Sendable {
    /// How fast the level falls once the sound has ended or was cut, per second: from 1 to 0 in 0.1 s — at once for the
    /// eye, and a frame's step stays under the bound 0.09 of speech.
    public static let closing = 10.0

    /// One syllable: when it starts and ends (s) and how far it opens the mouth.
    public struct Syllable: Equatable, Sendable {
        public let start: Double, end: Double, peak: Double
    }

    /// The level now (0…1) and the syllable now or next.
    public private(set) var level = 0.0, current: Syllable?
    private var random: Random, word = 0, phrase = 0, speaking = false

    public init(seed: UInt64) { random = Random(seed: seed ^ 0x5111_AB1E) }

    /// One step to the moment `t`: a new speech starts its first syllable 0.08 s later; out of speech the level closes.
    public mutating func step(_ dt: Double, at t: Double, speaking now: Bool) -> Double {
        if now, !speaking { begin(at: t) }
        speaking = now
        guard now else {
            level = max(level - Syllables.closing * dt, 0)
            return level
        }
        var raw = 0.0
        if var syllable = current {
            while t > syllable.end { syllable = next(after: syllable) }
            current = syllable
            if t >= syllable.start {
                raw = syllable.peak * pow(sin(.pi * (t - syllable.start) / (syllable.end - syllable.start)), 0.75)
            }
        }
        level += (raw - level) * (1 - exp(-(raw > level ? 26 : 16) * dt))
        return level
    }

    private mutating func begin(at t: Double) {
        (word, phrase) = (draw(1, 4), draw(8, 14))
        current = syllable(from: t + 0.08)
    }

    /// The syllable after `last`: straight on inside a word, 0.06 s later after a word, 0.36 s after a phrase.
    private mutating func next(after last: Syllable) -> Syllable {
        (word, phrase) = (word - 1, phrase - 1)
        var start = last.end
        if phrase == 0 {
            start += 0.36
            (phrase, word) = (draw(8, 14), draw(1, 4))
        } else if word == 0 {
            start += 0.06
            word = draw(1, 4)
        }
        return syllable(from: start)
    }

    private mutating func syllable(from start: Double) -> Syllable {
        let length = 0.16 + 0.06 * random.next()
        return Syllable(start: start, end: start + length, peak: 0.62 + 0.38 * random.next())
    }

    private mutating func draw(_ low: Int, _ high: Int) -> Int { low + Int(random.next() * Double(high - low + 1)) }
}
