import Foundation

/// Words and tables of `repair.json`; the Python stand reads the same file.
struct RepairData: Decodable {
    struct Numbers: Decodable { let units, teens, tens, hundreds, thousand: [String], feminine: [String: String] }
    struct Endearment: Decodable { let words, tailWords: [String], ownRe, aloneRe: String }
    let enWords, homoglyph: [String: String], translit, symbols: [[String]], ordinalSuffixes, urlTlds: [String]
    let decimalJoin, phoneMarker: String, numbers: Numbers, endearment: Endearment

    static func load() -> RepairData {
        do {
            guard let url = Bundle.module.url(forResource: "repair", withExtension: "json") else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(RepairData.self, from: Data(contentsOf: url))
        } catch {
            fatalError("Discipline: repair.json is unreadable: \(error)")
        }
    }
}

/// Everything the pipeline needs, built once from `repair.json`.
struct Rules: Sendable {
    static let shared = Rules(RepairData.load())
    static let word = "[\\p{L}\\p{N}_]"  // Python's \w: ICU's \w also takes combining marks
    static let boundary = "(?:(?<!\(word))(?=\(word))|(?<=\(word))(?!\(word)))"  // Python's \b
    static let cyrillic = "\\x{0410}-\\x{044F}\\x{0401}\\x{0451}"  // А-Я а-я Ё ё, as in the reference

    let enWords: [String: String]
    let numbers: RepairData.Numbers
    let translit: [(latin: String, cyrillic: String)]
    let homoglyph: [Character: String]
    let phoneMark: String
    let placeholder = Pattern(",?\\s*\\[[^\\]]{1,40}\\]")
    let thinking = Pattern("<\\s*think\\s*>.*?(<\\s*/\\s*think\\s*>|$)|<\\|channel\\|>.*?(<\\|message\\|>|$)",
                           [.caseInsensitive, .dotMatchesLineSeparators])
    let emoji = Pattern("[\\x{1F000}-\\x{1FAFF}\\x{2600}-\\x{27BF}\\x{2B00}-\\x{2BFF}\\x{FE0F}\\x{200D}"
                        + "\\x{2300}-\\x{23FF}\\x{2190}-\\x{21FF}\\x{25A0}-\\x{25FF}"
                        + "\\x{3030}\\x{303D}\\x{3297}\\x{3299}]|<3")
    let url: Pattern
    let list = Pattern("^\\s*(?:\\d+[.)]|[\\-–—•*])\\s+", .anchorsMatchLines)
    let markdown: [(Pattern, String)] = [
        (Pattern("\\[([^\\]]*)\\]\\([^)]*\\)"), "$1"),
        (Pattern("^\\s*#+\\s*|^\\s*>\\s?", .anchorsMatchLines), ""),
        (Pattern("\\*\\*|__|~~|[*`|]"), ""),
        (Pattern("(^|\\s)_([^_\\n]+)_"), "$1$2")
    ]
    let bracket = Pattern("[()\\[\\]\\{\\}]")
    let bracketGroup = Pattern("\\([^()]*\\)|\\[[^\\]]*\\]|\\{[^\\}]*\\}")
    let wordChar = Pattern(word)
    let sentenceEnd = Pattern("[.!?…:;,]$")
    let spaceBeforePunct = Pattern("\\s+([,.!?…:;])")
    let spaces = Pattern("\\s+")
    let edges = Pattern("^\\s+|\\s+$")
    let symbols: [(Pattern, String)]
    let latinLetter = Pattern("[A-Za-z]")
    let cjk = Pattern("[\\x{3040}-\\x{30FF}\\x{3400}-\\x{4DBF}\\x{4E00}-\\x{9FFF}"  // CJK_RE of the reference
                      + "\\x{AC00}-\\x{D7AF}\\x{F900}-\\x{FAFF}]+")
    let cyrillicLetter = Pattern("[\(cyrillic)]")
    let camelCase = Pattern("(?<=[a-z])(?=[A-Z])")
    let letters = Pattern("[A-Za-z\(cyrillic)]+")
    let digit = Pattern("\\d")
    let phone = Pattern("\\+?\\d[\\d\\-\\s()]{5,}\\d")
    let longRun = Pattern("\\d{5,}")
    let numberSteps: [(Pattern, String)]
    let digitRun = Pattern("\\d+")
    let counting = Pattern("(?<!\\d)\\d{1,2}(?!\\d)(?:[\\s,]+\\d{1,2}(?!\\d)){2,}")  // count_words: «5 4 3 2 1»
    let endearments: [Pattern]
    let sentenceStart = Pattern("(^|[.!?…]\\s+)([\\x{0430}-\\x{044F}\\x{0451}])")
    let multiSpace = Pattern("\\s{2,}")

    init(_ data: RepairData) {
        enWords = data.enWords
        numbers = data.numbers
        translit = data.translit.map { ($0[0], $0[1]) }
        homoglyph = Dictionary(uniqueKeysWithValues: data.homoglyph.map { (Character($0.key), $0.value) })
        phoneMark = " \(data.phoneMarker) "
        let notWord = "(?!\(Rules.word))"
        url = Pattern("https?://\\S+|www\\.\\S+|\(Rules.boundary)[\\p{L}\\p{N}_\\-]+\\."
                      + "(?:\(data.urlTlds.joined(separator: "|")))\(notWord)", .caseInsensitive)
        symbols = data.symbols.map { (Pattern($0[0]), NSRegularExpression.escapedTemplate(for: $0[1])) }
        numberSteps = [
            (Pattern("(\\d+):(\\d\\d)"), "$1 $2"),
            (Pattern("(\\d+)[.,](\\d+)"), "$1" + NSRegularExpression.escapedTemplate(for: data.decimalJoin) + "$2"),
            (Pattern("(\\d+)-(?:\(data.ordinalSuffixes.joined(separator: "|")))\(notWord)"), "$1")
        ]
        let terms = data.endearment
        let own = "(?:\(terms.ownRe)\\s+)?", name = "(?:\(terms.words.joined(separator: "|")))"
        let lead = "(^|(?<=[.!?…]\\s))"
        // strip_endearments: a lone «Ты моя хорошая!», mid-sentence, sentence start; without a comma only with the
        // possessive («Спокойной ночи моя радость!»), so «Собачка такая милая!» stays.
        endearments = [
            lead + terms.aloneRe + own + name + "\\s*[!.…]+\\s*",
            ",\\s*" + own + name + "\\s*(?=[,!?.…])",
            lead + own + name + "\\s*[,!]\\s*",
            "\\s+\(terms.ownRe)\\s+(?:\(terms.tailWords.joined(separator: "|")))\\s*(?=[!?.…])"
        ].map { Pattern($0, .caseInsensitive) }
    }

    func strip(_ text: String) -> String { edges.replacing(in: text, with: "") }  // str.strip()

    func collapse(_ text: String) -> String { strip(spaces.replacing(in: text, with: " ")) }  // \s+ → " ", strip
}
