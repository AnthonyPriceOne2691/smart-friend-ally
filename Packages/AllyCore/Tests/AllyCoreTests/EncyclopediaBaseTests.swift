@testable import AllyCore
import Discipline
import XCTest

/// P12, P13 on the bundled base `encyclopedia.ru.jsonl`: the authoring rules of every card, its license and sources;
/// every phrasing finds its own card with a hint, the router passes every phrasing and answer, no delicate stem. P24:
/// every card sounds word for word through the contract of `why`, its key read as the runtime reads it.
final class EncyclopediaBaseTests: XCTestCase {
    /// A card with its authoring fields, as the base's tests read it.
    struct Card: Decodable {
        struct Source: Decodable { let title: String, url: String?, oldid: Int?, accessed: String, note: String }
        let id: String, topic: String, questions: [String], answer: String, key: String, avoid: String
        let sources: [Source], license: String
    }

    static let lines = (String(bytes: Encyclopedia.bundledCards, encoding: .utf8) ?? "").split(separator: "\n")
    static let config = try? EncyclopediaConfig.decode(EncyclopediaConfig.bundled)
    static let firstPerson: Set = ["я", "мне", "меня", "мной", "мой", "моя", "мое", "мою", "моего", "моей", "моему",
                                   "моим", "моих", "мои", "моими"]

    func testTheBaseKeepsItsGroupsAndTheAuthoringRules() throws {  // P12
        XCTAssertEqual(Self.lines.count, 100)
        let fields: Set = ["id", "topic", "questions", "answer", "key", "avoid", "sources", "license"]
        for line in Self.lines {
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
            XCTAssertEqual(Set(object.keys), fields)
        }
        let cards = try Self.lines.map { try JSONDecoder().decode(Card.self, from: Data($0.utf8)) }
        XCTAssertEqual(Dictionary(grouping: cards, by: \.topic).values.map(\.count), Array(repeating: 10, count: 10))
        for card in cards {
            XCTAssertEqual(card.license, "own", card.id)
            XCTAssertFalse(card.sources.isEmpty, card.id)
            card.sources.forEach { source(of: card.id, $0) }
            card.questions.forEach { question(of: card.id, $0) }
            answer(card)
            try key(card)
        }
    }

    func testEveryPhrasingFindsItsCardAndTheRouterPassesTheBase() throws {  // P13
        let base = Encyclopedia.bundled(), router = RouterRouting(), config = try XCTUnwrap(Self.config)
        XCTAssertTrue(base.healthy)
        XCTAssertEqual(base.count, 100)
        for card in try Self.lines.map({ try JSONDecoder().decode(Card.self, from: Data($0.utf8)) }) {
            for phrasing in card.questions {
                let record = base.lookup(phrasing).record
                XCTAssertEqual([record.card, record.rules.first], [card.id, "knowledge.hint"], phrasing)
            }
            for text in card.questions + [card.answer] {
                XCTAssertEqual(router.route(text).decision, .pass, text)
            }
            let words = EncyclopediaText.words(([card.answer] + card.questions).joined(separator: " "))
            let delicate = words.filter { word in config.delicatePrefixes.contains(where: word.hasPrefix) }
            XCTAssertEqual(delicate, [], card.id)
        }
    }

    /// Open questions of the research sets (v1, v2) that a card of the base does not answer: one word missing from the
    /// card, and no whole phrasing in her words — no hint; one word on top of a whole phrasing — the hint stays.
    func testOpenQuestionsWithoutACardGetNoHint() {  // P16
        let base = Encyclopedia.bundled()
        for text in ["почему мышка спит всю зиму", "как кит дышит под водой", "почему вода в море синяя",
                     "как космонавты дышат в космосе", "почему солнце светит так ярко", "почему иней белый и пушистый",
                     "сколько будет два плюс два"] {
            XCTAssertNil(base.lookup(text).hint, text)
        }
        let kept = ["почему лёд тает на солнышке": "ice-melts", "зачем люди ночью спят": "why-sleep",
                    "почему зимой так холодно на улице": "winter-cold"]
        for (text, card) in kept { XCTAssertEqual(base.lookup(text).record.card, card, text) }
    }

