import Foundation
import XCTest
@testable import Memory

/// Fixtures of the spec's examples: invented names only, moments at +03:00, a store in a fresh temporary folder.
enum Fixture {
    static let header = "Что ты помнишь о ней из прошлых разговоров. Это для тебя: не пересказывай и не перечисляй, "
        + "вспоминай что-то одно, когда к месту. Если сейчас она говорит по-другому, верь ей. Правила безопасности и "
        + "подсказка к её вопросу важнее этого."  // M43
    static let brother = Subject.person(.brother, name: "Тёма")
    static let cat = Subject.pet(species: "кошка", name: "Мурка")
    static let unicorn = Subject.creation(kind: "единорог", name: "Звёздочка")
    static let names = ["Соня", "Тёма", "Мурка", "Звёздочка", "Нина", "Миша"]

    /// M15, session `s1`: 14 checked facts.
    static let first: [Candidate] = [
        Candidate(.child, .name, "Соня", turn: 1), Candidate(.child, .age, "5", turn: 2),
        Candidate(brother, .name, "Тёма", turn: 4), Candidate(brother, .age, "8", turn: 4),
        Candidate(brother, .detail, "строили замок из подушек", turn: 6),
        Candidate(cat, .species, "кошка", turn: 3), Candidate(cat, .name, "Мурка", turn: 3),
        Candidate(cat, .color, "рыжая", turn: 3), Candidate(cat, .detail, "любит спать на батарее", turn: 12),
        Candidate(.child, .favorite, "фиолетовый", slot: .color, turn: 5),
        Candidate(.child, .can, "считать до десяти", turn: 14, anchor: .found),
        Candidate(unicorn, .species, "единорог", turn: 16), Candidate(unicorn, .name, "Звёздочка", turn: 16),
        Candidate(unicorn, .detail, "был фиолетовый", turn: 17)
    ]

    /// M20: sessions `s1`–`s5`.
    static func family() throws -> [MemorySession] {
        let grandma = Subject.person(.grandma, name: nil), nina = Subject.person(.grandma, name: "Нина")
        let misha = Subject.person(.brother, name: "Миша"), fish = Subject.pet(species: "рыбка", name: nil)
        return [
            try session("s1", "2026-10-05 18:00", first),
            try session("s2", "2026-10-06 18:00", [Candidate(grandma, .detail, "печёт пирожки", turn: 7)]),
            try session("s3", "2026-10-07 18:00", [
                Candidate(nina, .name, "Нина", turn: 5), Candidate(nina, .detail, "у бабушки огород", turn: 5),
                Candidate(.person(.brother, name: "Тема"), .name, "Тема", turn: 2),
                Candidate(misha, .name, "Миша", turn: 6), Candidate(misha, .age, "3", turn: 6)
            ]),
            try session("s4", "2026-10-08 18:00", [Candidate(fish, .species, "рыбка", turn: 3),
                                                   Candidate(fish, .detail, "две рыбки в аквариуме", turn: 3)]),
            try session("s5", "2026-10-09 18:00", [Candidate(fish, .species, "рыбка", turn: 2),
                                                   Candidate(fish, .detail, "одна золотая", turn: 2)])
        ]
    }

    static func session(_ id: String, _ moment: String, _ candidates: [Candidate]) throws -> MemorySession {
        MemorySession(id: id, started: try at(moment), candidates: candidates)
    }

    /// «2026-10-05 18:00» at +03:00.
    static func at(_ moment: String) throws -> Date {
        let iso = moment.replacingOccurrences(of: " ", with: "T") + ":00+03:00"
        return try XCTUnwrap(ISO8601DateFormatter().date(from: iso), moment)
    }

    static func lines(_ text: String...) -> String { ([header] + text).joined(separator: "\n") }

    /// How many times the names occur in the files of a folder: UTF-8, as written, lower case, with «е» for «ё».
    static func occurrences(_ names: [String], in folder: URL) throws -> Int {
        let forms = Set(names.flatMap { [$0, $0.lowercased(), $0.replacingOccurrences(of: "ё", with: "е")] })
        var found = 0
        for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            let bytes = try Data(contentsOf: file)
            for form in forms.map({ Data($0.utf8) }) {
                var start = bytes.startIndex
                while let hit = bytes.range(of: form, in: start..<bytes.endIndex) {
                    (found, start) = (found + 1, hit.upperBound)
                }
            }
        }
        return found
    }
}

/// A test case whose store lives in its own temporary folder, removed after the test.
class StoreTestCase: XCTestCase {
    func makeFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("memory-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func makeStore(_ sessions: [MemorySession] = []) throws -> MemoryStore {
        let store = try MemoryStore(directory: try makeFolder())
        for session in sessions { try store.write(session) }
        return store
    }
}
