import Foundation
import XCTest
@testable import Memory

final class MemoryStoreTests: StoreTestCase {
    /// M15: the first session — facts with their anchors, the code's confidence, the block exactly.
    func testFirstSessionGivesFactsAndTheBlock() throws {  // M15
        let store = try makeStore()
        let report = try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        XCTAssertEqual(report, WriteReport(added: 14))
        let facts = try store.facts()
        XCTAssertEqual(facts.count, 14)
        XCTAssertEqual(Set(facts.map(\.entity)).count, 4)
        XCTAssertEqual(Set(facts.map(\.session)), ["s1"])
        XCTAssertEqual(facts.map(\.turn), Fixture.first.map(\.turn))
        XCTAssertEqual(facts.map(\.confidence), Fixture.first.map { $0.value == "считать до десяти" ? 0.8 : 0.9 })
        let block = try store.block()
        XCTAssertEqual(block.text, Fixture.lines("Она: Соня, пять лет.", "Любимое: цвет фиолетовый.",
                                                 "Умеет: считать до десяти.",
                                                 "Брат Тёма, восемь лет: строили замок из подушек.",
                                                 "Кошка Мурка, рыжая: любит спать на батарее.",
                                                 "Придумала: единорог Звёздочка — был фиолетовый."))
        XCTAssertEqual(block.text.unicodeScalars.count, 342)
        XCTAssertEqual(block.tokens, 127)
        XCTAssertEqual(block.trimmed, [])
    }

    /// M16: «Мурка — кошка, а не собака» — one pet, the dog goes to the history.
    func testCorrectionMovesTheOldValueToTheHistory() throws {  // M16
        let dog = Subject.pet(species: "собака", name: "Мурка")
        let store = try makeStore([try Fixture.session("s0", "2026-10-04 18:00", [
            Candidate(dog, .species, "собака", turn: 3), Candidate(dog, .name, "Мурка", turn: 3)
        ])])
        let report = try store.write(try Fixture.session("s1", "2026-10-05 18:00", [
            Candidate(Fixture.cat, .species, "кошка", turn: 3), Candidate(Fixture.cat, .name, "Мурка", turn: 3)
        ]))
        XCTAssertEqual(report.replaced, 1)
        XCTAssertEqual(Set(try store.facts().map(\.entity)).count, 1)
        let species = try store.facts(history: true).filter { $0.trait == .species }
        let cat = try XCTUnwrap(species.first(where: \.active))
        XCTAssertEqual([cat.value, cat.session, "\(cat.turn)", "\(cat.confidence)"], ["кошка", "s1", "3", "0.9"])
        XCTAssertEqual(species.filter { !$0.active }.map(\.value), ["собака"])
        XCTAssertEqual(species.first { !$0.active }?.supersededBy, cat.id)
        XCTAssertEqual(try store.block().text, Fixture.lines("Кошка Мурка."))
    }

    /// M17: newer replaces older by the session's date; a replayed older session changes nothing.
    func testUpdateByDateAndOlderSessionDoesNotOverwrite() throws {  // M17
        let brother = Fixture.brother, color = { (value: String) in
            Candidate(.child, .favorite, value, slot: .color, turn: 5) }
        let store = try makeStore([
            try Fixture.session("s1", "2026-10-05 18:00", [
                Candidate(brother, .name, "Тёма", turn: 4), Candidate(brother, .age, "8", turn: 4), color("фиолетовый")
            ]),
            try Fixture.session("s7", "2026-10-11 18:00", [color("розовый")]),
            try Fixture.session("s9", "2026-10-13 18:00", [Candidate(brother, .age, "9", turn: 3)]),
            try Fixture.session("s10", "2026-10-14 18:00", [color("зелёный")])
        ])
        let before = try store.facts(history: true)
        let older = [Candidate(brother, .age, "8", turn: 4)]
        let replay = try store.write(try Fixture.session("s1", "2026-10-05 18:00", older))
        XCTAssertEqual(replay, WriteReport(skippedOlder: 1))
        XCTAssertEqual(try store.facts(history: true), before)
        let ages = before.filter { $0.trait == .age }, colors = before.filter { $0.trait == .favorite }
        XCTAssertEqual(ages.filter(\.active).map(\.value), ["9"])
        XCTAssertEqual(ages.filter { !$0.active }.map(\.value), ["8"])
        XCTAssertEqual(colors.filter(\.active).map(\.value), ["зелёный"])
        XCTAssertEqual(colors.filter { !$0.active }.map(\.value), ["фиолетовый", "розовый"])
        XCTAssertEqual(try store.block().text, Fixture.lines("Любимое: цвет зелёный.", "Брат Тёма, девять лет."))
    }

