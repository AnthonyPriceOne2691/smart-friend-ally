import Foundation

/// The prompt block (П11, П13): built once a session from the active facts — lines in a fixed order, items by first
/// appearance, capped per line, cut by rank to the budget; the core (her name and age, siblings, pets) is never cut.
public struct MemoryBlock: Equatable, Sendable {
    public let text: String, tokens: Int, trimmed: [String]

    public static var budget: Int { Words.shared.budget }

    /// Whether the block goes into the conversation (`in_conversation`): off — the parent 2026-10-28 after M40
    /// («Слить с выключенной»); the console, the erase and the prefix rebuild work either way.
    public static var inConversation: Bool { Words.shared.inConversation }

    /// The system turn of a conversation (M36): the persona as it is when memory is empty or the block is off — the
    /// prefix of today byte for byte — else the persona, an empty line and the block.
    public static func system(persona: String, block: String, on: Bool = inConversation) -> String {
        block.isEmpty || !on ? persona : persona + "\n\n" + block
    }

    /// The counter on Linux: ⌈Unicode scalars / 2.7⌉, a margin to the model's tokenizer; the app passes the tokenizer.
    public static func estimate(_ text: String) -> Int {
        Int((Double(text.unicodeScalars.count) / Words.shared.charsPerToken).rounded(.up))
    }

    public static func render(_ facts: [StoredFact], budget: Int = MemoryBlock.budget,
                              count: (String) -> Int = estimate) -> MemoryBlock {
        var lines = BlockLine.lines(facts.filter(\.active), Words.shared)
        var trimmed: [String] = []
        while count(BlockLine.text(lines)) > budget, let cut = BlockLine.cut(&lines) { trimmed.append(cut) }
        let text = BlockLine.text(lines)
        return MemoryBlock(text: text, tokens: count(text), trimmed: trimmed)
    }
}

/// An item; rank `Int.max` is the core. Lower ranks go first when the block is over budget (spec, «Блок для промпта»).
struct BlockItem {
    static let core = Int.max
    let text: String, rank: Int, seen: Double
}

/// A line: a list («Она: …», «Любимое: …»), an entity («Брат Тёма, восемь лет: …») or the creations.
struct BlockLine {
    enum Style { case list, entity, creations }
    struct Entry {
        var head: String?
        var headRank: Int, seen: Double, details: [BlockItem]
    }

    let label: String, style: Style
    var entries: [Entry]

    var text: String? {
        let parts: [String] = switch style {
        case .list: entries.flatMap { [$0.head].compactMap { $0 } + $0.details.map(\.text) }
        case .entity: entries.compactMap { entry in
            entry.head.map { $0 + (entry.details.isEmpty ? "" : ": " + Self.join(entry.details, "; ")) } }
        case .creations: entries.compactMap { entry in
            entry.head.map { $0 + (entry.details.isEmpty ? "" : " — " + Self.join(entry.details, ", ")) } }
        }
        guard !parts.isEmpty else { return nil }
        return style == .entity ? parts.joined() + "." : label + ": " + parts.joined(separator: style == .list ? ", "
                                                                                                           : "; ") + "."
    }

    static func text(_ lines: [BlockLine]) -> String {
        let shown = lines.compactMap(\.text)
        return shown.isEmpty ? "" : ([Words.shared.header] + shown).joined(separator: "\n")
    }

    /// What can be cut: an item or, once its details are gone, a head. The weakest is the lowest rank, then the longest
    /// unconfirmed, then the last in the block.
    private struct Victim: Comparable {
        let rank: Int, seen: Double, line: Int, entry: Int, detail: Int?

        static func < (lhs: Victim, rhs: Victim) -> Bool {
            (lhs.rank, lhs.seen, rhs.line, rhs.entry, rhs.detail ?? -1)
                < (rhs.rank, rhs.seen, lhs.line, lhs.entry, lhs.detail ?? -1)
        }
    }

    /// Cuts the weakest item; nil — only the core is left.
    static func cut(_ lines: inout [BlockLine]) -> String? {
        var victims: [Victim] = []
        for (line, block) in lines.enumerated() {
            for (entry, item) in block.entries.enumerated() {
                victims += item.details.enumerated().map {
                    Victim(rank: $1.rank, seen: $1.seen, line: line, entry: entry, detail: $0)
                }
                if item.details.isEmpty, item.head != nil {
                    victims.append(Victim(rank: item.headRank, seen: item.seen, line: line, entry: entry, detail: nil))
                }
            }
        }
        guard let cut = victims.filter({ $0.rank < BlockItem.core }).min() else { return nil }
        if let detail = cut.detail { return lines[cut.line].entries[cut.entry].details.remove(at: detail).text }
        defer { lines[cut.line].entries[cut.entry].head = nil }
        return lines[cut.line].entries[cut.entry].head
    }

    private static func join(_ items: [BlockItem], _ separator: String) -> String {
        items.map(\.text).joined(separator: separator)
    }
}
