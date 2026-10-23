import AllySQLite
import XCTest
@testable import Memory

/// M29: her lines and the candidates of one session — invented; the store in a fresh folder.
private enum Guarded {
    static let heard = [
        "Моя фамилия Петрова", "Мы живём на улице Морковной", "Я хожу в садик номер семь", "Мне пять лет"
    ]
    static let details = [
        "живёт на улице Морковной", "мамин телефон восемь девятьсот один два три четыре пять",
        "ходит в садик номер семь", "бабушка Ольга Петровна", "воспитательница Ольга", "болеет ветрянкой",
        "мама с папой поссорились", "копит деньги на велосипед", "ходит в церковь", "потерялась в магазине",
        "чужой дядя дал конфету", "секрет от мамы", "пароль от планшета", "родилась в две тысячи двадцать первом году",
        "гуляли у Морковного пруда", "у неё семь кукол"
    ]
    static let refused = ["surname": 2, "address": 2, "phone": 1, "institution": 2, "outside_adult": 1, "health": 1,
                          "conflict": 1, "money": 1, "faith": 1, "incident": 2, "secret": 1, "password": 1,
                          "birth_year": 1]
    static let row: [SQLiteValue] = [.int(1), .text("detail"), .null, .text("живёт на улице Морковной"),
                                     .text("живет на улице морковной"), .text("s2"), .int(1), .real(0.9), .real(0),
                                     .real(0)]
    static let bypass: [(String, [SQLiteValue])] = [
        (Schema.insertFact, row), ("UPDATE fact SET value = 'болеет ветрянкой' WHERE value = 'качели'", []),
        ("INSERT INTO seen VALUES (1, 's2', 0, 1, 'бабушка Ольга Петровна', 0.9)", []),
        ("UPDATE seen SET value = 'воспитательница Ольга'", [])
    ]

    static func session() throws -> MemorySession {
        let candidates = [Candidate(.child, .name, "Петрова", turn: 1), Candidate(.child, .age, "5", turn: 4),
                          Candidate(.child, .likes, "качели", turn: 5)]
            + details.enumerated().map { Candidate(.child, .detail, $0.element, turn: $0.offset + 6) }
        return MemorySession(id: "s1", started: try Fixture.at("2026-10-05 18:00"), candidates: candidates,
                             heard: heard)
    }
}

final class MemoryGuardTests: StoreTestCase {
    func testForbiddenOnAnyPath() throws {  // M29
        let folder = try makeFolder()
        let store = try MemoryStore(directory: folder)
        XCTAssertEqual(try store.write(try Guarded.session()), WriteReport(added: 2, refused: Guarded.refused))
        XCTAssertEqual(try store.facts().map(\.value), ["5", "качели"])

        let path = folder.appendingPathComponent(MemoryStore.fileName).path
        let raw = try SQLiteConnection(path: path)
        try Forbidden.install(on: raw)
        for (sql, values) in Guarded.bypass {
            XCTAssertThrowsError(try raw.run(sql, values), sql) { error in
                XCTAssertEqual(error as? SQLiteError, SQLiteError(code: 19, message: "forbidden value"), sql)
            }
        }
        XCTAssertThrowsError(try SQLiteConnection(path: path).run(Schema.insertFact, Guarded.row)) { error in
            XCTAssertEqual(error as? SQLiteError, SQLiteError(code: 1, message: "no such function: forbidden"))
        }
        raw.close()
        XCTAssertEqual(try store.facts(history: true).count, 2)
        XCTAssertEqual(try Fixture.occurrences(["Петров", "Морковн", "ветрянк", "Ольг"], in: folder), 0)
    }
}
