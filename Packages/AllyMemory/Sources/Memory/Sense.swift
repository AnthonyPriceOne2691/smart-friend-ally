import Foundation

/// The words of what she says that is not true about her (`sense.json`): pretend play, dreams, tales and riddles;
/// whose a pet is; what is negated; what makes a favourite; what she no longer likes. The code reads them after the
/// model, the model never does.
struct SenseWords: Decodable {
    struct Fiction: Decodable { let her, elly, real: [String], window: Int }
    struct Owners: Decodable { let family: [String: String], others, mine, skip: [String] }
    struct Negation: Decodable { let after, before, filler, verbs: [String] }
    let fiction: Fiction, owners: Owners, negation: Negation, favorite, unlike, pets, making, past: [String]

    static let shared: SenseWords = {
        guard let url = Bundle.module.url(forResource: "sense", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyMemory: sense.json is unreadable") }
        do {
            return try JSONDecoder().decode(SenseWords.self, from: bytes)
        } catch {
            fatalError("AllyMemory: sense.json does not decode: \(error)")
        }
    }()

    /// A line as words between spaces, so a phrase matches from a word's start: « у бабушки есть собака ».
    static func phrase(_ text: String) -> String { " " + Forbidden.tokens(text).joined(separator: " ") + " " }

    /// Her turns inside a pretend play, a dream, a tale or a riddle: a trigger in her line or in Elly's line before it
    /// opens the window on that turn and the next `window` of hers; a word of reality closes it.
    func fiction(_ turns: [MemoryTurn]) -> Set<Int> {
        var inside = Set<Int>(), left = 0
        for (index, turn) in turns.enumerated() {
            let her = Self.phrase(turn.her), elly = Self.phrase(index > 0 ? turns[index - 1].elly ?? "" : "")
            if fiction.her.contains(where: { her.contains(" " + $0) })
                || fiction.elly.contains(where: { elly.contains(" " + $0) }) {
                (left, _) = (fiction.window, inside.insert(turn.number))
            } else if left > 0, !fiction.real.contains(where: { her.contains(" " + $0 + " ") }) {
                (left, _) = (left - 1, inside.insert(turn.number))
            } else {
                left = 0
            }
        }
        return inside
    }

    /// Whose the pet is by the nearest «у кого» before its word in her line: a relation and her word for the owner, or
    /// no relation for someone not of the family; nil — hers.
    func owner(of pet: [String], in line: String) -> (relation: Relation?, word: String)? {
        let words = Forbidden.tokens(line)
        guard let at = words.firstIndex(where: { word in pet.contains { Taint.alike(word, $0, least: 3) } }),
              let mark = words[..<at].lastIndex(of: "у"),
              let who = words[(mark + 1)..<at].first(where: { !owners.skip.contains($0) }),
              !owners.mine.contains(who) else { return nil }
        if let code = owners.family.first(where: { who.hasPrefix($0.key) })?.value {
            return (Relation(rawValue: code), who)
        }
        return owners.others.contains(where: who.hasPrefix) ? (nil, who) : nil
    }

    /// The value's word is the first word (past «у меня», «уже» and the like) after «не», «нет», «нету» — after «не
    /// люблю» the one after it — or the first before «нет», «нету»: «нет хомячка», «не люблю кашу», «собаки у меня
    /// нет»; not «мурка не собачка мурка».
    func negated(_ wanted: [String], in line: String) -> Bool {
        let words = Forbidden.tokens(line)
        let near = words.indices.flatMap { index -> [String] in
            let after = words[(index + 1)...].filter { !negation.filler.contains($0) }
            let before = words[..<index].reversed().filter { !negation.filler.contains($0) }
            return (negation.after.contains(words[index])
                    ? Array(after.prefix(negation.verbs.contains(after.first ?? "") ? 2 : 1)) : [])
                + (negation.before.contains(words[index]) ? Array(before.prefix(1)) : [])
        }
        return wanted.contains { want in near.contains { Taint.alike($0, want, least: 3) } }
    }

    /// A pet she can have at home: a cat, a dog, a hamster, a fish… — not a unicorn from her birthday wish.
    func homely(_ words: [String]) -> Bool {
        words.contains { word in pets.contains { Taint.alike(word, $0, least: 3) } }
    }

    /// What she no longer likes: the words after «больше не люблю» and the like in her lines.
    func unlikes(_ turns: [MemoryTurn], stop: Set<String>) -> [String] {
        turns.flatMap { turn in
            let line = Self.phrase(turn.her)
            return unlike.compactMap { phrase -> String? in
                guard let range = line.range(of: " " + phrase + " ") else { return nil }
                let rest = line[range.upperBound...].split(separator: " ").map(String.init)
                let words = rest.prefix(2).filter { !stop.contains($0) }
                return words.isEmpty ? nil : words.joined(separator: " ")
            }
        }
    }
}
