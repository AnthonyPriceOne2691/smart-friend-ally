import XCTest
@testable import Memory

/// M30, M31: her turns, Elly's lines and the model's answers — invented.
private enum Talks {
    static let foreign = [
        MemoryTurn(number: 2, her: "а у бабушки есть собака бим", elly: "Бим! А какой он?"),
        MemoryTurn(number: 3, her: "большой и лохматый", elly: "А у тебя есть хомячок?"),
        MemoryTurn(number: 4, her: "нет у меня нет хомячка", elly: "Понятно! А кто у тебя дома живёт?"),
        MemoryTurn(number: 5, her: "кошка мурка", elly: "Мурка! Давай поиграем понарошку?"),
        MemoryTurn(number: 6, her: "давай понарошку у меня есть дракон искра",
                   elly: "Дракон Искра! А что тебе снилось?"),
        MemoryTurn(number: 7, her: "мне приснилась собака", elly: "Хочешь загадку? Гав-гав, кто это?"),
        MemoryTurn(number: 8, her: "собака", elly: "Правильно!")
    ]
    static let foreignAnswer = """
        {"питомцы": [{"вид": "2: собака", "кличка": "2: Бим", "подробности": ["3: большой и лохматый"]},
                     {"вид": "4: хомяк"}, {"вид": "5: кошка", "кличка": "5: Мурка"},
                     {"вид": "6: дракон", "кличка": "6: Искра"}, {"вид": "7: собака"}, {"вид": "8: собака"}],
         "придумала": [{"что": "6: дракон", "имя": "6: Искра"}]}
        """
    static let likes = [
        MemoryTurn(number: 2, her: "я люблю танцы и рисовать", elly: "А что ты больше всего любишь кушать?"),
        MemoryTurn(number: 3, her: "макароны", elly: "А какой у тебя любимый цвет?"),
        MemoryTurn(number: 4, her: "розовый", elly: "Розовый — красивый! А что ты ещё любишь?"),
        MemoryTurn(number: 5, her: "ещё мне нравятся блины", elly: "Вкусно!")
    ]
    static let likesAnswer = """
        {"она": {"любит": ["2: танцы", "2: рисовать"],
                 "любимое": ["3: еда — макароны", "4: цвет — розовый", "5: еда — блины"]}}
        """
    static let unlike = [
        MemoryTurn(number: 2, her: "я больше не люблю танцы", elly: "Понятно! А что ты любишь теперь?"),
        MemoryTurn(number: 3, her: "лепить", elly: "Здорово!")
    ]
    static let unlikeAnswer = #"{"она": {"любит": ["2: танцы", "3: лепить"]}}"#

    static func talk(_ id: String, _ moment: String, _ turns: [MemoryTurn]) throws -> MemoryConversation {
        MemoryConversation(id: id, started: try Fixture.at(moment), turns: turns)
    }
}

final class SenseTests: StoreTestCase {
    func testForeignAndMadeUpAreNotHerPets() async throws {  // M30
        let store = try makeStore()
        let parse = try await store.remember(try Talks.talk("s1", "2026-10-05 18:00", Talks.foreign),
                                             model: ModelDouble(Talks.foreignAnswer))
        let dragon = Subject.creation(kind: "дракон", name: "Искра")
        XCTAssertEqual(parse.candidates, [
            Candidate(.person(.grandma, name: nil), .detail, "у бабушки собака Бим", turn: 2),
            Candidate(Fixture.cat, .species, "кошка", turn: 5), Candidate(Fixture.cat, .name, "Мурка", turn: 5),
            Candidate(dragon, .species, "дракон", turn: 6), Candidate(dragon, .name, "Искра", turn: 6)
        ])
        XCTAssertEqual(parse.dropped.map { "\($0.field) \($0.reason)" }, [
            "pets foreign", "pets.detail foreign", "pets.species negated", "pets.species fiction", "pets.name fiction",
            "pets.species fiction", "pets.species fiction"
        ])
        let pets = try store.facts().filter { $0.kind == .pet }
        XCTAssertEqual(pets.map(\.value), ["кошка", "Мурка"])
    }

    func testFavouriteNeedsItsWordAndUnlikeWithdraws() async throws {  // M31
        let store = try makeStore()
        let first = try await store.remember(try Talks.talk("s1", "2026-10-05 18:00", Talks.likes),
                                             model: ModelDouble(Talks.likesAnswer))
        XCTAssertEqual(first.candidates, [
            Candidate(.child, .favorite, "макароны", slot: .food, turn: 3),
            Candidate(.child, .favorite, "розовый", slot: .color, turn: 4), Candidate(.child, .likes, "блины", turn: 5),
            Candidate(.child, .likes, "танцы", turn: 2), Candidate(.child, .likes, "рисовать", turn: 2)
        ])
        let second = try await store.remember(try Talks.talk("s2", "2026-10-08 18:00", Talks.unlike),
                                              model: ModelDouble(Talks.unlikeAnswer))
        XCTAssertEqual(second.dropped, [Extraction.Drop(field: "she.likes", reason: .negated)])
        XCTAssertEqual(second.written, WriteReport(added: 1, withdrawn: 1))
        let likes = try store.facts(history: true).filter { $0.trait == .likes }
        XCTAssertEqual(Set(likes.filter(\.active).map(\.value)), ["рисовать", "блины", "лепить"])
        XCTAssertEqual(likes.filter { !$0.active }.map(\.value), ["танцы"])
    }
}
