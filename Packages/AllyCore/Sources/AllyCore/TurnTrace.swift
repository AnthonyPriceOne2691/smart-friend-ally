import Discipline
import Foundation

/// What the app stamps on every record: versions and hashes, memory, heat (П26) and the stage times of the listening
/// the record answers (`tail`, `recognize`, `speech_end_to_sound`, `tap_buffer`) — with the turn's own they make the
/// journal line of D1.2.
public struct TraceStamp: Sendable {
    public let versions: [String: String], memory: [String: Int], thermal: String, stages: [String: Double]

    public init(versions: [String: String] = [:], memory: [String: Int] = [:], thermal: String = "",
                stages: [String: Double] = [:]) {
        (self.versions, self.memory, self.thermal, self.stages) = (versions, memory, thermal, stages)
    }
}

/// Where the records go: a line per record on the phone (`TraceFile`, D2.2), the black box keeps them with the words
/// (D3).
public protocol TraceSink: Sendable {
    func write(_ trace: TurnTrace)
    /// The record with the turn's words; a sink that keeps no words drops them (`BlackBoxPorts.swift`).
    func write(_ trace: TurnTrace, words: TurnWords)
}

/// The session's part of a record, known before the turn's work: whose session, which turn, in what state and mode,
/// by whose word (`nil` — the source of the turn's outcome), the router's decision and the kind the ear listened with
/// for the utterance or silence it answers (`nil` — no listening, as for the greeting).
struct TraceHead: Sendable {
    let session: String, turn: Int, phase: SessionState, mode: TurnMode, source: String?, route: Route?
    let elapsed: Double, limit: Double, audience: Audience, turnKind: TurnKind?
}

/// One record per turn: the session and the turn, the router's decision, what the contract fired, the stage times
/// and how the session ended — never a word of the dialogue: a value from outside with Cyrillic is `redacted` (K9).
public struct TurnTrace: Encodable, Sendable {
    public struct Decision: Encodable, Sendable {
        public let kind: String, topic: String?, key: String?, rules: [String], dataHash: String, forget: Bool
    }

    public let session: String, turn: Int, phase: String, mode: String, source: String, route: Decision?
    public let rules: [String], contractHash: String?, modelTimeout: Bool, cancelled: Bool, error: String?
    public let elapsed: Double, limit: Double, stages: [String: Double], end: String?
    public let versions: [String: String], memory: [String: Int], thermal: String, audience: String
    public let turnKind: String?

    init(_ head: TraceHead, outcome: TurnOutcome?, stamp: TraceStamp, cancelled: Bool = false, error: String? = nil,
         end: String? = nil) {
        let log = outcome.map { TurnLog(outcome: $0, stages: stamp.stages) }
        (session, turn, phase, mode) = (head.session, head.turn, head.phase.rawValue, head.mode.rawValue)
        source = head.source ?? log?.source ?? "model"
        route = head.route.map {
            Decision(kind: $0.kind, topic: $0.topic, key: $0.key, rules: $0.rules, dataHash: $0.dataHash,
                     forget: $0.forget)
        }
        (rules, contractHash, modelTimeout) = (log?.rules ?? [], log?.contractHash, log?.modelTimeout ?? false)
        (self.cancelled, self.error, self.end) = (cancelled, error.map(TurnLog.wordless), end)
        (elapsed, limit, stages) = (head.elapsed, head.limit, log?.stages ?? stamp.stages)
        (versions, memory) = (stamp.versions.mapValues(TurnLog.wordless), stamp.memory)
        (thermal, audience) = (TurnLog.wordless(stamp.thermal), head.audience.rawValue)
        turnKind = head.turnKind?.rawValue
    }

    /// The record line: JSON with sorted snake_case keys; nil only if encoding fails.
    public func jsonLine() -> String? { journalLine(self) }
}
