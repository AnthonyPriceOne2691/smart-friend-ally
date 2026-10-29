import Foundation

/// The block's words, `memory.json` (one copy): the header, labels, the order of siblings, family and favorite slots,
/// ages in words, line caps, the budget and the Linux estimate of characters per token.
struct Words: Decodable {
    struct Labels: Decodable { let she, favorite, likes, can, creations, birthday, pet: String }
    struct Console: Decodable {
        let nothing, facts, erased, waiting, failed, confirm, off, forget, forgetAll: String, forms: [String]
    }
    let header: String, labels: Labels, siblings: [[String]], family: [[String]], slots: [[String]], ages: [String]
    let caps: [String: Int], budget: Int, charsPerToken: Double, inConversation: Bool, console: Console

    static let shared: Words = {
        guard let url = Bundle.module.url(forResource: "memory", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyMemory: memory.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(Words.self, from: bytes)
        } catch {
            fatalError("AllyMemory: memory.json does not decode: \(error)")
        }
    }()

    func age(_ value: String) -> String {
        Int(value).flatMap { ages.indices.contains($0 - 1) ? ages[$0 - 1] : nil } ?? value
    }
}

extension Array where Element == [String] {
    func label(_ code: String?) -> String? { first { $0.first == code }?.last }
    func position(_ code: String?) -> Int { firstIndex { $0.first == code } ?? count }
}

extension BlockLine {
    /// The lines in the spec's order: she, favorites, likes, can, siblings, pets, the rest of the family, creations.
    static func lines(_ facts: [StoredFact], _ words: Words) -> [BlockLine] {
        let groups = Dictionary(grouping: facts, by: \.entity).values.sorted { appearance($0) < appearance($1) }
        let of = { (kind: Kind) in groups.filter { $0.first?.kind == kind } }
        let people = of(.person).sorted { lhs, rhs in
            let (left, right) = (relation(lhs, words), relation(rhs, words))
            return left == right ? appearance(lhs) < appearance(rhs) : left < right
        }
        let siblings = people.filter { relation($0, words).0 == 0 }
        let family = people.filter { relation($0, words).0 == 1 }
        return she(of(.child).first ?? [], words) + siblings.map { person($0, words, sibling: true) }
            + of(.pet).map { pet($0, words) } + family.map { person($0, words, sibling: false) }
            + [BlockLine(label: words.labels.creations, style: .creations, entries: of(.creation).map { facts in
                Entry(head: [value(facts, .species), value(facts, .name)].compactMap { $0 }.joined(separator: " "),
                      headRank: 2, seen: seen(facts), details: items(facts, .detail, words.caps["creation"]) { _ in 1 })
            })]
    }

    private static func she(_ facts: [StoredFact], _ words: Words) -> [BlockLine] {
        let head = [value(facts, .name), value(facts, .age).map(words.age)].compactMap { $0 }.joined(separator: ", ")
        let birthday = facts.filter { $0.trait == .birthday }
            .map { BlockItem(text: words.labels.birthday + " " + $0.value, rank: 12, seen: $0.lastSeen) }
        let favorites = facts.filter { $0.trait == .favorite }
            .sorted { words.slots.position($0.slot?.rawValue) < words.slots.position($1.slot?.rawValue) }
            .map { fact in BlockItem(text: [words.slots.label(fact.slot?.rawValue) ?? "", fact.value]
                .filter { !$0.isEmpty }.joined(separator: " "), rank: 9, seen: fact.lastSeen) }
        return [
            list(words.labels.she, head: head.isEmpty ? nil : head, birthday),
            list(words.labels.favorite, head: nil, favorites),
            list(words.labels.likes, head: nil, items(facts, .likes, words.caps["likes"]) { _ in 6 }),
            list(words.labels.can, head: nil, items(facts, .can, words.caps["can"]) { _ in 5 })
        ]
    }

    private static func person(_ facts: [StoredFact], _ words: Words, sibling: Bool) -> BlockLine {
        let label = (sibling ? words.siblings : words.family).label(facts.first?.relation?.rawValue) ?? ""
        let head = [label.prefix(1).uppercased() + label.dropFirst() + (value(facts, .name).map { " " + $0 } ?? ""),
                    value(facts, .age).map(words.age)].compactMap { $0 }.joined(separator: ", ")
        let cap = words.caps[sibling ? "sibling" : "family"]
        let details = items(facts, .detail, cap) { sibling ? ($0 == 0 ? 11 : 8) : 3 }
        return BlockLine(label: "", style: .entity, entries: [
            Entry(head: head, headRank: sibling ? BlockItem.core : 4, seen: seen(facts), details: details)
        ])
    }

    private static func pet(_ facts: [StoredFact], _ words: Words) -> BlockLine {
        let species = value(facts, .species) ?? words.labels.pet
        let head = [species.prefix(1).uppercased() + species.dropFirst() + (value(facts, .name).map { " " + $0 } ?? ""),
                    value(facts, .color)].compactMap { $0 }.joined(separator: ", ")
        let details = items(facts, .detail, words.caps["pet"]) { $0 == 0 ? 10 : 7 }
        return BlockLine(label: "", style: .entity, entries: [
            Entry(head: head, headRank: BlockItem.core, seen: seen(facts), details: details)
        ])
    }

    /// Facts of a trait capped to the last confirmed, shown by first appearance; `rank` by position in the line.
    private static func items(_ facts: [StoredFact], _ trait: Trait, _ cap: Int?, rank: (Int) -> Int) -> [BlockItem] {
        facts.filter { $0.trait == trait }
            .sorted { ($0.lastSeen, $0.firstSeen, $0.turn, $1.key) > ($1.lastSeen, $1.firstSeen, $1.turn, $0.key) }
            .prefix(cap ?? Int.max)
            .sorted { ($0.firstSeen, $0.turn, $0.key) < ($1.firstSeen, $1.turn, $1.key) }
            .enumerated().map { BlockItem(text: $1.value, rank: rank($0), seen: $1.lastSeen) }
    }

    private static func list(_ label: String, head: String?, _ details: [BlockItem]) -> BlockLine {
        BlockLine(label: label, style: .list, entries: [Entry(head: head, headRank: BlockItem.core, seen: 0,
                                                              details: details)])
    }

    /// When an entity first appeared: its earliest fact's moment, turn and key — the same in any order of writing.
    private struct Appearance: Comparable {
        let seen: Double, turn: Int, key: String

        static func < (lhs: Appearance, rhs: Appearance) -> Bool {
            (lhs.seen, lhs.turn, lhs.key) < (rhs.seen, rhs.turn, rhs.key)
        }
    }

    private static func appearance(_ facts: [StoredFact]) -> Appearance {
        let first = facts.min { ($0.firstSeen, $0.turn, $0.key) < ($1.firstSeen, $1.turn, $1.key) }
        return Appearance(seen: first?.firstSeen ?? 0, turn: first?.turn ?? 0, key: first?.key ?? "")
    }

    /// Siblings (0) before the rest of the family (1), each in the order of `memory.json`.
    private static func relation(_ facts: [StoredFact], _ words: Words) -> (Int, Int) {
        let code = facts.first?.relation?.rawValue
        let sibling = words.siblings.position(code)
        return sibling < words.siblings.count ? (0, sibling) : (1, words.family.position(code))
    }

    private static func value(_ facts: [StoredFact], _ trait: Trait) -> String? {
        facts.first { $0.trait == trait }?.value
    }

    private static func seen(_ facts: [StoredFact]) -> Double { facts.map(\.lastSeen).max() ?? 0 }
}
