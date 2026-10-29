import XCTest
@testable import Discipline

/// story-mode: the contract's `story` mode — its limits, the order of its choice, and the sentences it lets out one by
/// one, which must be what it keeps of the whole reply (spec T5, T6, T11).
final class StoryContractTests: XCTestCase {
    private let hedgehog = ["Жил-был ёжик.", "Он жил в лесу.", "Он любил яблоки.", "Однажды он пошёл гулять.",
                            "Он нашёл яблоко.", "Он отнёс его маме.", "Мама обрадовалась.", "Они ели яблоко вместе.",
                            "Потом они легли спать.", "Утром снова светило солнце."]

    /// Stories of E4B with the story words of the stand (bake-off 2, seed 42), as the model wrote them.
    private let stories = [
        "🐉 Жил-был дракон по имени Рыжик, он очень добрый. Однажды Рыжик увидел маленького зайчика, который испугался "
            + "темноты. Рыжик тихонько подкрался и показал зайчику, как ярко светит луна. Зайчик перестал бояться и "
            + "они стали играть вместе. А потом они решили построить для друзей волшебный замок. Как ты думаешь, "
            + "что было дальше?",
        "Жил-был маленький зайчонок по имени Пушистик, и он очень любил собирать самые сочные красные яблоки. Однажды "
            + "Пушистик нашел целую полянку, где яблоки росли, как маленькие шары. Вечером они решили построить "
            + "себе домик из веточек. Как тебе такой конец? Что Пушистик построил дальше?",
        "🌸\n\nСолнышко встало, светит ярко,\nМама милая, как нежно так.\nТы улыбайся, смеёшься часто,\n"
            + "Ты самая лучшая, просто счастье!\n\nА что ещё можно добавить в наш стишок, моя радость?",
        "🐱✨ Представь, что Мурка, наша пушистая кошечка, вдруг увидела блестящие крылышки, как у бабочки. Она их "
            + "пошевелила, и *вжух* — взлетела прямо к самым высоким облакам. А там, наверху, её ждал целый пирог с "
            + "рыбкой! Что ты придумаешь дальше, моя солнышко?"
    ]

    func testEightSentencesSoundAndTheNinthEndsTheStory() {  // T5
        XCTAssertEqual(say(hedgehog.prefix(7).joined(separator: " "), .story).sentences, Array(hedgehog.prefix(7)))
        XCTAssertEqual(say(hedgehog.prefix(8).joined(separator: " "), .story).sentences, Array(hedgehog.prefix(8)))
        let ten = say(hedgehog.joined(separator: " "), .story)
        XCTAssertEqual(ten.sentences, Array(hedgehog.prefix(8)))
        XCTAssertEqual(ten.record.rules, ["limits"])
    }

    func testWordsOfTheStoryAndOfASentence() {  // T5
        let twenty = "Ёжик" + String(repeating: " ёжик", count: 19) + "."
        XCTAssertEqual(say(Array(repeating: twenty, count: 5).joined(separator: " "), .story).sentences.count, 5)
        let over = say(Array(repeating: twenty, count: 5).joined(separator: " ") + " Ура!", .story)
        XCTAssertEqual(over.sentences.count, 5)
        XCTAssertEqual(over.record.rules, ["limits"])
        XCTAssertEqual(say("Жил-был ёжик. " + twenty, .story).sentences, ["Жил-был ёжик.", twenty])
        let long = say("Жил-был ёжик. " + twenty.dropLast() + " ёжик.", .story)
        XCTAssertEqual(long.sentences, ["Жил-был ёжик."])
        XCTAssertEqual(long.record.rules, ["limits"])
        let split = "Ёжик долго шёл по лесу и нёс в корзинке яблоки, а потом он сел под большим деревом и съел самое "
            + "красное яблоко."
        let halves = ["Ёжик долго шёл по лесу и нёс в корзинке яблоки.",
                      "А потом он сел под большим деревом и съел самое красное яблоко."]
        XCTAssertEqual(say(split, .story).sentences, halves)
    }

    func testTheFirstQuestionStaysAndTheStoryGoesOn() {  // T5
        let turn = say("Жил-был ёжик. Что же он нашёл в лесу? Большое яблоко! Как ты думаешь, кому он его отнёс? "
                       + "Конечно, маме!", .story)
        XCTAssertEqual(spoken(turn), "Жил-был ёжик. Что же он нашёл в лесу? Большое яблоко! Конечно, маме!")
        XCTAssertEqual(turn.record.rules, ["last_question"])
        XCTAssertEqual(spoken(say(stories[1], .story)).hasSuffix("Как тебе такой конец?"), true)
        let after = say("Жил-был ёжик. Что он нашёл? Яблоко! Кому его отнести? Поэтому он пошёл к маме.", .story)
        XCTAssertEqual(spoken(after), "Жил-был ёжик. Что он нашёл? Яблоко! Он пошёл к маме.")
    }

    func testABrokenRuleEndsTheStoryBeforeItself() {  // T5
        let cut = say("Жил-был ёжик. Он жил в лесу. Ёжик сказал: я буду ждать тебя всегда. Потом он уснул.", .story)
        XCTAssertEqual(cut.sentences, ["Жил-был ёжик.", "Он жил в лесу."])
        XCTAssertTrue(cut.record.rules.contains("attachment"))
        let first = say("Я буду ждать тебя всегда. Жил-был ёжик.", .story)
        XCTAssertEqual(first.source, .canned("attachment"))
        XCTAssertEqual(spoken(first), contractData.canned["attachment"])
    }