    /// M18: a repeat in a later session confirms; the same session written twice changes nothing.
    func testRepeatConfirmsOncePerSession() throws {  // M18
        let store = try makeStore([try Fixture.session("s1", "2026-10-05 18:00", [
            Candidate(Fixture.cat, .name, "Мурка", turn: 3),
            Candidate(Fixture.cat, .detail, "любит спать на батарее", turn: 12)
        ])])
        let later = try Fixture.session("s3", "2026-10-07 18:00",
                                        [Candidate(Fixture.cat, .detail, "Любит спать на батарее", turn: 4)])
        XCTAssertEqual(try store.write(later), WriteReport(confirmed: 1))
        let after = try store.facts()
        let detail = try XCTUnwrap(after.first { $0.trait == .detail })
        XCTAssertEqual(after.filter { $0.trait == .detail }.count, 1)
        XCTAssertEqual([detail.value, "\(detail.confidence)", "\(detail.sessions)"],
                       ["любит спать на батарее", "0.95", "2"])
        XCTAssertEqual(detail.firstSeen, try Fixture.at("2026-10-05 18:00").timeIntervalSince1970)
        XCTAssertEqual(detail.lastSeen, try Fixture.at("2026-10-07 18:00").timeIntervalSince1970)
        XCTAssertEqual(try store.write(later), WriteReport())
        XCTAssertEqual(try store.facts(), after)
    }

    /// M19: the confidence comes from the anchor — said, found, agreed — and a later session adds 0.05 to the best one.
    func testConfidenceIsTheCodes() throws {  // M19
        let likes = { (value: String, anchor: Anchor) in Candidate(.child, .likes, value, turn: 2, anchor: anchor) }
        let store = try makeStore([try Fixture.session("s1", "2026-10-05 18:00", [
            likes("лепить", .said), likes("кататься на велосипеде", .found), likes("рисовать", .agreed)
        ])])
        XCTAssertEqual(try store.facts().map(\.confidence), [0.9, 0.8, 0.6])
        try store.write(try Fixture.session("s2", "2026-10-06 18:00", [likes("рисовать", .said)]))
        XCTAssertEqual(try store.facts().map(\.confidence), [0.9, 0.8, 0.95])
        XCTAssertFalse(Mirror(reflecting: likes("лепить", .said)).children.contains { $0.label == "confidence" })
    }

    /// M20: entities by relation and name: the unnamed grandma gets her name, «Тема» is «Тёма», two brothers, one fish.
    func testEntitiesAreFoundByRelationAndName() throws {  // M20
        let store = try makeStore(try Fixture.family())
        let facts = try store.facts()
        XCTAssertEqual([Set(facts.map(\.entity)).count, facts.count], [7, 22])
        XCTAssertEqual(facts.first { $0.value == "Тёма" }?.sessions, 2)
        let lines = try store.block().text.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.filter { $0.hasPrefix("Брат") }, ["Брат Тёма, восемь лет: строили замок из подушек.",
                                                               "Брат Миша, три года."])
        XCTAssertTrue(lines.contains("Бабушка Нина: печёт пирожки; у бабушки огород."))
        XCTAssertTrue(lines.contains("Рыбка: две рыбки в аквариуме; одна золотая."))
    }

    /// M21: «стереть всё» leaves no name in any file, and a session begun before it is refused.
    func testEraseAllLeavesNoNameAndRefusesOlderSessions() throws {  // M21
        let folder = try makeFolder(), store = try MemoryStore(directory: folder)
        for session in try Fixture.family() { try store.write(session) }
        XCTAssertGreaterThan(try Fixture.occurrences(Fixture.names, in: folder), 0)
        XCTAssertEqual(try store.eraseAll(now: try Fixture.at("2026-10-20 12:00")), EraseReport(entities: 7, facts: 22))
        XCTAssertEqual(try Fixture.occurrences(Fixture.names, in: folder), 0)
        XCTAssertEqual(try store.block().text, "")
        let sonya = [Candidate(.child, .name, "Соня", turn: 1)]
        let old = try store.write(try Fixture.session("s6", "2026-10-19 21:00", sonya))
        XCTAssertEqual(old, WriteReport(olderThanWipe: true))
        XCTAssertEqual(try store.facts().count, 0)
        XCTAssertEqual(try store.write(try Fixture.session("s7", "2026-10-21 10:00", sonya)), WriteReport(added: 1))
    }
}
