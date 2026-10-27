@testable import AllyCore
import XCTest

/// P2–P10 on the test base of eight cards (spec, «Тестовая база Э1»): the strict rule, invariance to case, marks,
/// stress and «ё», the fail-closed self-test, a record without words. Decisions were checked by the stand's reference.
final class EncyclopediaTests: XCTestCase {
    struct Card { var id: String, questions: [String], answer: String }
    struct Broken { let name: String, cards: Data, config: Data }

    static let cards = [
        Card(id: "sky-blue", questions: ["почему небо голубое", "а почему небо синее", "почему небо не зелёное"],
             answer: "В солнечном свете спрятаны все цвета радуги. "
                + "Воздух сильнее всего разбрасывает по небу голубой цвет, как брызги во все стороны."),
        Card(id: "rainbow", questions: ["почему бывает радуга", "откуда берётся радуга", "как появляется радуга"],
             answer: "Солнечный свет проходит через капельки дождя и распадается на цвета: "
                + "красный, оранжевый и другие."),
        Card(id: "cat-whiskers", questions: ["зачем кошке усы", "зачем коту усы", "для чего кошке усы"],
             answer: "Усы у кошки очень чуткие: ими она ощущает всё вокруг, даже в темноте."),
        Card(id: "cat-purr", questions: ["почему кошка мурлычет", "почему кот мурлычет", "зачем кошка мурлычет"],
             answer: "Чаще всего кошка мурлычет, когда ей хорошо и спокойно, как будто тихонько поёт."),
        Card(id: "bear-winter",
             questions: ["почему медведь спит зимой", "зачем медведь спит всю зиму",
                         "почему медведи зимой спят в берлоге"],
             answer: "Зимой медведю нечего есть, поэтому он спит в берлоге до весны."),
        Card(id: "hedgehog-spines", questions: ["зачем ежу иголки", "почему ёжик колючий", "зачем ёжику колючки"],
             answer: "Иголки защищают ежа: при опасности он сворачивается в колючий клубок."),
        Card(id: "ice-melts", questions: ["почему лёд тает", "почему тает сосулька", "куда девается лёд весной"],
             answer: "Лёд — это замёрзшая вода. Когда ему тепло, он снова становится водой."),
        Card(id: "echo", questions: ["откуда эхо", "почему бывает эхо", "что такое эхо"],
             answer: "Звук летит, ударяется о стену или гору и возвращается назад, как отскочивший мячик.")
    ]

    static func jsonl(_ cards: [Card]) -> Data {
        let lines = cards.map { card in
            let object: [String: Any] = ["id": card.id, "questions": card.questions, "answer": card.answer]
            let bytes = try? JSONSerialization.data(withJSONObject: object, options: .sortedKeys)  // the same bytes
            return bytes.flatMap { String(bytes: $0, encoding: .utf8) } ?? ""
        }
        return Data(lines.joined(separator: "\n").utf8)
    }

    private let base = Encyclopedia(cards: jsonl(cards))

    private func decision(_ text: String, _ encyclopedia: Encyclopedia? = nil) -> [String?] {
        let record = (encyclopedia ?? base).lookup(text).record
        return [record.card, record.rules.first]
    }

    func testVariantsDecideAlike() { // P2
        XCTAssertTrue(base.healthy)
        for card in Self.cards {
            for phrasing in card.questions {
                let plain = decision(phrasing)
                XCTAssertEqual(plain, [card.id, "knowledge.hint"], phrasing)  // every phrasing finds its card
                let stressed = phrasing.split(separator: " ").map { word in
                    word.firstIndex(where: "аеиоуыэюяё".contains).map {
                        String(word[...$0]) + "\u{301}" + String(word[word.index(after: $0)...])
                    } ?? String(word)
                }.joined(separator: " ")
                let swapped = String(phrasing.map { $0 == "е" ? "ё" : $0 == "ё" ? "е" : $0 })
                for variant in [phrasing.uppercased(), phrasing + "?!…", stressed, swapped] {
                    XCTAssertEqual(decision(variant), plain, variant)
                }
            }
        }
        XCTAssertEqual(decision("ПОЧЕМУ НЕБО ГОЛУ\u{301}БОЕ?!"), ["sky-blue", "knowledge.hint"])
    }

    func testDirectHit() { // P3
        let lookup = base.lookup("почему небо голубое")
        XCTAssertEqual(lookup.hint, Self.cards[0].answer)
        XCTAssertEqual(lookup.record.card, "sky-blue")
        XCTAssertEqual(lookup.record.rules, ["knowledge.hint"])
        XCTAssertNotNil(lookup.record.dataHash.range(of: "^fnv1a:[0-9a-f]{16}$", options: .regularExpression))
    }

    func testChildWords() { // P4
        XCTAssertEqual(decision("зачем котику усы"), ["cat-whiskers", "knowledge.hint"])
        XCTAssertEqual(decision("а пачиму небо синее"), ["sky-blue", "knowledge.hint"])
        XCTAssertEqual(decision("почему мишка спит зимой"), ["bear-winter", "knowledge.hint"])
    }

    func testCloseCards() { // P5
        XCTAssertEqual(decision("зачем кошке усы"), ["cat-whiskers", "knowledge.hint"])
        XCTAssertEqual(decision("почему кошка мурлычет"), ["cat-purr", "knowledge.hint"])
    }

