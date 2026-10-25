import Foundation

/// One turn of hers with its number (the black box's) and Elly's answer to it.
public struct MemoryTurn: Equatable, Sendable {
    public let number: Int, her: String, elly: String?

    public init(number: Int, her: String, elly: String?) { (self.number, self.her, self.elly) = (number, her, elly) }
}

/// A conversation to remember: its session and her turns.
public struct MemoryConversation: Sendable {
    public let id: String, started: Date, turns: [MemoryTurn]

    public init(id: String, started: Date, turns: [MemoryTurn]) {
        (self.id, self.started, self.turns) = (id, started, turns)
    }
}

/// A message of the request: the system text, the user text, the model's answer, the retry.
public struct ExtractMessage: Equatable, Sendable {
    public enum Role: String, Sendable { case system, user, assistant }
    public let role: Role, text: String
}

/// The sampling of the parse (`extract.json`): temperature, seed, the JSON grammar.
public struct ExtractParams: Decodable, Equatable, Sendable {
    public let temperature: Double, seed: Int, grammar: String
}

/// The model that parses a conversation: E4B on the phone (memory-app) and on the Mac (memory-quality); a double in
/// the tests.
public protocol MemoryModel {
    func answer(_ messages: [ExtractMessage], _ params: ExtractParams) async throws -> String
}

/// What a parse did: parsed, or failed with the reason; the request's hash and the sampling; the candidates anchored in
/// her words, what was dropped (field and reason, no values) and the write.
public struct Extraction: Sendable {
    public enum Status: Equatable, Sendable { case parsed, failed(String) }

    /// A value not taken: where in the answer and why.
    public struct Drop: Equatable, Sendable {
        public enum Reason: String, Sendable {
            case ungrounded, age, relation, fiction, negated, foreign, namesake, restates, notPet
        }
        public let field: String, reason: Reason
    }

    public let status: Status, requestHash: String, params: ExtractParams, attempts: Int
    public let candidates: [Candidate], dropped: [Drop], written: WriteReport?
}

extension MemoryStore {
    /// Parses a conversation with the model and writes what is anchored in her words as one session; garbage gets one
    /// retry, garbage twice — failed with the reason, nothing written.
    public func remember(_ conversation: MemoryConversation, model: MemoryModel) async throws -> Extraction {
        let texts = ExtractTexts.shared, known = try facts()
        let prompt = ExtractPrompt(known: known, turns: conversation.turns)
        var messages = [ExtractMessage(role: .system, text: prompt.system),
                        ExtractMessage(role: .user, text: prompt.user)]
        var reason = ""
        for attempt in 1...2 {
            try Task.checkCancellation()
            let text = try await model.answer(messages, texts.params)
            do {
                var reading = Reading(turns: conversation.turns, names: known.filter { $0.trait == .name }.map(\.key))
                reading.read(try ModelAnswer.parse(text))
                let written = try write(MemorySession(id: conversation.id, started: conversation.started,
                                                      candidates: reading.candidates,
                                                      heard: conversation.turns.map(\.her), unlike: reading.unlikes))
                return Extraction(status: .parsed, requestHash: prompt.hash, params: texts.params, attempts: attempt,
                                  candidates: reading.candidates, dropped: reading.dropped, written: written)
            } catch let garbage as Garbage {
                reason = garbage.reason
                messages += [ExtractMessage(role: .assistant, text: text),
                             ExtractMessage(role: .user, text: texts.retry.replacingOccurrences(of: "{error}",
                                                                                                with: reason))]
            }
        }
        return Extraction(status: .failed(reason), requestHash: prompt.hash, params: texts.params, attempts: 2,
                          candidates: [], dropped: [], written: nil)
    }
}
