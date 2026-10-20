import Foundation

/// `router.json` compiled once: concepts with stems and whole-match endings, word sets, the noise model as tables.
struct Lexicon: Sendable {
    /// A stem and its exact ending; `letters` — the stem as а…я indices for the noise model.
    struct Entry: Sendable {
        let stem: String, letters: [Int], ending: Pattern

        func ends(_ word: String, from offset: Int) -> Bool {
            ending.found(in: String(word.unicodeScalars.dropFirst(offset)))
        }

        func exact(_ word: String) -> Bool { word.hasPrefix(stem) && ends(word, from: stem.unicodeScalars.count) }
    }

    static let token = Pattern("[а-я]+|[a-z]+|\\d+")
    static let particle = Contract.compile("(?<=[а-я])-(?=(?:то|нибудь|либо|ка|таки)\\b)")
    static let doubled = Contract.compile("\\b(бо|ва)-(бо|ва)\\b")

    let data: RouterData, concepts: [(name: String, entries: [Entry])], glue: [String], clauses: [String: [Clause]]
    let sets: [String: Set<String>], doubles: Set<String>, setWords: Set<String>, noise: NoiseTable, plain: NoiseTable

    init(_ data: RouterData) {
        self.data = data
        concepts = data.lexicon.map { name, entries in
            (name, entries.map { pair in
                let stem = Self.normalize(pair.first ?? "")
                let ending = Contract.compile("^(?:\(Self.normalize(pair.last ?? "")))$")
                return Entry(stem: stem, letters: Self.letters(stem) ?? [], ending: ending)
            })
        }
        sets = data.sets.mapValues { Set($0.map(Self.normalize)) }
        glue = (data.sets["glue_prefix"] ?? []).map(Self.normalize)
        setWords = sets.values.reduce([]) { $0.union($1) }
        doubles = Set(data.exactOnly.values.joined().map(Self.normalize))
        (noise, plain) = (NoiseTable(data.noise, child: true), NoiseTable(data.noise, child: false))
        let topics = data.hazards.compactMap { hazard in hazard.clauses.map { (hazard.topic, $0.map(Clause.init)) } }
        clauses = Dictionary(topics, uniquingKeysWith: { first, _ in first })
    }

    /// normalize of the reference: lower case, ё and э as е, a hyphen before a particle or inside «бо-бо» goes, no ь ъ.
    static func normalize(_ text: String) -> String {
        var out = text.lowercased().replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "э", with: "е")
        out = doubled.replacing(in: particle.replacing(in: out, with: ""), with: "$1$2")
        return out.replacingOccurrences(of: "ь", with: "").replacingOccurrences(of: "ъ", with: "")
    }

    /// The word as а…я indices; nil when it has another character (a Latin or a digit token).
    static func letters(_ word: String) -> [Int]? {
        let letters = word.unicodeScalars.map { Int($0.value) - 0x430 }
        return letters.allSatisfy((0..<32).contains) ? letters : nil
    }

    func inSet(_ name: String, _ word: String) -> Bool { sets[name]?.contains(word) ?? false }

    /// tokenize of the reference: runs of letters or digits; a long word the router does not know may be glued.
    func tokens(_ text: String, off: Set<String>) -> [String] {
        let tokens = Self.token.matches(in: Self.normalize(text))
        return off.contains("glue") ? tokens : tokens.flatMap(glued)
    }

    func glued(_ word: String) -> [String] {
        guard word.count >= 6, !known(word) else { return [word] }
        for prefix in glue where word.hasPrefix(prefix) {
            let rest = String(word.dropFirst(prefix.count))
            if rest.count >= 3, known(rest) { return [prefix, rest] }
        }
        let head = String(word.dropLast()), last = String(word.suffix(1))
        return inSet("glue_suffix", last) && known(head) ? [head, last] : [word]
    }

    /// A word the router knows: a double, a word of a set, an exact hit of a concept.
    func known(_ word: String) -> Bool {
        doubles.contains(word) || setWords.contains(word)
            || concepts.contains { $0.entries.contains { $0.exact(word) } }
    }

    /// stem_match of the reference: a real word (`double`) only exactly; otherwise the stem reaches the word through
    /// the noise model `table` within the budget of its length, and the ending matches exactly.
    func reaches(_ entry: Entry, _ word: String, _ letters: [Int]?, double: Bool, table: NoiseTable) -> Bool {
        let count = entry.letters.count
        if count <= 2 || double { return entry.exact(word) }
        guard let tok = letters, let head = tok.first, let stem = entry.letters.first, table.first[stem][head],
              count > 3 || stem == head || table.child[stem][head] else { return false }
        let row = distances(entry.letters, tok, table)
        let limit = table.budget[min(count, table.budget.count - 1)] + 1e-9
        return tok.indices.contains { index in
            row[index] + table.sub[entry.letters[count - 1]][tok[index]] <= limit && entry.ends(word, from: index + 1)
        }
    }

    /// The edit costs of the stem without its last letter against every prefix of the token (the reference's
    /// `before`: the last letter is then set against one letter of the token).
    func distances(_ stem: [Int], _ tok: [Int], _ table: NoiseTable) -> [Double] {
        var prev = [0.0]
        for index in tok.indices { prev.append(prev[index] + table.indel(tok, index)) }
        for (row, letter) in stem.dropLast().enumerated() {
            let cost = table.indel(stem, row)
            var cur = [prev[0] + cost]
            for index in tok.indices {
                cur.append(min(prev[index] + table.sub[letter][tok[index]], prev[index + 1] + cost,
                               cur[index] + table.indel(tok, index)))
            }
            prev = cur
        }
        return prev
    }
}
