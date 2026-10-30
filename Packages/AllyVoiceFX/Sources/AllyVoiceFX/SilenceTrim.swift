import Foundation

/// The synthesis's own silence off a sentence's ends (voice-tuning). Supertonic wraps a sentence in about 0.6 s of
/// silence before the speech and 0.7 s after it, so the mouth would move over silence and the pause between sentences
/// would be the model's, not the preset's. Speech is what rises above `floorDB` of the sentence's peak in 10 ms frames;
/// `head` and `tail` seconds of margin stay, pauses inside stay, a sentence with nothing above the floor stays whole.
public struct SilenceTrim: Equatable, Sendable {
    /// −45 dB keeps a hummed «Ммм» that starts below −40 and cuts the breath before the speech; 80 ms of tail keep the
    /// last consonant's release (the voice-tuning stand, 80 sentences of three styles).
    public static let standard = SilenceTrim(floorDB: -45, head: 0.03, tail: 0.08)

    public let floorDB: Double, head: Double, tail: Double

    public init(floorDB: Double, head: Double, tail: Double) {
        (self.floorDB, self.head, self.tail) = (floorDB, head, tail)
    }

    public func apply(_ samples: [Float], rate: Int) throws -> [Float] {
        Array(samples[try span(samples, rate: rate)])
    }

    /// The sentence between its margins; the whole of it when no frame rises above the floor.
    public func span(_ samples: [Float], rate: Int) throws -> Range<Int> {
        guard rate > 0 else { throw VoiceFXError.badRate(rate) }
        let frame = max(rate / 100, 1), frames = samples.count / frame
        let peak = samples.reduce(0) { max($0, abs($1)) }
        let floor = Double(peak) * pow(10, floorDB / 20)
        let loud = (0..<frames).filter { index in
            let piece = samples[(index * frame)..<((index + 1) * frame)]
            return sqrt(piece.reduce(0) { $0 + Double($1) * Double($1) } / Double(frame)) > floor
        }
        guard let first = loud.first, let last = loud.last else { return 0..<samples.count }
        return max(first * frame - Int(head * Double(rate)), 0)
            ..< min((last + 1) * frame + Int(tail * Double(rate)), samples.count)
    }
}
