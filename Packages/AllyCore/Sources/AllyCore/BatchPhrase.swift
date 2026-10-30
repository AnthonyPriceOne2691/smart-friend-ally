import Foundation

/// One utterance for a batch recognizer (GigaAM, D7.3): the 16 kHz Int16 samples the black box writes, from the
/// microphone's opening; it decodes from `preRoll` s before her speech began — not before the opening — and the text of
/// her tentative end is the text at the tail unless her speech came back (one decoding a turn).
public final class BatchPhrase: @unchecked Sendable {
    private struct State { var samples: [Int16] = [], started: Int?, tentative: String?, decodes = 0 }
    private let rate: Double, preRoll: Double, decode: @Sendable ([Int16]) -> String, state = Locked(State())
    private let onFed: @Sendable ([Int16], Int) -> Void

    /// - Parameter onFed: every fed chunk as it came — the black box keeps the very samples this recognizer decodes
    ///   from (D3.2).
    public init(rate: Double = 16_000, preRoll: Double, decode: @escaping @Sendable ([Int16]) -> String,
                onFed: @escaping @Sendable ([Int16], Int) -> Void = { _, _ in }) {
        (self.rate, self.preRoll, self.decode, self.onFed) = (rate, preRoll, decode, onFed)
    }

    public func feed(_ samples: [Int16]) {
        state { $0.samples += samples }
        onFed(samples, Int(rate))
    }

    /// The flag of her speech rose: it marks the samples heard so far — the flag comes after the speech, the pre-roll
    /// covers that.
    public func started() { state { $0.started = $0.started ?? $0.samples.count } }

    /// What the recognizer gets: from the pre-roll before her start (the opening at the earliest) to now.
    public var heard: [Int16] {
        state { (now: inout State) -> [Int16] in
            guard let started = now.started else { return now.samples }
            return Array(now.samples[max(0, started - Int((preRoll * rate).rounded()))...])
        }
    }

    public var decodes: Int { state { $0.decodes } }

    /// Her tentative end: the text so far, decoded once.
    public func tentative() -> String {
        let text = decode(heard)
        state { (now: inout State) in
            now.tentative = text
            now.decodes += 1
        }
        return text
    }

    /// Her speech came back: the tentative text is no longer hers.
    public func resumed() { state { $0.tentative = nil } }

    /// The tail: the tentative text if her speech did not come back, else the utterance decoded now.
    public func finish() -> String {
        if let kept = state({ $0.tentative }) { return kept }
        return tentative()
    }

    /// The recognizer's samples: Int16 / 32768, the black box's WAV bit for bit.
    public static func floats(_ samples: [Int16]) -> [Float] { samples.map { Float($0) / 32_768 } }
}
