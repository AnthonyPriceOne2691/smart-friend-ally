import Foundation

/// Who talks with her in a session: the parent in the adult console, the girl on her screen with the parent by — the
/// mode R's signed exception opens — or the girl alone once the goals of 18.10 are accepted (R2). The black box keeps
/// only `supervised` sessions.
public enum Audience: String, Sendable {
    case parent, supervised, child
}

/// The words of a record the black box keeps and the trace never does: her utterance, the model's text before the
/// contract, what sounded after it; and the session time when the record was written.
public struct TurnWords: Sendable {
    public let heard: String?, modelText: String?, said: [String]?, elapsed: Double

    public init(heard: String? = nil, modelText: String? = nil, said: [String]? = nil, elapsed: Double = 0) {
        (self.heard, self.modelText, self.said, self.elapsed) = (heard, modelText, said, elapsed)
    }
}

extension TraceSink {
    /// A trace sink keeps no words: here they are dropped by construction (K9).
    public func write(_ trace: TurnTrace, words: TurnWords) { write(trace) }
}

/// One record into several sinks: the trace file and the black box get the same turn.
public struct TraceFanOut: TraceSink {
    private let sinks: [TraceSink]

    public init(_ sinks: [TraceSink]) { self.sinks = sinks }

    public func write(_ trace: TurnTrace) { sinks.forEach { $0.write(trace) } }

    public func write(_ trace: TurnTrace, words: TurnWords) { sinks.forEach { $0.write(trace, words: words) } }
}

/// The black box's files on the phone: one root out of the backup, each file written whole (`.atomic` and
/// `.completeFileProtection` there). `isPrivate` — the root is out of the backup and protected, as read back.
public protocol BlackBoxDisk: Sendable {
    var isPrivate: Bool { get }
    /// Relative path → bytes, every file under the root.
    func files() throws -> [String: Int]
    func write(_ data: Data, to path: String) throws
    /// A file or a folder with all it holds.
    func remove(_ path: String) throws
}

/// Her utterance as the recognizer got it: PCM16 samples at its rate and the listening times on the session's clock —
/// the microphone opened, her speech began and ended (none if no speech), the microphone closed, the text was known.
public struct Utterance: Sendable {
    public let samples: [Int16], rate: Int
    public let opened: Double, voiced: Double?, ended: Double?, closed: Double, known: Double

    public init(samples: [Int16], rate: Int, opened: Double, voiced: Double?, ended: Double?, closed: Double,
                known: Double) {
        (self.samples, self.rate, self.opened, self.voiced, self.ended) = (samples, rate, opened, voiced, ended)
        (self.closed, self.known) = (closed, known)
    }
}

/// What the voice sounded since the last take, as the app encoded it off the engine's output (D3.3).
public struct RecordedVoice: Sendable {
    public let data: Data, seconds: Double, format: String

    public init(data: Data, seconds: Double, format: String) {
        (self.data, self.seconds, self.format) = (data, seconds, format)
    }
}

/// The voice's tape: the sound since the previous take, nil when nothing sounded or nothing records it.
public protocol VoiceTape: Sendable {
    func take() -> RecordedVoice?
}
