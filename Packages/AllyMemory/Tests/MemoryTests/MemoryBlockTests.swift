import Foundation
import XCTest
@testable import Memory

final class MemoryBlockTests: StoreTestCase {
    /// M23: over the budget the lowest ranks go first and the core stays; the line caps keep the last confirmed. With
    /// the new form's longer header only the core is left at 100 and 10, over the budget.
    func testBudgetCutsByRankAndKeepsTheCore() throws {  // M23
        let store = try makeStore([try Fixture.session("s1", "2026-10-05 18:00", Fixture.first)])
        let at120 = try store.block(budget: 120)
        XCTAssertEqual(at120.trimmed, ["был фиолетовый", "единорог Звёздочка", "считать до десяти",  // M23
                                       "цвет фиолетовый", "любит спать на батарее"])
        XCTAssertEqual(at120.text, Fixture.lines("Она: пять лет.",  // M23
                                                 "Брат Тёма, восемь лет: строили замок из подушек.",
                                                 "Кошка Мурка, рыжая."))
        XCTAssertEqual(at120.tokens, 118)  // M23
        let core = Fixture.lines("Она: пять лет.", "Брат Тёма, восемь лет.", "Кошка Мурка, рыжая.")
        let at100 = try store.block(budget: 100)
        XCTAssertEqual(at100.text, core)  // M23
        XCTAssertEqual(at100.tokens, 108)  // M23
        XCTAssertEqual(try store.block(budget: 10).text, core)  // M23

        let big = try makeStore(try bigBase())
        let block = try big.block(budget: 300)  // M23
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

    /// The new form, signed by the parent 2026-10-29: the header with «верь ей» and the priority of the safety rules
    /// and the hint, her line without her name, the budget 200 — the parent's example on invented facts, exactly.
    func testTheNewFormIsTheParentsExample() throws {  // M43
        let grandma = Subject.person(.grandma, name: "Нина")
        let store = try makeStore([
            try Fixture.session("s1", "2026-10-05 18:00",
                                Fixture.first + [Candidate(.child, .birthday, "в декабре", turn: 2)]),
            try Fixture.session("s2", "2026-10-06 18:00", [
                Candidate(.child, .favorite, "блинчики", slot: .food, turn: 3),
                Candidate(.child, .likes, "лепить", turn: 4),
                Candidate(grandma, .name, "Нина", turn: 5), Candidate(grandma, .detail, "печёт пирожки", turn: 5)
            ]),
            try Fixture.session("s3", "2026-10-07 18:00", [
                Candidate(.child, .likes, "качели", turn: 2),
                Candidate(Fixture.brother, .detail, "научил играть в шашки", turn: 6),
                Candidate(Fixture.cat, .detail, "ловит мух", turn: 8)
            ]),
            try Fixture.session("s4", "2026-10-08 18:00", [
                Candidate(.child, .likes, "рисовать", turn: 3),
                Candidate(Fixture.brother, .detail, "ходит на футбол", turn: 5)
            ])
        ])
        let block = try store.block()
        XCTAssertEqual(MemoryBlock.budget, 200)
        XCTAssertEqual(block.text, Fixture.lines(
            "Она: пять лет, день рождения в декабре.", "Любимое: цвет фиолетовый, еда блинчики.",
            "Любит: лепить, качели, рисовать.", "Умеет: считать до десяти.",
            "Брат Тёма, восемь лет: строили замок из подушек; научил играть в шашки; ходит на футбол.",
            "Кошка Мурка, рыжая: любит спать на батарее; ловит мух.", "Бабушка Нина."))
        XCTAssertEqual(block.trimmed, ["был фиолетовый", "единорог Звёздочка", "печёт пирожки"])
        XCTAssertEqual(block.tokens, 197)
        XCTAssertFalse(block.text.contains("Соня"))
    }

    /// M24: the block's bytes do not depend on the order the sessions were written, on a second render or a reopen; a
    /// new detail of the cat changes only her line — at the budget of the signed example (300), so no cut moves a line.
    func testBlockBytesDoNotDependOnWriteOrder() throws {  // M24
        let sessions = try Fixture.family()
        let folder = try makeFolder(), forward = try MemoryStore(directory: folder)
        for session in sessions { try forward.write(session) }
        let reversed = try makeStore(Array(sessions.reversed()))
        let text = try forward.block(budget: 300).text  // M24
        XCTAssertEqual(try reversed.block(budget: 300).text, text)  // M24
        XCTAssertEqual(try forward.block(budget: 300).text, text)  // M24
        XCTAssertEqual(try MemoryStore(directory: folder).block(budget: 300).text, text)  // M24

        let flies = [Candidate(Fixture.cat, .detail, "ловит мух", turn: 2)]
        try forward.write(try Fixture.session("s8", "2026-10-10 18:00", flies))
        let before = text.split(separator: "\n"), after = try forward.block(budget: 300).text.split(separator: "\n")
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
