import Foundation

/// The kind of her next turn by what Elly just said — code, not the model (the parent's rule, 2026-10-23): a counting
/// request anywhere in Elly's turn → counting; else by the last sentence: no question → open; a question with a choice
/// or a number word → closed; with a question word → open; with none (yes or no) → closed. Unclear is open: an open
/// question taken for a closed one cuts her story, a closed one taken for open costs half a second. Words —
/// `turn_kinds.json`, lowercase, «ё» as «е».
public struct TurnKinds: Sendable {
    private struct Cues: Decodable { let counting, choice, number, open: [String] }

    private let counting: Set<String>, closing: Set<String>, open: Set<String>

    public static let shared: TurnKinds = {
        guard let url = Bundle.module.url(forResource: "turn_kinds", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: turn_kinds.json is unreadable") }
        do {
            let cues = try JSONDecoder().decode(Cues.self, from: bytes)
            return TurnKinds(counting: cues.counting, closing: cues.choice + cues.number, open: cues.open)
        } catch {
            fatalError("AllyCore: turn_kinds.json does not decode: \(error)")
        }
    }()

    private init(counting: [String], closing: [String], open: [String]) {
        (self.counting, self.closing, self.open) = (Self.words(counting), Self.words(closing), Self.words(open))
    }

    /// The kind of the turn that answers these sentences of Elly's.
    public func kind(after sentences: [String]) -> TurnKind {
        if sentences.contains(where: { !Self.words([$0]).isDisjoint(with: counting) }) { return .counting }
        guard let last = sentences.last, last.contains("?") else { return .open }
        let said = Self.words([last])
        if !said.isDisjoint(with: closing) { return .closed }
        return said.isDisjoint(with: open) ? .closed : .open
    }

    private static func words(_ texts: [String]) -> Set<String> {
        Set(texts.flatMap { $0.lowercased().replacingOccurrences(of: "ё", with: "е").split { !$0.isLetter } }
            .map(String.init))
    }
}
