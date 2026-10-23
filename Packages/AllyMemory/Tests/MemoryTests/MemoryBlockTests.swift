import Foundation
import XCTest
@testable import Memory

final class MemoryBlockTests: StoreTestCase {
    /// M23: over the budget the lowest ranks go first and the core stays; the line caps keep the last confirmed.
    func testBudgetCutsByRankAndKeepsTheCore() throws {
        let store = try makeStore([try Fixture.session("s1", "2026-10-05 18:00", Fixture.first)])
        let at120 = try store.block(budget: 120)
        XCTAssertEqual(at120.trimmed, ["был фиолетовый", "единорог Звёздочка"])
        XCTAssertEqual(at120.tokens, 109)
        let at100 = try store.block(budget: 100)
        XCTAssertEqual(at100.trimmed, ["был фиолетовый", "единорог Звёздочка", "считать до десяти"])
        XCTAssertEqual(at100.text, Fixture.lines("Она: Соня, пять лет.", "Любимое: цвет фиолетовый.",
                                                 "Брат Тёма, восемь лет: строили замок из подушек.",
                                                 "Кошка Мурка, рыжая: любит спать на батарее."))
        XCTAssertEqual(at100.tokens, 100)
        XCTAssertEqual(try store.block(budget: 10).text, Fixture.lines("Она: Соня, пять лет.", "Брат Тёма, восемь лет.",
                                                                       "Кошка Мурка, рыжая."))

        let big = try makeStore(try bigBase())
        let block = try big.block()
        XCTAssertLessThanOrEqual(block.tokens, 300)
        XCTAssertEqual(block.trimmed, [])
        let lines = block.text.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines.contains("Любит: любит 3, любит 4, любит 5, любит 6."))
        XCTAssertTrue(lines.contains("Умеет: умеет 4, умеет 5, умеет 6."))
        XCTAssertTrue(lines.contains("Брат Тёма: брат 4; брат 5; брат 6."))
        XCTAssertTrue(lines.contains("Кошка Мурка: кошка 4; кошка 5; кошка 6."))
        XCTAssertTrue(lines.contains("Бабушка Нина: бабушка 5; бабушка 6."))
        XCTAssertTrue(lines.contains("Придумала: дракон Искра — дракон 6; единорог Звёздочка — единорог 6."))
    }

    /// M24: the block's bytes do not depend on the order the sessions were written, on a second render or a reopen; a
    /// new detail of the cat changes only her line.
    func testBlockBytesDoNotDependOnWriteOrder() throws {
        let sessions = try Fixture.family()
        let folder = try makeFolder(), forward = try MemoryStore(directory: folder)
        for session in sessions { try forward.write(session) }
        let reversed = try makeStore(Array(sessions.reversed()))
        let text = try forward.block().text
        XCTAssertEqual(try reversed.block().text, text)
        XCTAssertEqual(try forward.block().text, text)
        XCTAssertEqual(try MemoryStore(directory: folder).block().text, text)

        let flies = [Candidate(Fixture.cat, .detail, "ловит мух", turn: 2)]
        try forward.write(try Fixture.session("s8", "2026-10-10 18:00", flies))
        let before = text.split(separator: "\n"), after = try forward.block().text.split(separator: "\n")
        XCTAssertEqual(before.count, after.count)
        XCTAssertEqual(zip(before, after).filter { $0 != $1 }.map { String($1) },
                       ["Кошка Мурка, рыжая: любит спать на батарее; ловит мух."])
    }

    /// M23's large base: 6 «любит», 4 «умеет», 5 details of the brother and of the cat, 3 of the grandma, 2 of each of
    /// two creations — one a day, so the last confirmed are the last days.
    private func bigBase() throws -> [MemorySession] {
        let nina = Subject.person(.grandma, name: "Нина"), dragon = Subject.creation(kind: "дракон", name: "Искра")
        let names = try Fixture.session("d0", "2026-09-30 18:00", [
            Candidate(Fixture.brother, .name, "Тёма", turn: 1), Candidate(Fixture.cat, .species, "кошка", turn: 2),
            Candidate(Fixture.cat, .name, "Мурка", turn: 2), Candidate(nina, .name, "Нина", turn: 3),
            Candidate(dragon, .species, "дракон", turn: 4), Candidate(dragon, .name, "Искра", turn: 4),
            Candidate(Fixture.unicorn, .species, "единорог", turn: 5),
            Candidate(Fixture.unicorn, .name, "Звёздочка", turn: 5)
        ])
        return try [names] + (1...6).map { day in
            try Fixture.session("d\(day)", "2026-10-0\(day) 18:00", [
                (1, Candidate(.child, .likes, "любит \(day)", turn: 1)),
                (3, Candidate(.child, .can, "умеет \(day)", turn: 2)),
                (2, Candidate(Fixture.brother, .detail, "брат \(day)", turn: 3)),
                (2, Candidate(Fixture.cat, .detail, "кошка \(day)", turn: 4)),
                (4, Candidate(nina, .detail, "бабушка \(day)", turn: 5)),
                (5, Candidate(dragon, .detail, "дракон \(day)", turn: 6)),
                (5, Candidate(Fixture.unicorn, .detail, "единорог \(day)", turn: 7))
            ].filter { day >= $0.0 }.map(\.1))
        }
    }
}
