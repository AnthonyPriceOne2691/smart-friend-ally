@testable import AllyCore
import Discipline
import XCTest

/// card-fallback through the real `Session`, the real router and the bundled base of 100 cards: a hinted turn whose
/// kept sentences miss the card's essence sounds the card's text after the sentence that already sounded; a reply with
/// the essence, a canned reply and a turn without a hint sound as before.
final class CardFallbackTests: XCTestCase {
    private static let base = Encyclopedia.bundled()
    private let boat = ["Вода всё время выталкивает вверх то, что в неё попало.",
                        "Корабль широкий и полон воздуха, и вода держит его, как мячик."]
    private let reAsk = "Ой, какой ты умненький! А как ты думаешь, почему кораблик не тонет?"

    private func rig(_ reply: String) -> Rig { Rig(replies: [reply], router: RouterRouting(), knowledge: Self.base) }

    func testAReplyWithoutTheEssenceSoundsTheCardAfterItsFirstSentence() async throws {  // P21
        let rig = rig(reAsk)
        await rig.session.handle(.wake)
        await rig.hear("почему кораблик не тонет")
        XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"] + boat)
        let record = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual([record.mode, record.source], ["why", "model"])
        XCTAssertEqual(record.knowledge?.card, "boats-float")
        XCTAssertEqual(record.knowledge?.rules, ["knowledge.hint", "knowledge.fallback"])
        XCTAssertEqual(rig.model.memory.turns.last?.said, (["Ой, какой ты умненький!"] + boat).joined(separator: " "))
    }

    func testTheEssenceCountsOnlyInWhatTheContractKept() async {  // P21
        // A second question breaks the limits of `why`: the sentence with the essence never sounds.
        let rig = rig("Ой, ты знаешь, почему так? Думаешь, это волшебство? Вода выталкивает кораблик вверх.")
        await rig.session.handle(.wake)
        await rig.hear("почему кораблик не тонет")
        XCTAssertEqual(rig.said, ["Ой, ты знаешь, почему так?"] + boat)
    }

    func testACannedReplyStaysAndNoCardSounds() async {  // P21
        let rig = rig("")
        await rig.session.handle(.wake)
        await rig.hear("почему кораблик не тонет")
        XCTAssertEqual(rig.said, [misheard])
        XCTAssertEqual(rig.sink.records.last?.source, "canned:generic")
        XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
    }

    func testOnTheLastTurnTheCardSoundsBeforeTheGoodbye() async {  // P21
        let rig = rig(reAsk)
        await rig.session.handle(.wake)
        await rig.hear("почему кораблик не тонет", at: 605)
        XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"] + boat + goodbye)
        let records = Array(rig.sink.records.suffix(2))
        XCTAssertEqual(records.map(\.mode), ["goodbye", "goodbye"])
        XCTAssertEqual(records.first?.knowledge?.rules, ["knowledge.hint", "knowledge.fallback"])
        XCTAssertEqual(records.map(\.end), [nil, "limit"])
    }

    func testWhenNothingHasSoundedOnlyTheCardSounds() async throws {  // P21
        let lookup = Self.base.lookup("почему кораблик не тонет"), voice = RecordingVoice()
        let card = HintCard(text: try XCTUnwrap(lookup.hint), key: try XCTUnwrap(lookup.key))
        let runner = TurnRunner(model: ReplyQueue(["А как ты думаешь, почему кораблик не тонет?"]), voice: voice,
                                mode: .why)
        let outcome = try await runner.run("почему кораблик не тонет", card: card)
        XCTAssertEqual(voice.sentences, boat)
        XCTAssertEqual(outcome.turn.sentences, boat)
        XCTAssertTrue(outcome.cardSaid)
    }

    func testAReplyWithTheEssenceSoundsAsItIs() async {  // P22
        let reply = ["Ой, это интересно!",
                     "Вода толкает кораблик снизу вверх, а внутри у него много воздуха, поэтому он держится на воде."]
        let rig = rig(reply.joined(separator: " "))
        await rig.session.handle(.wake)
        await rig.hear("почему кораблик не тонет")
        XCTAssertEqual(rig.said, reply)
        XCTAssertEqual(rig.sink.records.last?.mode, "why")
        XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
    }

    func testTheEssenceIsReadWithYoAsYe() async {  // P22
        // The key of `ice-melts` holds «тепл»: «тёплой» carries the essence only with «ё» read as «е».
        let reply = ["Ой, интересно!", "В тёплой комнате лёд снова становится водой."]
        let rig = rig(reply.joined(separator: " "))
        await rig.session.handle(.wake)
        await rig.hear("почему лёд тает")
        XCTAssertEqual(rig.said, reply)
        XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
    }

    func testWithoutAHintTheReplySoundsAsBefore() async throws {  // P23
        let rig = rig("Ой, а ты как думаешь, почему?")
        await rig.session.handle(.wake)
        await rig.hear("почему бурый медведь спит")
        XCTAssertEqual(rig.model.inputs, ["почему бурый медведь спит"])
        XCTAssertEqual(rig.said, ["Ой, а ты как думаешь, почему?"])
        let record = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(record.mode, "talk")
        XCTAssertEqual(record.knowledge?.rules, ["knowledge.coverage"])
        XCTAssertNil(record.knowledge?.card)
    }

    func testACardWithoutAKeyNeverSoundsAsText() async {  // P24
        let keyless = Encyclopedia(cards: EncyclopediaTests.jsonl(EncyclopediaTests.cards))
        let rig = Rig(replies: ["Ой, какой ты умненький! А как ты думаешь, почему?"], router: RouterRouting(),
                      knowledge: keyless)
        await rig.session.handle(.wake)
        await rig.hear("почему небо голубое")
        XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"])
        XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
    }
}
