import XCTest
@testable import Memory

/// M41: the parent forgets one fact or one entity — invented facts, the parent's moment at +03:00.
private enum Forget {
    static let cat = #"{"питомцы": [{"вид": "3: кошка", "кличка": "3: Мурка", "окрас": "4: рыжая"}]}"#
    static let brother = #"{"близкие": [{"кто": "брат", "имя": "2: Тёма", "возраст": null, "подробности": []}]}"#
    static func color(_ store: MemoryStore) throws -> StoredFact? { try store.facts().first { $0.trait == .color } }
    static func color(_ id: String, _ moment: String, _ value: String) throws -> MemorySession {
        try Fixture.session(id, moment, [Candidate(Fixture.cat, .color, value, turn: 2)])
    }
}

final class MemoryForgetTests: StoreTestCase {
    func testAForgottenFactLeavesNoByteAndAnOlderSessionDoesNotBringItBack() async throws {  // M41
        let folder = try makeFolder(), store = try MemoryStore(directory: folder)
        try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        try store.write(try Forget.color("s2", "2026-10-06 18:00", "серая"))
        let color = try XCTUnwrap(try Forget.color(store))
        let item = try XCTUnwrap(try store.remembered().flatMap(\.items).first { $0.fact == color.id })
        XCTAssertEqual(MemoryConsole.forgetting(item), "Забыть «серая»?")
        XCTAssertEqual(try store.forget(fact: color.id, now: try Fixture.at("2026-10-20 12:00")), 2)
        XCTAssertEqual(try Fixture.occurrences(["рыжая", "серая"], in: folder), 0)
        XCTAssertEqual(try store.block().text.split(separator: "\n").filter { $0.hasPrefix("Кошка") },
                       ["Кошка Мурка: любит спать на батарее."])

        let again = try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        XCTAssertEqual(again.refused, ["forgotten": 1])  // the same session parsed again
        for (turn, her) in [(3, "у меня кошка мурка"), (4, "она рыжая")] {  // a talk begun before the forgetting
            try store.enqueue(session: "s3", started: try Fixture.at("2026-10-19 18:00"), turn: turn, her: her,
                              elly: "Ага!")
        }
        let parsed = try await store.drain(model: ModelDouble(Forget.cat))
        XCTAssertEqual(parsed.first?.written?.refused, ["forgotten": 1])
        XCTAssertNil(try Forget.color(store))
        XCTAssertEqual(try Fixture.occurrences(["рыжая", "серая"], in: folder), 0)

        try store.write(try Forget.color("s4", "2026-10-21 18:00", "рыжая"))
        XCTAssertEqual(try Forget.color(store)?.value, "рыжая")  // told after the forgetting: known again
    }

    func testAForgottenEntityLeavesNoByteAndAnOlderSessionDoesNotBringItBack() async throws {  // M41
        let folder = try makeFolder(), store = try MemoryStore(directory: folder)
        try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        let brother = try XCTUnwrap(try store.remembered().first { $0.title == "Брат Тёма" })
        XCTAssertEqual(brother.items.map(\.text), ["Тёма", "восемь лет", "строили замок из подушек"])
        XCTAssertEqual(MemoryConsole.forgetting(brother), "Забыть всё про «Брат Тёма»? (3 факта)")
        XCTAssertEqual(try store.forget(entity: brother.entity, now: try Fixture.at("2026-10-20 12:00")), 3)
        XCTAssertEqual(try Fixture.occurrences(["Тёма", "строили замок из подушек"], in: folder), 0)
        XCTAssertEqual(try store.facts().count, 11)
        XCTAssertFalse(try store.block().text.contains("Брат"))

        let again = try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        XCTAssertEqual(again.refused, ["forgotten": 3])
        try store.enqueue(session: "s2", started: try Fixture.at("2026-10-19 18:00"), turn: 2, her: "мой брат тёма",
                          elly: "Здорово!")
        _ = try await store.drain(model: ModelDouble(Forget.brother))
        XCTAssertEqual(try store.facts().count, 11)
        XCTAssertEqual(try Fixture.occurrences(["Тёма"], in: folder), 0)
    }
}
