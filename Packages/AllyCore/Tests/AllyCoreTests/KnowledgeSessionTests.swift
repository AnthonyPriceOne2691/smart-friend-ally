@testable import AllyCore
import Discipline
import XCTest

/// P17 through the real `Session` and the real router, on the eight cards of Э1's test base: the encyclopedia is asked
/// only after a «pass», its hint reaches the model on a line before her words and turns the turn to `why`; without a
/// hint the model gets her words byte for byte.
final class KnowledgeSessionTests: XCTestCase {
    private let frame = "Подсказка к вопросу девочки — верный ответ: "
    private let reply = "Воздух разбрасывает голубой цвет во все стороны."
    private var base: Encyclopedia { Encyclopedia(cards: EncyclopediaTests.jsonl(EncyclopediaTests.cards)) }
    private var skyPrompt: String { frame + EncyclopediaTests.cards[0].answer + "\nпочему небо голубое" }

    func testTheHintGoesToTheModelOnlyAfterThePass() async throws {  // P17
        let rig = Rig(replies: [reply], router: RouterRouting(), knowledge: base)
        await rig.session.handle(.wake)
        await rig.hear("почему небо голубое")
        XCTAssertEqual(rig.model.inputs, [skyPrompt])
        let hinted = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(hinted.mode, "why")
        XCTAssertEqual(hinted.knowledge?.card, "sky-blue")
        XCTAssertEqual(hinted.knowledge?.rules, ["knowledge.hint"])
        XCTAssertEqual(hinted.jsonLine()?.contains("\"knowledge\":{\"card\":\"sky-blue\""), true)
        for text in ["Дай мне спички", "Я живу на улице Морковной, дом семь"] {
            await rig.hear(text)
            XCTAssertNil(rig.sink.records.last?.knowledge, text)  // a script, a forgotten one: no lookup
        }
        XCTAssertEqual(rig.model.calls, 1)
        await rig.hear("где мой мишка")
        XCTAssertEqual(rig.model.inputs.last, "где мой мишка")
        let personal = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(personal.mode, "talk")
        XCTAssertEqual(personal.knowledge?.rules, ["knowledge.personal"])
        XCTAssertNil(personal.knowledge?.card)
    }

    func testWithoutTheEncyclopediaTheTurnIsAsBefore() async throws {  // P17
        let rig = Rig(replies: [reply], router: RouterRouting())
        await rig.session.handle(.wake)
        await rig.hear("почему небо голубое")
        XCTAssertEqual(rig.model.inputs, ["почему небо голубое"])
        let record = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(record.mode, "talk")
        XCTAssertNil(record.knowledge)
        XCTAssertEqual(record.jsonLine()?.contains("knowledge"), false)
    }

    func testTheAnswerBegunInHerPauseCarriesTheSameHint() async {  // P17
        let rig = Rig(replies: [reply], router: RouterRouting(), knowledge: base)
        await rig.session.handle(.wake)
        await rig.session.handle(.tentative("почему небо голубое"))
        await rig.hear("почему небо голубое")
        XCTAssertEqual(rig.model.inputs, [skyPrompt])  // one call: the turn took the answer begun in her pause
        XCTAssertEqual(rig.sink.records.last?.stages["spec_reused"], 1)
    }

    func testTheConversationGivesItsSessionTheEncyclopedia() async {  // P17
        let talk = Talk([.init(text: "почему небо голубое"), .init(text: nil), .init(text: nil)], replies: [reply],
                        knowledge: base)
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.inputs, [skyPrompt])
        XCTAssertEqual(talk.sink.records.compactMap(\.knowledge?.card), ["sky-blue"])
    }

    func testTheWarmUpLineNamesTheCardsOrTheRefusal() throws {  // P20
        XCTAssertEqual(base.line(searchP95: 0.42), "энциклопедия: карточек — 8, поиск p95 0.4 мс")
        let broken = Encyclopedia(cards: Data("{".utf8))
        XCTAssertEqual(broken.line(searchP95: 0), "энциклопедия: выключена (selftest_failed)")
        XCTAssertGreaterThan(base.searchP95(), 0)
    }

    func testFormatBPutsTheHintAfterHerWords() throws {  // P18
        var config = try XCTUnwrap(JSONSerialization.jsonObject(with: EncyclopediaConfig.bundled) as? [String: Any])
        config["hint_place"] = "after"
        let after = Encyclopedia(cards: EncyclopediaTests.jsonl(EncyclopediaTests.cards),
                                 config: try JSONSerialization.data(withJSONObject: config))
        let hint = EncyclopediaTests.cards[0].answer
        XCTAssertEqual(after.prompt("почему небо голубое", hint: hint), "почему небо голубое\n" + frame + hint)
        XCTAssertEqual(after.prompt("где мой мишка", hint: nil), "где мой мишка")
    }
}
