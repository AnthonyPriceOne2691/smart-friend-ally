import AllySQLite
import Foundation

/// The never-stored list (`forbidden.json`): a rule per item, one definition for the write's check and the database's
/// trigger; text without case and with «е» for «ё». The taint of her words lives in `Taint`.
struct Forbidden {
    struct Rule: Decodable { let id: String, any: [String] }
    struct Trigger: Decodable { let rule: String, after: [String], words: Int, before: Bool, numbers: Bool }
    struct List: Decodable {
        let rules: [Rule], taint: [Trigger], skip: Set<String>, adjective: [String], numbers: [String: Int]
    }

    static let shared: Forbidden = {
        guard let url = Bundle.module.url(forResource: "forbidden", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyMemory: forbidden.json is unreadable") }
        do {
            return try Forbidden(try JSONDecoder().decode(List.self, from: bytes))
        } catch {
            fatalError("AllyMemory: forbidden.json does not load: \(error)")
        }
    }()

    let words: List, patterns: [NSRegularExpression]

    init(_ words: List) throws {
        self.words = words
        patterns = try words.rules.map { try NSRegularExpression(pattern: $0.any.joined(separator: "|")) }
    }

    /// The id of the first rule the text falls under; nil — it may be stored.
    func rule(_ text: String) -> String? {
        let text = MemoryStore.key(text), range = NSRange(location: 0, length: (text as NSString).length)
        return zip(words.rules, patterns).first { $0.1.firstMatch(in: text, range: range) != nil }?.0.id
    }

    /// The numbers a text says: in digits or in words, each word by itself.
    func numbers(_ tokens: some Sequence<String>) -> [Int] { tokens.compactMap { Int($0) ?? words.numbers[$0] } }

    /// The words of a text without case, «ё» and punctuation.
    static func tokens(_ text: String) -> [String] {
        MemoryStore.key(text).split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    /// The database's own check `forbidden(text)`: the triggers call it on every write of a value; a connection
    /// without it writes nothing.
    static func install(on db: SQLiteConnection) throws { try db.function("forbidden") { shared.rule($0) != nil } }
}

/// What her lines of a session taint: the word after «фамилия», the words after «улица» and the adjective before it,
/// the numbers after «садик номер». A tainted value is stored in no field; the taint itself is not stored.
struct Taint {
    struct Mark { let word: String, rule: String }
    private(set) var marks: [Mark] = [], numbers: [Int: String] = [:]
    private let forbidden: Forbidden

    init(heard: [String], forbidden: Forbidden = .shared) {
        self.forbidden = forbidden
        for tokens in heard.map(Forbidden.tokens) {
            for (index, token) in tokens.enumerated() {
                for trigger in forbidden.words.taint where trigger.after.contains(where: token.hasPrefix) {
                    mark(trigger, index, tokens)
                }
            }
        }
    }

    /// The rule of the taint the value carries; nil — none.
    func rule(_ value: String) -> String? {
        let tokens = Forbidden.tokens(value)
        if let mark = marks.first(where: { mark in tokens.contains { Self.alike($0, mark.word) } }) { return mark.rule }
        return forbidden.numbers(tokens).lazy.compactMap { numbers[$0] }.first
    }

    /// One word in another form: the same, or the same start of at least max(`least`, the shorter length − 2) letters
    /// (4 for the taint, 3 for the anchor of a value).
    static func alike(_ word: String, _ marked: String, least: Int = 4) -> Bool {
        let common = zip(word, marked).prefix { $0 == $1 }.count
        return word == marked || common >= max(least, min(word.count, marked.count) - 2)
    }

    private mutating func mark(_ trigger: Forbidden.Trigger, _ index: Int, _ tokens: [String]) {
        let after = tokens[(index + 1)...].filter { !forbidden.words.skip.contains($0) }
        if trigger.numbers {
            let run = after.prefix { !forbidden.numbers([$0]).isEmpty }
            for number in forbidden.numbers(run) { numbers[number] = trigger.rule }
            return
        }
        var taken = after.prefix(trigger.words).filter { $0.count >= 3 }
        if trigger.before, index > 0, !forbidden.words.skip.contains(tokens[index - 1]),
           forbidden.words.adjective.contains(where: tokens[index - 1].hasSuffix) {
            taken.append(tokens[index - 1])
        }
        marks += taken.map { Mark(word: $0, rule: trigger.rule) }
    }
}