    func testAReferralComesBackOnlyAfterTheStory() {  // T5
        let skipped = say("Жил-был ёжик. Что он нашёл? Большое яблоко. Покажи маме рисунок с ёжиком, ладно?", .story)
        XCTAssertEqual(skipped.sentences, ["Жил-был ёжик.", "Что он нашёл?", "Большое яблоко.",
                                           contractData.pointerScript])
        XCTAssertEqual(skipped.record.rules, ["last_question", "action_referral"])
        let full = say(hedgehog.prefix(8).joined(separator: " ") + " Покажи маме рисунок с ёжиком, ладно?", .story)
        XCTAssertEqual(full.sentences, Array(hedgehog.prefix(8)))
    }

    func testWhatSoundedStaysWhenTheReplyChanges() {  // T6
        let contract = TurnContract(mode: .story)
        XCTAssertEqual(contract.first("Жил-был ёжик."), "Жил-был ёжик.")
        XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в лесу. "), ["Он жил в лесу."])
        XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в норке. Конец. "), [])
        XCTAssertTrue(contract.stopped)
        XCTAssertEqual(contract.finish("Жил-был ёжик. Он жил в норке. Конец.").sentences,
                       ["Жил-был ёжик.", "Он жил в лесу."])
    }

    func testTheStandStoriesPassWhole() {  // T5
        let told = stories.map { say($0, .story) }
        XCTAssertEqual(told.map(\.sentences.count), [6, 4, 3, 4])
        XCTAssertEqual(told.map(\.source), Array(repeating: .model, count: stories.count))
        XCTAssertEqual(told.map { $0.record.rules.contains("limits") }, Array(repeating: false, count: stories.count))
    }

    /// Every reply of the fixtures and probes, cut as the voice cuts it, through `first` and `more`: what they let out
    /// is the beginning of `finish`, and `finish` is what a contract that never streamed keeps.
    func testSentencesLetOutOneByOneAreWhatTheWholeReplyKeeps() throws {  // T6
        let replies = try Fixture.pairs().map(\.input) + (turnViolators + turnCleans).map(\.reply) + stories
            + [hedgehog.joined(separator: " ")]
        var streamed = 0
        for reply in replies {
            let contract = TurnContract(mode: .story), cuts = Self.cuts(reply)
            let whole = say(reply, .story)
            guard let head = cuts.first.flatMap(contract.first) else {
                XCTAssertEqual(contract.finish(reply).sentences, whole.sentences, reply)
                continue
            }
            var said = [head]
            for prefix in cuts.dropFirst() { said += contract.more(prefix) }
            let final = contract.finish(reply)
            XCTAssertTrue(final.sentences.starts(with: said), "\(said) — \(final.sentences)")
            XCTAssertEqual(final.sentences, whole.sentences, reply)
            XCTAssertEqual(final.source, whole.source, reply)
            streamed += said.count > 1 ? 1 : 0
        }
        XCTAssertGreaterThan(streamed, 20)
    }

    func testMoreLetsOutNothingOutsideAStory() {  // T6
        let contract = TurnContract(mode: .talk)
        XCTAssertEqual(contract.first("Жил-был ёжик."), "Жил-был ёжик.")
        XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в лесу. "), [])
        let story = TurnContract(mode: .story)
        XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. "), [])
        XCTAssertEqual(story.first("Жил-был ёжик."), "Жил-был ёжик.")
        XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. "), ["Он жил в лесу."])
        XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. Ёжик сказал: я буду ждать тебя. "), [])
        XCTAssertTrue(story.stopped)
        XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. Ёжик сказал: я буду ждать тебя. Он уснул. "), [])
        let long = TurnContract(mode: .story)
        XCTAssertEqual(long.first(hedgehog[0]), hedgehog[0])
        let told = (2...9).flatMap { long.more(hedgehog.prefix($0).joined(separator: " ") + " ") }
        XCTAssertEqual(told, Array(hedgehog[1..<8]))
        XCTAssertTrue(long.stopped)
    }

    func testStoryProbesAreCaughtAtLoad() {  // T11
        let probes = contractData.selftest.filter { $0.mode == "story" }
        XCTAssertEqual(Set(probes.map(\.rule)), ["limits", "last_question", "attachment"])
        XCTAssertTrue(Contract.shared.healthy)
        var broken = ContractData.decode(ContractData.bytes)
        broken.modes["story"] = ContractData.Limits(maxSentences: 20, maxQuestions: 2, maxWords: 500,
                                                    maxSentenceWords: 50, canned: "generic")
        XCTAssertFalse(Contract(broken, hash: "broken").healthy)
    }

    /// The prefixes the voice gets: the reply up to each end of a sentence that the next one follows — end marks,
    /// whitespace and a letter, not after a digit (`SentenceStream` of AllyCore), and the first sentence alone.
    static func cuts(_ reply: String) -> [String] {
        let chars = Array(reply)
        var out: [String] = [], index = 0
        while index < chars.count {
            guard SentenceMarks.all.contains(chars[index]) else {
                index += 1
                continue
            }
            var end = index, next = index + 1
            while next < chars.count, SentenceMarks.all.contains(chars[next]) { (end, next) = (next, next + 1) }
            while next < chars.count, chars[next].isWhitespace { next += 1 }
            if next > end + 1, next < chars.count, chars[next].isLetter, index == 0 || !chars[index - 1].isNumber {
                out.append(String(chars[...end]))
            }
            index = end + 1
        }
        guard let first = out.first else { return [] }
        return [first.trimmingCharacters(in: .whitespacesAndNewlines)] + out.dropFirst().map { $0 + " " }
    }
}

private enum SentenceMarks {
    static let all: Set<Character> = [".", "!", "?", "…"]
}
