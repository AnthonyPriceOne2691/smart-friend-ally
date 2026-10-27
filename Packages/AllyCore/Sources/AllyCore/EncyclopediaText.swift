import Foundation

/// `encyclopedia.json`, one copy: the word lists of the research stand (own text), the field weights and the limits;
/// the hint's frame and its place — before her words (format A of Э2) or after them (B).
struct EncyclopediaConfig: Decodable, Sendable {
    let stopWords: Set<String>, frameVerbs: Set<String>, questionWords: [String], personalWords: Set<String>
    let delicatePrefixes: [String], synonyms: [String: String]
    let fieldWeights: [Double], boost: Double, limit: Int, tokenizer: String
    let questionsPerCard: [Int], answerMaxChars: Int, answerMaxSentences: Int, oneMissingFrom: Int
    let hintFrame: String, hintPlace: String

    /// The bundled copy's bytes; a missing resource gives empty bytes, and the encyclopedia fails its self-test.
    static let bundled: Data = Bundle.module.url(forResource: "encyclopedia", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) } ?? Data()

    static func decode(_ bytes: Data) throws -> EncyclopediaConfig {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let config = try decoder.decode(EncyclopediaConfig.self, from: bytes)
        guard config.fieldWeights.count == 3, config.fieldWeights.allSatisfy({ $0 > 0 }), config.limit > 0,
              config.questionsPerCard.count == 2, (1...config.questionsPerCard[1]).contains(config.questionsPerCard[0]),
              config.answerMaxChars > 0, !config.hintFrame.isEmpty, ["before", "after"].contains(config.hintPlace)
        else { throw EncyclopediaError.config }
        return config
    }
}

enum EncyclopediaError: Error { case config }

/// Text as the research stand reads it: lower case, «ё» → «е», stress marks off, words of letters and digits; stems by
/// Snowball. A child word adds its standard words («котик» → «кошка», «кот»), looked up by the word or by its stem.
struct EncyclopediaText: Sendable {
    let config: EncyclopediaConfig
    private let synonymsByStem: [String: String]

    init(_ config: EncyclopediaConfig) {
        self.config = config
        synonymsByStem = Dictionary(config.synonyms.map { (RussianStemmer.stem($0.key), $0.value) }) { kept, _ in
            kept
        }
    }

    /// Words as the stand's `[а-яa-z0-9]+` finds them in the normalized text — run by run of code points.
    static func words(_ text: String) -> [String] {
        let plain = String(String.UnicodeScalarView(text.decomposedStringWithCanonicalMapping.unicodeScalars
            .filter { $0.value != 0x301 && $0.value != 0x300 })).precomposedStringWithCanonicalMapping
            .lowercased().replacingOccurrences(of: "ё", with: "е")
        var words: [String] = [], current = String.UnicodeScalarView()
        for scalar in plain.unicodeScalars {
            if (0x430...0x44F).contains(scalar.value) || ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar) {
                current.append(scalar)
            } else if !current.isEmpty {
                words.append(String(current))
                current = String.UnicodeScalarView()
            }
        }
        return current.isEmpty ? words : words + [String(current)]
    }

    /// Index tokens of a field: stems of its words without stop words and one-letter words.
    func stems(_ text: String) -> [String] {
        Self.words(text).filter { !config.stopWords.contains($0) && $0.count > 1 }.map(RussianStemmer.stem)
    }

    /// The query: her content words (no stop words, frames, one-letter words) and the distinct stems with synonyms.
    func query(_ words: [String]) -> (content: [String], terms: [String]) {
        let content = words.filter {
            !config.stopWords.contains($0) && $0.count > 1 && !config.frameVerbs.contains($0)
        }
        let all = content + content.flatMap { synonyms(of: $0) }
        return (content, Array(Set(all.flatMap(Self.words).map(RussianStemmer.stem))).sorted())
    }

    func synonyms(of word: String) -> [String] {
        (config.synonyms[word] ?? synonymsByStem[RussianStemmer.stem(word)])
            .map { $0.split(separator: " ").map(String.init) } ?? []
    }

    /// The stems that stand for a word: its own and those of its synonyms («котик» → «котик», «кошк», «кот»).
    func standsFor(_ word: String) -> Set<String> {
        Set([RussianStemmer.stem(word)] + synonyms(of: word).flatMap(Self.words).map(RussianStemmer.stem))
    }

    func asked(_ words: [String]) -> Bool {
        let text = " " + words.joined(separator: " ") + " "
        return config.questionWords.contains { text.contains(" \($0) ") }
    }

    func personal(_ words: [String]) -> Bool { words.contains(where: config.personalWords.contains) }

    func delicate(_ words: [String]) -> Bool {
        words.contains { word in config.delicatePrefixes.contains(where: word.hasPrefix) }
    }
}
