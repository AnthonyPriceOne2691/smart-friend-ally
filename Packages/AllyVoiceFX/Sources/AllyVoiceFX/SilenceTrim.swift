import CVoiceFX

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
        var start: Int32 = 0, end = Int32(samples.count)
        samples.withUnsafeBufferPointer {
            ally_speech_span($0.baseAddress, Int32($0.count), Int32(rate), floorDB, head, tail, &start, &end)
        }
        return Int(start)..<Int(end)
    }
}
