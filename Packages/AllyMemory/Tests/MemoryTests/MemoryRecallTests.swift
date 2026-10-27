import XCTest
@testable import Memory

/// M36, M39: the system turn with the block and the console's lines — invented facts, the phone's zone +03:00.
private enum Recall {
    static let persona = "Ты — Элли, сказочный аксолотлик-девочка."
    static let zone = TimeZone(secondsFromGMT: 3 * 3600) ?? .current
    static let cat = #"{"питомцы": [{"вид": "3: кошка", "кличка": "3: Мурка", "окрас": "4: рыжая"}]}"#
}

final class MemoryRecallTests: StoreTestCase {
    func testSystemTurnIsThePersonaWhenMemoryIsEmptyElseThePersonaAndTheBlock() throws {  // M36
        let store = try makeStore()
        XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: try store.block().text), Recall.persona)
        try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        let block = try store.block().text
        XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: block), Recall.persona + "\n\n" + block)
        XCTAssertTrue(block.hasPrefix(Fixture.header))
    }
}

final class MemoryConsoleTests: StoreTestCase {
    func testConsoleTellsTheMemoryStatesApart() async throws {  // M39
        let store = try makeStore()
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: Элли пока ничего не знает"])
        try store.write(try Fixture.session("s1", "2026-10-05 18:00", Fixture.first))
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов"])
        XCTAssertEqual(MemoryConsole.confirmation(facts: 14), "Стереть всё, что помнит Элли? (14 фактов)")
        XCTAssertEqual([1, 2, 5, 11, 21, 22].map { MemoryConsole.count("{n} {facts}", $0) },
                       ["1 факт", "2 факта", "5 фактов", "11 фактов", "21 факт", "22 факта"])

        for session in ["s2", "s3"] {
            try store.enqueue(session: session, started: try Fixture.at("2026-10-06 18:00"), turn: 1, her: "привет",
                              elly: "Привет!")
        }
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов", "ждёт разбора: 2"])
        _ = try await store.drain(model: ModelDouble("мусор", "мусор", "мусор", "мусор"))
        _ = try await store.drain(model: ModelDouble("мусор", "мусор", "мусор", "мусор"))
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов", "разбор не удался"])
        for (turn, her) in [(3, "у меня кошка мурка"), (4, "она рыжая")] {
            try store.enqueue(session: "s4", started: try Fixture.at("2026-10-07 18:00"), turn: turn, her: her,
                              elly: "Ага!")
        }
        _ = try await store.drain(model: ModelDouble(Recall.cat))  // a parse that worked takes the mark away
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone).count, 1)

        try store.eraseAll(now: try Fixture.at("2026-10-20 12:00"))
        XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: стёрта 20.10 в 12:00"])
        XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: try store.block().text), Recall.persona)
    }
}
