import Foundation
@testable import AllyAccent

/// Запись RUAccent на Python для повтора логики (`Fixtures/accent_replay.json`, генератор вне git —
/// `local/spike/tts-swift/scripts/make_accent_replay.py`): позиции стенда с каждым вызовом моделей (разметка и логиты,
/// которые Python посчитал), выборка словарей под слова фраз и пробы причуд; sha256 источников — в `provenance`.
struct Replay: Decodable {
    struct Tables: Codable {
        let accents: [String: String]
        let omographs: [String: [String]]
        let yoWords: [String: String]
        let yoHomographs: [String: String]
    }

    /// Добавки пробы поверх выборки.
    struct Overrides: Decodable {
        let accents: [String: String]?
        let yoWords: [String: String]?
    }

    struct Call: Decodable {
        let model: String
        let text: String
        let pair: String?
        let ids: [Int]
        let tokens: [String]?
        let special: [Int]?
        let offsets: [[Int]]?
        let logits: [[Float]]
    }

    struct Item: Decodable {
        let pos: String
        let cat: String
        let textIn: String
        let textOut: String
        let calls: [Call]
        let dictionaries: Overrides?
    }

    let dictionaries: Tables
    let positions: [Item]
    let probes: [Item]

    struct Missing: Error {}

    static let shared = Result { try load() }

    static func load() throws -> Replay {
        guard let fixtures = Bundle.module.url(forResource: "Fixtures", withExtension: nil) else { throw Missing() }
        let data = try Data(contentsOf: fixtures.appendingPathComponent("accent_replay.json"))
        return try JSONDecoder().decode(Replay.self, from: data)
    }

    /// Выборка позиций стенда идёт через файлы, как в приложении: четыре JSON во временном каталоге и
    /// `AccentDictionaries(directory:)`; у пробы — добавки поверх выборки.
    func dictionaries(for item: Item) throws -> AccentDictionaries {
        guard let extra = item.dictionaries else { return try Self.files.get() }
        return AccentDictionaries(accents: dictionaries.accents.merging(extra.accents ?? [:]) { $1 },
                                  omographs: dictionaries.omographs, yoWords: dictionaries.yoWords.merging(
                                    extra.yoWords ?? [:]) { $1 }, yoHomographs: dictionaries.yoHomographs)
    }

    static let files = Result { () throws -> AccentDictionaries in
        let tables = try shared.get().dictionaries
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("accent-replay-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for (name, table) in [("accents_nn", tables.accents), ("yo_words", tables.yoWords),
                              ("yo_homographs", tables.yoHomographs)] as [(String, [String: String])] {
            try JSONEncoder().encode(table).write(to: dir.appendingPathComponent(name + ".json"))
        }
        try JSONEncoder().encode(tables.omographs).write(to: dir.appendingPathComponent("omographs.json"))
        return try AccentDictionaries(directory: dir)
    }
}

/// Двойник токенизаторов и моделей одной позиции: разметка и логиты — записанные Python. Вход, которого Python не
/// подавал, — отказ: логика подала модели не ту строку; `unused` — записанные вызовы, которых логика не сделала.
final class ReplayTwin: AccentTokenizers, AccentModels, @unchecked Sendable {
    struct Unrecorded: Error {
        let key: String
    }

    private var encodings: [String: Encoding] = [:]
    private var logits: [String: [[[Float]]]] = [:]

    init(_ calls: [Replay.Call]) {
        for call in calls {
            encodings[call.model + "|" + call.text + "|" + (call.pair ?? "")] = Encoding(
                ids: call.ids, tokens: call.tokens ?? [], specialTokensMask: (call.special ?? []).map { $0 == 1 },
                offsets: (call.offsets ?? []).map { $0[0]..<$0[1] })
            logits[call.model + "|\(call.ids)", default: []].append(call.logits)
        }
    }

    var unused: Int { logits.values.reduce(0) { $0 + $1.count } }

    func yo(_ sentence: String) throws -> Encoding { try encoding("yo|" + sentence + "|") }

    func omograph(_ text: String, _ hypothesis: String) throws -> Encoding {
        try encoding("omograph|" + text + "|" + hypothesis)
    }

    func accent(_ word: String) throws -> Encoding { try encoding("accent|" + word + "|") }

    func omograph(_ pair: Encoding) throws -> [Float] { try next("omograph", pair)[0] }

    func yo(_ sentence: Encoding) throws -> [[Float]] { try next("yo", sentence) }

    func accent(_ word: Encoding) throws -> [[Float]] { try next("accent", word) }

    private func encoding(_ key: String) throws -> Encoding {
        guard let found = encodings[key] else { throw Unrecorded(key: key) }
        return found
    }

    private func next(_ model: String, _ encoding: Encoding) throws -> [[Float]] {
        let key = model + "|\(encoding.ids)"
        guard let queue = logits[key], let first = queue.first else { throw Unrecorded(key: key) }
        logits[key] = queue.count == 1 ? nil : Array(queue.dropFirst())
        return first
    }
}
