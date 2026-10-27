import XCTest
@testable import Memory

/// M32: what the reference run on E4B found, as invented cases for the model double.
private enum Found {
    static let turns = [
        MemoryTurn(number: 1, her: "мурка не собачка мурка это кошка а не собака",
                   elly: "Ой, прости! Мурка — кошка. Что ты сегодня делала?"),
        MemoryTurn(number: 2, her: "я собрала домик для мурки с окошком", elly: "Домик для Мурки! А Тёма помогал?"),
        MemoryTurn(number: 3, her: "я нарисовала динозавра для тёмы",
                   elly: "Для Тёмы! А что ты хочешь на день рождения?"),
        MemoryTurn(number: 4, her: "единорога и торт", elly: "А что ты больше всего любишь?"),
        MemoryTurn(number: 5, her: "я люблю качели больше всего", elly: "Качели — здорово! А как там Тёма?"),
        MemoryTurn(number: 6, her: "брату дают сироп", elly: "Пусть поправляется!"),
        MemoryTurn(number: 7, her: "я рисовала цветы", elly: "Красиво!"),
        MemoryTurn(number: 8, her: "давай поиграем в загадки", elly: "Давай! Что жужжит и летает?"),
        MemoryTurn(number: 9, her: "пчела", elly: "Правильно! Расскажешь что-нибудь про Мурку?"),
        MemoryTurn(number: 10, her: "а моя мурка любит спать на батарее", elly: "Тепло ей там!")
    ]
    static let answer = """
        {"она": {"любимое": ["5: больше всего", "5: качели — больше всего"], "умеет": ["7: рисовала"]},
         "близкие": [{"кто": "брат", "имя": "3: Тёма", "подробности": ["3: для Тёмы", "6: ему дают сироп"]}],
         "питомцы": [{"вид": "1: кошка", "кличка": "1: Мурка", "подробности": ["10: любит спать на батарее"]},
                     {"вид": "4: единорог"}],
         "придумала": [{"что": "2: домик", "имя": "2: Мурка", "подробности": ["2: с окошком", "2: сама собрала"]}]}
        """
}

final class QualityTests: StoreTestCase {
    func testReferenceFindingsOnE4B() async throws {  // M32
        let wrong = Subject.pet(species: "собака", name: "Мурка")
        let store = try makeStore([try Fixture.session("s0", "2026-10-04 18:00", [
            Candidate(.child, .name, "Соня", turn: 1), Candidate(wrong, .name, "Мурка", turn: 2),
            Candidate(wrong, .species, "собака", turn: 2)
        ])])
        let talk = MemoryConversation(id: "s1", started: try Fixture.at("2026-10-05 18:00"), turns: Found.turns)
        let parse = try await store.remember(talk, model: ModelDouble(Found.answer))
        let brother = Subject.person(.brother, name: "Тёма"), house = Subject.creation(kind: "домик", name: nil)
        XCTAssertEqual(parse.candidates, [
            Candidate(.child, .favorite, "качели", slot: .other, turn: 5), Candidate(brother, .name, "Тёма", turn: 3),
            Candidate(brother, .detail, "ему дают сироп", turn: 6),
            Candidate(Fixture.cat, .species, "кошка", turn: 1), Candidate(Fixture.cat, .name, "Мурка", turn: 1),
            Candidate(Fixture.cat, .detail, "любит спать на батарее", turn: 10),
            Candidate(house, .species, "домик", turn: 2), Candidate(house, .detail, "с окошком", turn: 2)
        ])
        XCTAssertEqual(parse.dropped.map { "\($0.field) \($0.reason)" },
                       ["she.favorite ungrounded", "she.can restates", "people.detail restates", "pets.species notPet",
                        "creations.name namesake", "creations.detail restates"])
        XCTAssertEqual(parse.written?.refused, ["health": 1])
        let species = try store.facts(history: true).filter { $0.kind == .pet && $0.trait == .species }
        XCTAssertEqual(species.filter(\.active).map(\.value), ["кошка"])
        XCTAssertEqual(species.filter { !$0.active }.map(\.value), ["собака"])
    }
}
