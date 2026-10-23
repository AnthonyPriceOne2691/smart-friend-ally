import Foundation

/// A card as the runtime reads it: id, the child's phrasings, the verified answer. The authoring fields (topic, key,
/// avoid, sources, license) are judged by the base's tests (Э2), not here.
public struct EncyclopediaCard: Decodable, Equatable, Sendable {
    public let id: String, questions: [String], answer: String
}

/// Why the encyclopedia answered so — the card, the rule ids `knowledge.*`, the data hash; never a word of hers.
public struct KnowledgeRecord: Codable, Equatable, Sendable {
    public let card: String?, rules: [String], dataHash: String
}

/// A lookup: the hint — the card's answer word for word — or nothing; the record; the best three for the stand.
public struct Lookup: Equatable, Sendable {
    public struct Ranked: Equatable, Sendable { public let card: String, score: Double }
    public let hint: String?, record: KnowledgeRecord, top: [Ranked]
}

/// The children's encyclopedia before the model: a hint only when the search is sure. In order: no question word,
/// «ты/мой…», a delicate word, no shared stem, the best card's phrasings missing her content words (one may miss
/// from three and more; a synonym counts) — no hint. Fail-closed: a bad card or config, or a first phrasing that does
/// not find its own card — no hint at all (`knowledge.selftest_failed`); an FTS5 table that does not build — the same
/// with `knowledge.index_failed`.
public final class Encyclopedia: @unchecked Sendable {
    public let healthy: Bool
    private let engine: Engine?, hash: String, failure: String

    /// The cards (JSONL, a card a line) with the bundled `encyclopedia.json`.
    public convenience init(cards: Data) { self.init(cards: cards, config: EncyclopediaConfig.bundled) }

    public init(cards bytes: Data, config configBytes: Data) {
        hash = FNV1a.tag(configBytes + bytes)
        var engine: Engine?, failure = "selftest_failed"
        if let config = try? EncyclopediaConfig.decode(configBytes), let cards = try? Self.cards(bytes, config) {
            let text = EncyclopediaText(config)
            if let index = try? EncyclopediaIndex(cards.map { Self.document($0, text) }, config: config) {
                let built = Engine(cards, text, index)
                engine = cards.indices.allSatisfy { built.decide(cards[$0].questions[0]).card == $0 } ? built : nil
            } else {
                failure = "index_failed"
            }
        }
        (self.engine, self.failure, healthy) = (engine, failure, engine != nil)
    }

    public func lookup(_ utterance: String) -> Lookup {
        guard let engine else { return Lookup(hint: nil, record: record(nil, failure), top: []) }
        let decision = engine.decide(utterance), card = decision.card.map { engine.cards[$0] }
        return Lookup(hint: card?.answer, record: record(card?.id, decision.rule), top: decision.top)
    }

    private func record(_ card: String?, _ rule: String) -> KnowledgeRecord {
        KnowledgeRecord(card: card, rules: ["knowledge." + rule], dataHash: hash)
    }

    private static func document(_ card: EncyclopediaCard, _ text: EncyclopediaText) -> EncyclopediaIndex.Document {
        EncyclopediaIndex.Document(title: text.stems(card.questions[0]),
                                   alias: text.stems(card.questions.dropFirst().joined(separator: " ")),
                                   body: text.stems(card.answer))
    }

    /// JSONL into cards; any line that does not decode or a card that breaks the runtime rules refuses the whole base.
    private static func cards(_ bytes: Data, _ config: EncyclopediaConfig) throws -> [EncyclopediaCard] {
        let decoder = JSONDecoder()
        guard let lines = String(bytes: bytes, encoding: .utf8) else { throw EncyclopediaError.config }
        let cards = try lines.split(separator: "\n")
            .filter { !$0.allSatisfy(\.isWhitespace) }
            .map { try decoder.decode(EncyclopediaCard.self, from: Data($0.utf8)) }
        guard Set(cards.map(\.id)).count == cards.count, cards.allSatisfy({ valid($0, config) }) else {
            throw EncyclopediaError.config
        }
        return cards
    }

    /// Id in kebab-case Latin; distinct phrasings in the config's range; the answer — Cyrillic and plain punctuation,
    /// within the length and the number of sentences.
    private static func valid(_ card: EncyclopediaCard, _ config: EncyclopediaConfig) -> Bool {
        let phrasings = Set(card.questions.map { EncyclopediaText.words($0).joined(separator: " ") })
        let chars = Array(card.answer)
        let sentences = 1 + zip(chars, chars.dropFirst()).filter { ".!…".contains($0.0) && $0.1.isWhitespace }.count
        return card.id.range(of: "^[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression) != nil
            && (config.questionsPerCard[0]...config.questionsPerCard[1]).contains(card.questions.count)
            && phrasings.count == card.questions.count && !phrasings.contains("")
            && !chars.isEmpty && chars.count <= config.answerMaxChars && sentences <= config.answerMaxSentences
            && card.answer.unicodeScalars.allSatisfy(answerScalar)
    }

    private static func answerScalar(_ scalar: Unicode.Scalar) -> Bool {
        (0x410...0x44F).contains(scalar.value) || scalar.value == 0x401 || scalar.value == 0x451
            || " .,!:;—-«»…".unicodeScalars.contains(scalar)
    }
}

/// The search and the decision over a built base; the index answers one caller at a time.
private struct Engine {
    let cards: [EncyclopediaCard], text: EncyclopediaText, phrasings: [Set<String>], index: Locked<EncyclopediaIndex>

    init(_ cards: [EncyclopediaCard], _ text: EncyclopediaText, _ index: EncyclopediaIndex) {
        (self.cards, self.text, self.index) = (cards, text, Locked(index))
        phrasings = cards.map { card in Set(card.questions.flatMap(text.stems)) }
    }

    /// The card's index when there is a hint, the rule that decided, the best three.
    struct Decision { let card: Int?, rule: String, top: [Lookup.Ranked] }

    func decide(_ utterance: String) -> Decision {
        let words = EncyclopediaText.words(utterance), query = text.query(words)
        guard let ranked = index({ try? $0.ranked(query.terms) }) else {
            return Decision(card: nil, rule: "index_failed", top: [])
        }
        let top = ranked.prefix(3).map { Lookup.Ranked(card: cards[$0.index].id, score: $0.score) }
        let rule = !text.asked(words) ? "not_asked" : text.personal(words) ? "personal"
            : text.delicate(words) ? "delicate" : ranked.isEmpty ? "no_match"
            : covered(query.content, ranked[0].index) ? "hint" : "coverage"
        return Decision(card: rule == "hint" ? ranked[0].index : nil, rule: rule, top: top)
    }

    /// Her content words in the card's phrasings — by stem or by a synonym's stem; one may miss from three and more.
    private func covered(_ content: [String], _ card: Int) -> Bool {
        let known = phrasings[card]
        let found: (String) -> Bool = { known.contains(RussianStemmer.stem($0)) }
        let hits = content.filter { word in
            found(word) || text.synonyms(of: word).flatMap(EncyclopediaText.words).contains(where: found)
        }.count
        let allowed = content.count >= text.config.oneMissingFrom ? 1 : 0
        return hits >= 1 && hits >= content.count - allowed
    }
}
