import Foundation

/// Словари RUAccent tiny mode — простые JSON: `.gz` распаковывает команда копирования V4 на Mac (gzip в Foundation на
/// Linux нет). Добавки — как в `RUAccent.load`: «о» → «+о» поверх `accents_nn`, «коса» и закреплённое «поняла»
/// (стенд, `custom_homographs`) поверх омографов.
public struct AccentDictionaries: Sendable {
    let accents: [String: String]
    let omographs: [String: [String]]
    let yoWords: [String: String]
    let yoHomographs: [String: String]

    public init(accents: [String: String], omographs: [String: [String]], yoWords: [String: String],
                yoHomographs: [String: String]) {
        self.accents = accents.merging(["о": "+о", "О": "+О"]) { $1 }
        self.omographs = omographs.merging(["коса": ["к+оса", "кос+а"], "поняла": ["понял+а"]]) { $1 }
        self.yoWords = yoWords
        self.yoHomographs = yoHomographs
    }

    /// Каталог с `accents_nn.json`, `omographs.json`, `yo_words.json` и `yo_homographs.json`.
    public init(directory: URL) throws {
        func read<T: Decodable>(_ name: String) throws -> T {
            try JSONDecoder().decode(T.self, from: Data(contentsOf: directory.appendingPathComponent(name + ".json")))
        }
        try self.init(accents: read("accents_nn"), omographs: read("omographs"), yoWords: read("yo_words"),
                      yoHomographs: read("yo_homographs"))
    }
}
