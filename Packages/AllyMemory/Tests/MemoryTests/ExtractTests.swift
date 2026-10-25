import XCTest
@testable import Memory

/// A model double: answers in order and keeps every request.
final class ModelDouble: MemoryModel {
    private var answers: [String]
    private(set) var requests: [[ExtractMessage]] = [], params: [ExtractParams] = []

    init(_ answers: String...) { self.answers = answers }

    func answer(_ messages: [ExtractMessage], _ params: ExtractParams) async throws -> String {
        (requests, self.params) = (requests + [messages], self.params + [params])
        return answers.isEmpty ? "" : answers.removeFirst()
    }
}

/// M26–M28: her turns of `s1` — numbers not in a row — with Elly's answers; invented.
private enum Talk {
    static let turns = [
        MemoryTurn(number: 3, her: "привет я соня", elly: "Привет, Соня! Что ты любишь делать?"),
        MemoryTurn(number: 4, her: "рисовать и лепить из пластилина", elly: "Здорово! А кто у тебя живёт дома?"),
        MemoryTurn(number: 6, her: "кошка мурка она рыжая",
                   elly: "Рыжая Мурка! Ты, наверное, любишь качаться на качелях?"),
        MemoryTurn(number: 7, her: "да", elly: "Я тоже! А ещё многие девочки любят зоопарк."),
        MemoryTurn(number: 9, her: "пока", elly: "Пока, Соня!")
    ]
    static let name = #"{"она": {"имя": "3: Соня"}}"#
    static let anchors = """
        {"она": {"имя": "3: Соня", "любит": ["4: рисовать", "3: лепить", "7: качаться на качелях", "9: зоопарк"]},
         "близкие": [{"кто": "сестра", "имя": "4: Мила", "возраст": "4: 3"}],
         "питомцы": [{"вид": "6: кошка", "кличка": "6: Мурка", "окрас": "6: рыжая"},
                     {"вид": "4: хомяк", "кличка": "4: Хрум", "подробности": ["4: любит морковку"]}]}
        """

    static func conversation() throws -> MemoryConversation {
        MemoryConversation(id: "s1", started: try Fixture.at("2026-10-05 18:00"), turns: turns)
    }

    /// A prompt resource as it lies in the sources.
    static func resource(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../Sources/Memory/Resources/\(name)").standardized
        return try String(contentsOf: url, encoding: .utf8)
    }
}

final class ExtractTests: StoreTestCase {
    func testRequestIsBuiltFromResourcesWordForWord() async throws {  // M26
        let store = try makeStore([try Fixture.session("s0", "2026-10-04 18:00", [
            Candidate(.child, .name, "Соня", turn: 1), Candidate(.child, .age, "5", turn: 1),
            Candidate(Fixture.brother, .name, "Тёма", turn: 2), Candidate(Fixture.brother, .age, "8", turn: 2)
        ])])
        let model = ModelDouble(Talk.name, Talk.name)
        let parse = try await store.remember(try Talk.conversation(), model: model)
        let request = try XCTUnwrap(model.requests.first)
        let dialog = Talk.turns.map { "\($0.number). Девочка: \($0.her)\n   Элли: \($0.elly ?? "")" }
        XCTAssertEqual(request.map(\.role), [.system, .user])
        XCTAssertEqual(request[0].text, try Talk.resource("extract.system.ru.md"))
        XCTAssertEqual(request[1].text, try Talk.resource("extract.user.ru.md")
            .replacingOccurrences(of: "{known}", with: "Соня, пять лет; брат Тёма, восемь лет.")
            .replacingOccurrences(of: "{dialog}", with: dialog.joined(separator: "\n")))
        XCTAssertTrue(request[1].text.contains("1. Девочка: привет я мила"))
        XCTAssertEqual(parse.requestHash, ExtractPrompt.fnv1a(request[0].text + "\n" + request[1].text))
        XCTAssertEqual(parse.params, ExtractParams(temperature: 0.2, seed: 42, grammar: "json"))
        XCTAssertEqual(model.params, [parse.params])

        let again = try await store.remember(try Talk.conversation(), model: model)
        XCTAssertEqual(again.requestHash, parse.requestHash)
        let cat = [Candidate(Fixture.cat, .name, "Мурка", turn: 1)]
        try store.write(try Fixture.session("s2", "2026-10-06 18:00", cat))
        let other = try await store.remember(try Talk.conversation(), model: ModelDouble(Talk.name))
        XCTAssertNotEqual(other.requestHash, parse.requestHash)
    }

    func testGarbageGetsOneRetryThenTheSessionIsNotParsed() async throws {  // M27
        let first = try await makeStore().remember(try Talk.conversation(), model: ModelDouble(Talk.name))
        XCTAssertEqual([first.status], [.parsed])
        XCTAssertEqual([first.attempts, first.written?.added], [1, 1])

        let retried = ModelDouble("Сейчас подумаю…", Talk.name)
        let second = try await makeStore().remember(try Talk.conversation(), model: retried)
        XCTAssertEqual([second.attempts, second.written?.added], [2, 1])
        let retry = try XCTUnwrap(retried.requests.last), again = retry.dropFirst(2).map(\.text)
        XCTAssertEqual(retry.map(\.role), [.system, .user, .assistant, .user])
        XCTAssertEqual(again.first, "Сейчас подумаю…")
        XCTAssertTrue(again.last?.contains("Ответь ещё раз") == true, again.joined())
        XCTAssertTrue(again.last?.contains("в ответе нет объекта JSON") == true, again.joined())

        let store = try makeStore(), failing = ModelDouble("Сейчас подумаю…", #"{"ответ": 1}"#, Talk.name)
        let failed = try await store.remember(try Talk.conversation(), model: failing)
        XCTAssertEqual(failed.status, .failed("ответ не по шаблону"))
        XCTAssertEqual([failed.attempts, failing.requests.count], [2, 2])
        XCTAssertEqual(try store.facts(history: true), [])
    }

    func testAnchorIsInHerWords() async throws {  // M28
        let store = try makeStore()
        let parse = try await store.remember(try Talk.conversation(), model: ModelDouble(Talk.anchors))
        XCTAssertEqual(parse.candidates, [
            Candidate(.child, .name, "Соня", turn: 3), Candidate(.child, .likes, "рисовать", turn: 4),
            Candidate(.child, .likes, "лепить", turn: 4, anchor: .found),
            Candidate(.child, .likes, "качаться на качелях", turn: 7, anchor: .agreed),
            Candidate(Fixture.cat, .species, "кошка", turn: 6), Candidate(Fixture.cat, .name, "Мурка", turn: 6),
            Candidate(Fixture.cat, .color, "рыжая", turn: 6)
        ])
        XCTAssertEqual(parse.dropped.map(\.field),
                       ["she.likes", "people.name", "people.age", "pets.species", "pets.name", "pets.detail"])
        XCTAssertEqual(Set(parse.dropped.map(\.reason)), [.ungrounded])
        XCTAssertEqual(try store.facts().map(\.confidence), [0.9, 0.9, 0.8, 0.6, 0.9, 0.9, 0.9])
    }
}
