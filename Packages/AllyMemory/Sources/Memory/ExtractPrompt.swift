import Foundation

/// The parse's words (`extract.json`) and its two prompt texts, loaded once.
struct ExtractTexts: Decodable {
    struct Errors: Decodable { let noJson, notTemplate: String }
    let params: ExtractParams, retry: String, errors: Errors, her: String, elly: String, nothing: String
    let yes: Set<String>, stop: Set<String>
    var system = "", user = ""

    enum CodingKeys: String, CodingKey { case params, retry, errors, her, elly, nothing, yes, stop }

    static let shared: ExtractTexts = {
        func text(_ name: String, _ kind: String) -> String {
            guard let url = Bundle.module.url(forResource: name, withExtension: kind),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                fatalError("AllyMemory: \(name).\(kind) is unreadable")
            }
            return text
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            var texts = try decoder.decode(ExtractTexts.self, from: Data(text("extract", "json").utf8))
            (texts.system, texts.user) = (text("extract.system.ru", "md"), text("extract.user.ru", "md"))
            return texts
        } catch {
            fatalError("AllyMemory: extract.json does not decode: \(error)")
        }
    }()
}

/// The request to the model: the system text as the resource; the user text — the resource with what is known and the
/// conversation by her turn numbers; FNV-1a 64 of both.
struct ExtractPrompt {
    let system: String, user: String
    var hash: String { Self.fnv1a(system + "\n" + user) }

    init(known facts: [StoredFact], turns: [MemoryTurn], texts: ExtractTexts = .shared) {
        let dialog = turns.map { turn in
            "\(turn.number). \(texts.her): \(turn.her)" + (turn.elly.map { "\n   \(texts.elly): \($0)" } ?? "")
        }
        system = texts.system
        user = texts.user.replacingOccurrences(of: "{known}", with: Self.known(facts, texts))
            .replacingOccurrences(of: "{dialog}", with: dialog.joined(separator: "\n"))
    }

    /// Who is who in the active facts, without details: «Соня, пять лет; брат Тёма, восемь лет.».
    static func known(_ facts: [StoredFact], _ texts: ExtractTexts) -> String {
        let words = Words.shared
        let parts = Dictionary(grouping: facts, by: \.entity).sorted { $0.key < $1.key }.map { _, group in
            let value = { (trait: Trait) in group.first { $0.trait == trait }?.value }
            let relation = group.first?.relation.flatMap { (words.siblings + words.family).label($0.rawValue) }
            let who = [relation, value(.species), value(.name)].compactMap { $0 }.joined(separator: " ")
            return ([who] + [value(.age).map(words.age)].compactMap { $0 }).filter { !$0.isEmpty }
                .joined(separator: ", ")
        }.filter { !$0.isEmpty }
        return parts.isEmpty ? texts.nothing : parts.joined(separator: "; ") + "."
    }

    /// FNV-1a 64 of the UTF-8 bytes as 16 hex digits — the project's data hash.
    static func fnv1a(_ text: String) -> String {
        let hash = text.utf8.reduce(UInt64(0xcbf2_9ce4_8422_2325)) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01b3 }
        return String(format: "%016llx", hash)
    }
}
