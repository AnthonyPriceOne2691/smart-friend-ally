import Discipline
import Foundation

/// One line of the turn journal: what happened and on what, never what was said — the model may echo the girl. Rule
/// ids, the contract data hash, the source, stage times, versions and hashes, memory and heat; a value with Cyrillic
/// is written as `redacted`, so no word of the dialogue gets in by construction (K9, П26).
public struct TurnLog: Encodable, Sendable {
    public let rules: [String], contractHash: String, source: String, modelTimeout: Bool
    public let stages: [String: Double], versions: [String: String], memory: [String: Int], thermal: String

    public init(outcome: TurnOutcome, stages: [String: Double] = [:], versions: [String: String] = [:],
                memory: [String: Int] = [:], thermal: String = "") {
        let record = outcome.turn.record, times = outcome.times
        (rules, contractHash, modelTimeout) = (record.rules, record.contractHash, outcome.modelTimeout)
        if case .canned(let kind) = record.source { source = "canned:" + kind } else { source = "model" }
        let measured = ["first_text": times.firstText, "first_sentence": times.firstSentence,
                        "first_sound": times.firstSound, "reply_end": times.replyEnd].compactMapValues { $0 }
        self.stages = stages.merging(measured) { given, _ in given }
        self.versions = versions.mapValues(TurnLog.wordless)
        (self.memory, self.thermal) = (memory, TurnLog.wordless(thermal))
    }

    /// The journal line: JSON with sorted snake_case keys; nil only if encoding fails.
    public func jsonLine() -> String? {
        let encoder = JSONEncoder()
        (encoder.outputFormatting, encoder.keyEncodingStrategy) = ([.sortedKeys], .convertToSnakeCase)
        return (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func wordless(_ value: String) -> String {
        value.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) } ? "redacted" : value
    }
}
