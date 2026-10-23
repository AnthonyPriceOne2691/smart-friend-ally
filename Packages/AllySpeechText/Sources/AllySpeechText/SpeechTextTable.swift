import Foundation

/// Таблица отвергнута: правило названо ключом, чтобы его нашли в `speech-text.json`.
public enum SpeechTextError: Error, Equatable {
    /// Правило чтения меняет число гласных — ударение некуда перенести (Z11).
    case vowels(String)
    /// Закреплённое ударение: буквы формы не те, что у ключа, или ударной нет.
    case stress(String)
}

/// Таблица произношения для голоса (`speech-text.json`): закреплённые ударения поверх расстановщика, записи имён и
/// правила чтения. Строки — данные: второй круг образцов добавляет их без правки кода.
public struct SpeechTextTable: Sendable {
    /// Окончание слова: `to` — под ударением на последней гласной, `unstressed` — без него; `except` — слова целиком,
    /// которые правило не трогает («много» при «-ого»).
    public struct Ending: Sendable, Decodable, Equatable {
        public let end: String
        public let to: String
        public let unstressed: String?
        public let except: [String]?

        public init(end: String, to: String, unstressed: String? = nil, except: [String]? = nil) {
            self.end = end
            self.to = to
            self.unstressed = unstressed
            self.except = except
        }
    }

    let stress: [String: SpokenWord]
    let names: [String: SpokenWord]
    let words: [String: String]
    let endings: [Ending]
    let parts: [(String, String)]

    /// Ключи — слова строчными; формы `stress` и `names` — с «+» перед ударной гласной.
    public init(stress: [String: String] = [:], names: [String: String] = [:], words: [String: String] = [:],
                endings: [Ending] = [], parts: [String: String] = [:]) throws {
        let pinned = stress.mapValues(SpokenWord.init(plus:))
        if let bad = pinned.first(where: { $0.value.letters.lowercased() != $0.key || $0.value.stress == nil }) {
            throw SpeechTextError.stress(bad.key)
        }
        let pairs = (words.map { ($0.key, $0.value) } + parts.map { ($0.key, $0.value) })
            + endings.flatMap { [($0.end, $0.to), ($0.end, $0.unstressed ?? $0.to)] }
        if let bad = pairs.first(where: { Self.vowels($0.0) != Self.vowels($0.1) }) {
            throw SpeechTextError.vowels(bad.0)
        }
        self.stress = pinned
        self.names = names.mapValues(SpokenWord.init(plus:))
        self.words = words
        // Длинное раньше короткого, при равной длине — по алфавиту: порядок правил не зависит от порядка в словаре.
        self.endings = endings.sorted { Self.longerFirst($0.end, $1.end) }
        self.parts = parts.map { ($0.key, $0.value) }.sorted { Self.longerFirst($0.0, $1.0) }
    }

    public init(json: Data) throws {
        let raw = try JSONDecoder().decode(Raw.self, from: json)
        try self.init(stress: raw.stress ?? [:], names: raw.names ?? [:], words: raw.words ?? [:],
                      endings: raw.endings ?? [], parts: raw.parts ?? [:])
    }

    /// Таблица пакета — `Resources/speech-text.json`.
    public static func bundled() throws -> SpeechTextTable {
        guard let url = Bundle.module.url(forResource: "speech-text", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try SpeechTextTable(json: Data(contentsOf: url))
    }

    private static func vowels(_ text: String) -> Int { SpokenWord(letters: text, stress: nil).vowelCount }

    private static func longerFirst(_ lhs: String, _ rhs: String) -> Bool {
        lhs.count == rhs.count ? lhs < rhs : lhs.count > rhs.count
    }

    private struct Raw: Decodable {
        let stress: [String: String]?
        let names: [String: String]?
        let words: [String: String]?
        let endings: [Ending]?
        let parts: [String: String]?
    }
}
