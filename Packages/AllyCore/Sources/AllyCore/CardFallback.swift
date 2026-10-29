import Discipline
import Foundation

/// The card behind a turn's hint (card-fallback, decision of the parent 2026-10-29): its text and the key of its
/// essence. When what the contract kept of the model's reply misses the essence, the card's text sounds in place of the
/// rest of the turn; the sentence that has already sounded stays.
public struct HintCard: Equatable, Sendable {
    public let text: String, key: String

    public init(text: String, key: String) { (self.text, self.key) = (text, key) }

    /// The key compiles and does not find the essence in the sentences; a key that does not compile judges nothing
    /// (the base's self-test refuses such a card at load).
    func misses(_ sentences: [String]) -> Bool { CardEssence(key).map { !$0.found(in: sentences) } ?? false }
}

/// A card's key as the base's test (P13) and the P18 judge read it: lower case, «ё» as «е», case-insensitive.
struct CardEssence: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    private let regex: NSRegularExpression

    init?(_ key: String) {
        guard let regex = try? NSRegularExpression(pattern: key, options: .caseInsensitive) else { return nil }
        self.regex = regex
    }

    func found(in sentences: [String]) -> Bool {
        let text = sentences.joined(separator: " ").lowercased().replacingOccurrences(of: "ё", with: "е")
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}

/// The card of a hinted turn with what the turn's contract needs: the mode, her words, the router's decision.
struct CardTurn {
    let card: HintCard, mode: TurnMode, heard: String, decision: RouterDecision

    /// A model's turn whose kept sentences miss the essence becomes, through a contract of the same turn, the sentence
    /// that already sounded and the card's text; nil — the turn stays: a canned reply, or the essence is there.
    func turn(after kept: Turn, spoken: Bool) -> Turn? {
        guard kept.source == .model, card.misses(kept.sentences) else { return nil }
        let contract = TurnContract(mode: mode, heard: heard, decision: decision)
        guard spoken else { return contract.finish(card.text) }
        guard let head = kept.sentences.first, contract.first(head) != nil else { return nil }
        return contract.finish(head + " " + card.text)
    }
}