    /// The card's text in place of a reply without the essence: alone and after a first sentence at the limit of `why`
    /// (22 words), the contract keeps it word for word and fires no rule; the runtime finds the essence in it.
    func testEveryCardSoundsWordForWordAfterAFirstSentence() throws {  // P24
        let first = "Ой, Соня, как же здорово, что ты спросила об этом сегодня утром, пока мы шли вдоль реки к самой "
            + "большой зелёной горке!"
        for card in try Self.lines.map({ try JSONDecoder().decode(Card.self, from: Data($0.utf8)) }) {
            XCTAssertEqual(CardEssence(card.key)?.found(in: [card.answer]), true, card.id)
            let alone = TurnContract(mode: .why).finish(card.answer)
            XCTAssertEqual(alone.sentences.joined(separator: " "), card.answer, card.id)
            XCTAssertEqual(alone.record.rules, [], card.id)
            let after = TurnContract(mode: .why).finish(first + " " + card.answer)
            XCTAssertEqual(after.sentences, [first] + alone.sentences, card.id)
        }
    }

    /// Fail-closed: a key that does not compile or does not find the card's own answer turns the encyclopedia off.
    func testABrokenKeyTurnsTheEncyclopediaOff() throws {  // P24
        let card = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(Self.lines[0].utf8)) as? [String: Any])
        for key in ["(жир", "кит"] {
            var broken = card
            broken["key"] = key
            let line = try XCTUnwrap(String(bytes: try JSONSerialization.data(withJSONObject: broken), encoding: .utf8))
            let lines = [line] + Self.lines.dropFirst().map(String.init)
            let base = Encyclopedia(cards: Data(lines.joined(separator: "\n").utf8))
            XCTAssertFalse(base.healthy, key)
            XCTAssertEqual(base.failure, "selftest_failed", key)
            XCTAssertNil(base.lookup("почему медведь спит всю зиму").hint, key)
        }
    }

    private func source(of id: String, _ source: Card.Source) {
        XCTAssertFalse(source.title.isEmpty || source.note.isEmpty, id)
        XCTAssertTrue(source.url != nil || source.oldid != nil, id)
        XCTAssertNotNil(source.accessed.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression), id)
    }

    /// A question word, no digits and no Latin.
    private func question(of id: String, _ text: String) {
        let words = " " + EncyclopediaText.words(text).joined(separator: " ") + " "
        XCTAssertTrue(Self.config?.questionWords.contains { words.contains(" \($0) ") } == true, text)
        XCTAssertNil(text.range(of: "[0-9A-Za-z]", options: .regularExpression), text)
    }

    /// No «?», no first person, at most 14 words a sentence; the runtime rules are the loader's (P13: healthy).
    private func answer(_ card: Card) {
        XCTAssertFalse(card.answer.contains("?"), card.id)
        XCTAssertTrue(Self.firstPerson.isDisjoint(with: EncyclopediaText.words(card.answer)), card.id)
        let sentences = card.answer.replacingOccurrences(of: #"([.!…])\s+"#, with: "$1\n", options: .regularExpression)
            .split(separator: "\n")
        XCTAssertTrue(sentences.allSatisfy { EncyclopediaText.words(String($0)).count <= 14 }, card.id)
    }

    /// The judge's key: lower case without «ё», it catches its answer but not an empty text, her phrasings or `avoid`.
    private func key(_ card: Card) throws {
        let key = try NSRegularExpression(pattern: card.key, options: .caseInsensitive)
        let catches = { (text: String) -> Bool in
            let plain = text.lowercased().replacingOccurrences(of: "ё", with: "е")
            return key.firstMatch(in: plain, range: NSRange(plain.startIndex..., in: plain)) != nil
        }
        XCTAssertTrue(card.key == card.key.lowercased() && !card.key.contains("ё"), card.id)
        XCTAssertTrue(catches(card.answer), card.id)
        XCTAssertFalse(([""] + card.questions + [card.avoid]).contains(where: catches), card.id)
        XCTAssertFalse(card.avoid.isEmpty, card.id)
    }
}
