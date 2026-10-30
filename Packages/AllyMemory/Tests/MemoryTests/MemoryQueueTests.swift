import AllySQLite
import XCTest
@testable import Memory

/// A model that is cancelled on its first call: a tap, the background, the app killed during the parse.
private final class CancelledModel: MemoryModel {
    func answer(_ messages: [ExtractMessage], _ params: ExtractParams) async throws -> String {
        throw CancellationError()
    }
}

/// M34, M35: talks in the queue — her lines and Elly's, invented.
private enum Queue {
    static let cat = #"{"питомцы": [{"вид": "3: кошка", "кличка": "3: Мурка", "окрас": "4: рыжая"}]}"#
    static let turns = [(3, "у меня кошка мурка", "Мурка — красивое имя!"), (4, "она рыжая", "Рыжая — красота!")]

    static func enqueue(_ store: MemoryStore, _ session: String, at moment: String) throws {
        for (turn, her, elly) in turns {
            try store.enqueue(session: session, started: try Fixture.at(moment), turn: turn, her: her, elly: elly)
        }
    }
}

final class MemoryQueueTests: StoreTestCase {
    func testTheTalkWaitsInTheBaseUntilParsedThenItsTranscriptGoes() async throws {  // M34
        let folder = try makeFolder()
        try Queue.enqueue(try MemoryStore(directory: folder), "s1", at: "2026-10-05 18:00")
        let store = try MemoryStore(directory: folder)
        XCTAssertEqual(try store.waiting(), 1)
        let first = try await store.drain(model: ModelDouble(Queue.cat))
        XCTAssertEqual(first.map(\.status), [.parsed])
        XCTAssertEqual(try store.facts().map(\.value), ["кошка", "Мурка", "рыжая"])

        try Queue.enqueue(store, "s2", at: "2026-10-06 18:00")
        _ = try await store.drain(model: ModelDouble("мусор", "мусор"))
        XCTAssertEqual(try store.waiting(), 1)
        let second = try await store.drain(model: ModelDouble("мусор", "мусор"))
        XCTAssertEqual(second.map(\.status), [.failed("в ответе нет объекта JSON")])
        XCTAssertEqual(try store.waiting(), 0)

        try store.eraseAll(now: try Fixture.at("2026-10-07 12:00"))
        try Queue.enqueue(store, "s0", at: "2026-10-07 11:00")
        let model = ModelDouble(Queue.cat)
        let none = try await store.drain(model: model)
        XCTAssertEqual(none.count, 0)
        XCTAssertEqual([try store.waiting(), model.requests.count], [0, 0])
        XCTAssertEqual(try Fixture.occurrences(["красивое", "Рыжая — красота", "у меня кошка"], in: folder), 0)
    }

    func testCancelledParseLeavesTheTalkAsItWas() async throws {  // M35
        let store = try makeStore()
        try Queue.enqueue(store, "s1", at: "2026-10-05 18:00")
        do {
            try await store.drain(model: CancelledModel())
            XCTFail("the parse was not cancelled")
        } catch {
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        XCTAssertEqual(try store.db.rows("SELECT attempts FROM queue"), [[.int(0)]])
        XCTAssertEqual(try store.facts(history: true), [])
        let again = try await store.drain(model: ModelDouble(Queue.cat))
        XCTAssertEqual(again.map(\.status), [.parsed])
        XCTAssertEqual(try store.waiting(), 0)
    }

    func testMemoryFolderIsOutOfTheBackupOrTheMemoryIsOff() throws {  // M38
        let root = try makeFolder(), folder = MemoryFiles.prepare(under: root)
        #if canImport(Darwin)
        XCTAssertEqual(folder, .ready(root.appendingPathComponent("Memory", isDirectory: true)))
        XCTAssertNotEqual(MemoryFiles.flags, 0)
        guard case .ready(let url) = folder else { return }
        XCTAssertNoThrow(try MemoryStore(directory: url, flags: MemoryFiles.flags))
        #else
        XCTAssertNotEqual(folder, .ready(root.appendingPathComponent("Memory", isDirectory: true)))
        XCTAssertEqual(MemoryFiles.flags, 0)
        #endif
    }
}
