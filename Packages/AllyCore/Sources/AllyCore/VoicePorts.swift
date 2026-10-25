import Foundation

/// A sentence made sound (voice series V4b2): the samples after processing, their rate, and how long each stage took —
/// `voice_text`, `voice_synth`, `voice_fx`.
public struct RenderedSentence: Sendable {
    public let samples: [Float], rate: Int, stages: [String: Double]

    public init(samples: [Float], rate: Int, stages: [String: Double]) {
        (self.samples, self.rate, self.stages) = (samples, rate, stages)
    }
}

/// Makes a sentence's sound: the text for the engine, the synthesis, the processing. Synchronous and heavy — the voice
/// calls it off the cooperative pool; `first` asks for the first sentence's steps.
public protocol SentenceRenderer: Sendable {
    func render(_ sentence: String, first: Bool) throws -> RenderedSentence
}

/// What a playing did: host seconds of its first sound (nil when nothing sounded), the frames played, a stop cut it.
public struct Played: Sendable, Equatable {
    public let started: Double?, frames: Int, cut: Bool

    public init(started: Double?, frames: Int, cut: Bool) {
        (self.started, self.frames, self.cut) = (started, frames, cut)
    }
}

/// Sounds samples: `play` returns when they have sounded or a `stop` cut them; `stop` silences at once.
public protocol SoundPlayer: AnyObject, Sendable {
    func play(_ samples: [Float], rate: Int) async -> Played
    func stop()
}

/// The played sound, in order (the port for D3.3): what sounded after processing, and a cut sign when a stop
/// interrupts a sentence.
public protocol PlayedSound: Sendable {
    func played(_ samples: [Float], rate: Int)
    func cut()
}

/// The turn's next sentences, so a voice makes their sound ahead (Z25). Optional: a voice without it just speaks.
public protocol VoiceLookahead: AnyObject {
    func upcoming(_ sentences: [String])
}