    func testStrictCoverage() { // P6
        for text in ["почему марс красный", "почему трава зелёная"] {
            XCTAssertNil(base.lookup(text).hint, text)
            XCTAssertEqual(decision(text), [nil, "knowledge.coverage"], text)
        }
        XCTAssertEqual(base.lookup("почему марс красный").top.first?.card, "rainbow")
        // P16: «one may be missing» — none of two words; of three and of four only on top of a whole phrasing of the
        // card: «почему лёд тает» in «…быстро», «почему медведь спит зимой» in «…бурый…»
        XCTAssertEqual(decision("почему бурый медведь"), [nil, "knowledge.coverage"])
        XCTAssertEqual(decision("почему бурый медведь спит"), [nil, "knowledge.coverage"])
        XCTAssertEqual(decision("почему лёд тает быстро"), ["ice-melts", "knowledge.hint"])
        XCTAssertEqual(decision("почему бурый медведь спит зимой"), ["bear-winter", "knowledge.hint"])
    }

    func testNoHintRules() { // P7
        XCTAssertEqual(decision("я сегодня была в зоопарке"), [nil, "knowledge.not_asked"])
        XCTAssertEqual(decision("где мой мишка"), [nil, "knowledge.personal"])
        XCTAssertEqual(base.lookup("где мой мишка").top.first?.card, "bear-winter")
        XCTAssertEqual(decision("почему умирают кошки"), [nil, "knowledge.delicate"])
    }

    func testEmptyInputAndBase() { // P8
        for text in ["", "ааа", "2 плюс 2"] { XCTAssertEqual(decision(text), [nil, "knowledge.not_asked"], text) }
        let empty = Encyclopedia(cards: Data())
        XCTAssertTrue(empty.healthy)
        XCTAssertEqual(decision("почему небо голубое", empty), [nil, "knowledge.no_match"])
    }

    func testFailClosed() throws { // P9
        let config = EncyclopediaConfig.bundled, good = Self.jsonl(Self.cards)
        func cards(_ change: (inout [Card]) -> Void) -> Data {
            var copy = Self.cards
            change(&copy)
            return Self.jsonl(copy)
        }
        let broken = [
            Broken(name: "латиница", cards: cards { $0[0].answer = "Воздух разбрасывает голубой цвет, cat." },
                   config: config),
            Broken(name: "повтор id", cards: cards { $0[1].id = "sky-blue" }, config: config),
            Broken(name: "три предложения",
                   cards: cards { $0[2].answer = "Усы чуткие. Ими она щупает. Даже в темноте." }, config: config),
            Broken(name: "длиннее 130",
                   cards: cards { $0[3].answer = String(repeating: "мурлычет ", count: 15) + "громко." },
                   config: config),
            Broken(name: "две формулировки", cards: cards { $0[4].questions.removeLast() }, config: config),
            Broken(name: "семь формулировок", cards: cards { $0[7].questions += Self.moreEcho + ["где прячется эхо"] },
                   config: config),
            Broken(name: "одна первая", cards: cards { $0[1].questions[0] = "почему небо голубое" },
                   config: config),
            Broken(name: "без весов", cards: good, config: try edited(config, "field_weights", [Double]())),
            Broken(name: "формат A", cards: good, config: try edited(config, "hint_place", "before"))
        ]
        for item in broken {
            let encyclopedia = Encyclopedia(cards: item.cards, config: item.config)
            XCTAssertFalse(encyclopedia.healthy, item.name)
            XCTAssertEqual(decision("почему небо голубое", encyclopedia), [nil, "knowledge.selftest_failed"], item.name)
        }
        let noTable = Encyclopedia(cards: good, config: try edited(config, "tokenizer", "nosuch"))
        XCTAssertFalse(noTable.healthy)
        XCTAssertEqual(decision("почему небо голубое", noTable), [nil, "knowledge.index_failed"])
        XCTAssertEqual(decision("почему небо голубое", Encyclopedia(cards: good, config: config)),
                       ["sky-blue", "knowledge.hint"])
        // P9 at three points (L90): 130 characters and six phrasings load, 142 and seven do not
        let atLimits = cards {
            $0[3].answer = String(repeating: "мурлычет ", count: 14) + "мур."
            $0[7].questions += Self.moreEcho
        }
        XCTAssertTrue(Encyclopedia(cards: atLimits, config: config).healthy)
    }

    static let moreEcho = ["откуда берётся эхо", "как получается эхо", "почему эхо отвечает"]

    func testRecordWithoutWords() throws { // P10
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let broken = Encyclopedia(cards: Data("{".utf8))
        let cases = [(base, "почему небо голубое"), (base, "почему марс красный"), (base, "где мой мишка"),
                     (broken, "почему небо голубое")]
        for (encyclopedia, text) in cases {
            let json = String(bytes: try encoder.encode(encyclopedia.lookup(text).record), encoding: .utf8) ?? ""
            XCTAssertNil(json.range(of: "[А-Яа-яЁё]", options: .regularExpression), json)
        }
        var changed = Self.cards
        changed[0].answer = changed[0].answer.replacingOccurrences(of: "радуги.", with: "радуги!")
        let again = Encyclopedia(cards: Self.jsonl(Self.cards)).lookup("").record.dataHash
        XCTAssertEqual(again, base.lookup("").record.dataHash)
        XCTAssertNotEqual(Encyclopedia(cards: Self.jsonl(changed)).lookup("").record.dataHash, again)
    }

    private func edited(_ config: Data, _ key: String, _ value: Any) throws -> Data {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: config) as? [String: Any])
        object[key] = value
        return try JSONSerialization.data(withJSONObject: object)
    }
}
