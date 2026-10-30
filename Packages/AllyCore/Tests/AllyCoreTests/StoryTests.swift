@testable import AllyCore
import Discipline
import XCTest

/// The model of tales as a double: each telling plays the next script (the last one again), `asked` — what it got.
final class Teller: StoryModel, @unchecked Sendable {
    private struct State {
        var scripts: [[ScriptedModel.Step]], asked: [StoryRequest] = []
        var now: ScriptedModel?
    }
    private let state: Locked<State>, clock: TurnClock
    var asked: [StoryRequest] { state { $0.asked } }
    var cancelled: Bool { state { $0.now?.cancelled ?? false } }

    init(_ scripts: [[ScriptedModel.Step]], clock: TurnClock = SystemClock()) {
        (state, self.clock) = (Locked(State(scripts: scripts)), clock)
    }

    convenience init(replies: [String]) { self.init(replies.map { [.say($0)] }) }

    func tell(_ request: StoryRequest) -> AsyncThrowingStream<String, Error> {
        let clock = clock, model = state { (s: inout State) -> ScriptedModel in
            s.asked.append(request)
            let steps = s.scripts.count > 1 ? s.scripts.removeFirst() : s.scripts.first ?? []
            s.now = ScriptedModel(steps, clock: clock)
            return s.now ?? ScriptedModel([], clock: clock)
        }
        return model.reply(to: request.utterance)
    }

    func cancel() { state { $0.now }?.cancel() }
}

/// story-mode, spec T1–T4, T6–T8, T10, T11: story turns through the real `Session`, the real router and the real
/// contract, a double in place of the model of tales. Replies of E4B from the stand, the fixed lines invented.
final class StoryTests: XCTestCase {
    private let told = ["Жил-был дракон по имени Рыжик, он очень добрый.",
                        "Однажды Рыжик увидел маленького зайчика, который испугался темноты.",
                        "Рыжик тихонько подкрался и показал зайчику, как ярко светит луна.",
                        "Зайчик перестал бояться и они стали играть вместе.",
                        "А потом они решили построить для друзей волшебный замок.", "Как ты думаешь, что было дальше?"]
    private var dragon: String { "🐉 " + told.joined(separator: " ") }
    private let asks = "Элли, расскажи мне сказку про дракона."

    private func rig(_ replies: [String], teller: Teller? = nil, talk: [String] = ["Ого! А что было потом?"],
                     limit: String? = nil) -> (Rig, Teller) {
        let teller = teller ?? Teller(replies: replies)
        return (Rig(replies: talk, router: RouterRouting(), limit: limit, story: teller), teller)
    }

    func testAStoryRunsWholeAfterItsBridge() async throws {  // T1
        let (rig, teller) = rig(["Жил-был ёжик. Он нашёл яблоко.", dragon])
        await rig.session.handle(.wake)
        await rig.hear("Расскажи сказку про ёжика!")
        await rig.hear(asks)
        XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Он нашёл яблоко.",
                                  "Ура, сказка! Слушай."] + told)
        let record = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(record.mode, "story")
        XCTAssertEqual(record.jsonLine()?.contains("\"story\":{\"bridge\":2,\"intent\":\"story\"}"), true)
        XCTAssertEqual(rig.model.calls, 0)
        XCTAssertEqual(teller.asked.map(\.utterance).last, asks)
        XCTAssertEqual(rig.model.memory.turns.last,
                       ModelMemory.Turn(heard: asks, said: (["Ура, сказка! Слушай."] + told).joined(separator: " ")))
        XCTAssertEqual(rig.states.log.suffix(3), [.thinking, .speaking, .listening])
    }

    func testMakingUpHasItsOwnBridgesAndOneQuestion() async throws {  // T2
        let idea = "Может, Мурка станет самым лучшим котом-спасателем, который помогает потерявшимся котятам?"
        let (rig, _) = rig(["🐱 " + idea + " А как ты думаешь, кем она станет?"])
        await rig.session.handle(.wake)
        await rig.hear("Давай придумаем, кем станет Мурка, когда вырастет.")
        XCTAssertEqual(rig.said, ["Ух, давай! Сейчас придумаю.", idea])
        let record = try XCTUnwrap(rig.sink.records.last)
        XCTAssertEqual(record.story?.kind, .invent)
        XCTAssertEqual(record.story?.number, 1)
        XCTAssertEqual(record.rules, ["emoji", "last_question"])
    }

    func testAStoryAsksNeitherTheEncyclopediaNorTheTalkInHerPause() async throws {  // T1
        let teller = Teller(replies: [dragon])
        let base = Encyclopedia(cards: EncyclopediaTests.jsonl(EncyclopediaTests.cards))
        let rig = Rig(router: RouterRouting(), knowledge: base, story: teller)
        await rig.session.handle(.wake)
        await rig.session.handle(.tentative("Расскажи историю, почему небо голубое"))
        XCTAssertEqual(rig.model.calls, 0)
        await rig.hear("Расскажи историю, почему небо голубое")
        XCTAssertEqual(rig.sink.records.last?.mode, "story")
        XCTAssertNil(rig.sink.records.last?.knowledge)
        XCTAssertEqual(rig.model.calls, 0)
    }

    func testTheWindowReadsAStoryAsAnyReply() async throws {  // T7
        let teller = Teller(replies: ["Жил-был ёжик. Соня пошла в лес. Ёжик уснул."])
        let rig = Rig(router: RouterRouting(), names: FamilyNames(her: "Соня"), story: teller)
        await rig.session.handle(.wake)
        await rig.hear("Расскажи сказку!")
        XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Ёжик уснул."])
    }

    func testOtherLinesGoAsToday() async throws {  // T3
        let lines = ["Мама вчера читала мне сказку про колобка.", "А ты знаешь сказку про репку?",
                     "Давай придумаем загадку!"]
        let (rig, teller) = rig([dragon])
        await rig.session.handle(.wake)
        for line in lines { await rig.hear(line) }
        XCTAssertEqual(rig.model.inputs, lines)
        XCTAssertTrue(teller.asked.isEmpty)
        XCTAssertEqual(rig.sink.records.suffix(3).map(\.mode), ["talk", "talk", "talk"])
        XCTAssertEqual(rig.sink.records.last?.jsonLine()?.contains("\"story\""), false)
    }

    func testTheRuleReadsTheStandsCasesAsTheReferenceDoes() throws {  // T3
        let url = try XCTUnwrap(Bundle.module.url(forResource: "intent_cases", withExtension: "json"))
        let cases = try JSONDecoder().decode([String: [String]].self, from: Data(contentsOf: url))
        for (want, texts) in cases {
            for text in texts { XCTAssertEqual(StoryIntent.shared.kind(of: text)?.rawValue ?? "none", want, text) }
        }
        XCTAssertEqual(StoryIntent.normalized("  Ещё объём,\n5 a-b — можешь? "), "еще обем 5 a b можеш")
    }

    func testTheRouterComesFirst() async throws {  // T4
        let lines = [("Расскажи сказку, как трогать розетку.", "script"), ("Расскажи сказку про спички.", "guard"),
                     ("Расскажи сказку про девочку, которая ушла с чужим дядей.", "pass")]
        let (rig, teller) = rig([dragon])
        await rig.session.handle(.wake)
        for (line, kind) in lines {
            await rig.hear(line)
            let record = try XCTUnwrap(rig.sink.records.last)
            XCTAssertEqual(record.route?.kind, kind, line)
            XCTAssertEqual(record.mode, "talk", line)
            XCTAssertNil(record.story, line)
        }
        XCTAssertEqual(rig.model.calls, 2)
        XCTAssertTrue(teller.asked.isEmpty)
    }

    func testNoStoryAfterTheLimit() async throws {  // T4
        let (rig, teller) = rig([dragon], talk: ["Сказку расскажу завтра."], limit: "5")
        await rig.session.handle(.wake)
        await rig.hear(asks, at: 301)
        XCTAssertTrue(teller.asked.isEmpty)
        XCTAssertEqual(rig.sink.records[1].mode, "goodbye")
        XCTAssertEqual(rig.said, ["Сказку расскажу завтра."] + goodbye)
        XCTAssertEqual(rig.session.state, .asleep)
    }

    func testAStorySoundsBeforeTheReplyEnds() async throws {  // T6
        let teller = Teller([[.say("Жил-был ёжик. "), .say("Он нашёл яблоко. "), .say("Потом"), .hang]])
        let (rig, _) = rig([], teller: teller)
        await rig.session.handle(.wake)
        let turn = Task { await rig.hear("Расскажи сказку!") }
        await eventually { rig.said.count == 3 }
        XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Он нашёл яблоко."])
        await rig.session.handle(.stop)
        await turn.value
        XCTAssertEqual(rig.model.memory.turns.last?.said, rig.said.joined(separator: " "))
        XCTAssertTrue(teller.cancelled)
    }

    func testAFullStoryStopsTheModel() async throws {  // T6
        let teller = Teller([(1...9).map { .say("Ёжик пошёл домой \($0) раз. ") } + [.say("Ещё"), .hang]])
        let (rig, _) = rig([], teller: teller)
        await rig.session.handle(.wake)
        await rig.hear("Расскажи сказку!")
        XCTAssertEqual(rig.said.count, 9)
        XCTAssertTrue(teller.cancelled)
        XCTAssertEqual(rig.sink.records.last?.rules, ["digits", "limits"])
    }

    func testTheVoiceGetsWhatTheContractKeepsOfTheWholeReply() async throws {  // T6
        let replies = [dragon, "Раз. Два! Три? Четыре… Пять. Шесть? Семь. Восемь. Девять.", "Жил-был ёжик", "🐱",
                       "Звони 89161234567! Жил-был ёжик.", "Жил-был ёжик. Я буду ждать тебя. Конец.",
                       "Жил-был ёжик. Он нашёл яблоко.\n(Ёжик смеётся! Только не лазь!)",
                       "В 2.5 года Мурка нашла 1. Кошка спала. Конец!", "Я живая девочка. Правда."]
        for reply in replies {
            let voice = RecordingVoice(), clock = SystemClock(), model = ScriptedModel.typing(reply, clock: clock)
            let outcome = try await TurnRunner(model: model, voice: voice, clock: clock, mode: .story)
                .run("Расскажи сказку!", bridge: "Слушай.")
            XCTAssertEqual(voice.sentences, ["Слушай."] + TurnContract(mode: .story).finish(reply).sentences, reply)
            XCTAssertEqual(outcome.said, voice.sentences, reply)
            XCTAssertEqual(model.memory.turns.last?.said, voice.sentences.joined(separator: " "), reply)
        }
    }

    func testTheTalkGoesOnAfterAStoryAndBridgesGoInACircle() async throws {  // T7
        let (rig, teller) = rig([dragon])
        await rig.session.handle(.wake)
        await rig.hear(asks)
        await rig.hear("Дракон полетел к маме!")
        XCTAssertEqual(rig.model.inputs, ["Дракон полетел к маме!"])
        let turns = rig.model.memory.turns
        XCTAssertEqual(turns.map(\.heard), [asks, "Дракон полетел к маме!"])
        XCTAssertEqual(turns[0].said, (["Ой, сейчас расскажу! Слушай."] + told).joined(separator: " "))
        XCTAssertEqual(rig.sink.records.last?.mode, "talk")
        XCTAssertNil(rig.sink.records.last?.story)
        for _ in 0..<3 { await rig.hear("Ещё сказку!") }
        XCTAssertEqual(teller.asked.map(\.bridge), ["Ой, сейчас расскажу! Слушай.", "Ура, сказка! Слушай.",
                                                    "Хорошо, расскажу! Слушай внимательно.",
                                                    "Ой, сейчас расскажу! Слушай."])
        XCTAssertEqual(rig.sink.records.suffix(3).compactMap(\.story?.number), [2, 3, 1])
        await rig.session.handle(.stop)
        await rig.session.handle(.wake)
        await rig.hear("Ещё сказку!")
        XCTAssertEqual(teller.asked.last?.bridge, "Ой, сейчас расскажу! Слушай.")
        XCTAssertEqual(teller.asked.last?.recent, [])
    }

    func testTheModelOfTalesReadsTheLastExchangesAsTheySounded() async throws {  // T8
        let (rig, teller) = rig(["Жил-была кошка."], talk: ["Рыжая кошка!", "Здорово!", "Ого!", "Вот это да!"])
        await rig.session.handle(.wake)
        let lines = ["Привет", "У меня есть кошка Мурка, она рыжая.", "Дай мне спички",
                     "Я живу на улице Морковной, дом семь", "Она спит на батарее.", "А ещё она любит рыбу."]
        for line in lines { await rig.hear(line) }
        await rig.hear("Расскажи сказку про мою кошку!")
        let spoken = try XCTUnwrap(Router.script(for: "matches"))
        XCTAssertEqual(teller.asked, [StoryRequest(recent: [Exchange(heard: lines[1], said: "Здорово!"),
                                                            Exchange(heard: lines[2], said: spoken),
                                                            Exchange(heard: lines[4], said: "Ого!"),
                                                            Exchange(heard: lines[5], said: "Вот это да!")],
                                                   utterance: "Расскажи сказку про мою кошку!",
                                                   bridge: "Ой, сейчас расскажу! Слушай.")])
    }

    func testTheBridgeSoundsBeforeTheModelsFirstWord() async throws {  // T10
        let clock = TestClock()
        let teller = Teller([[.wait(5), .say("Жил-был ёжик. "), .say("Он нашёл яблоко.")]], clock: clock)
        let rig = Rig(router: RouterRouting(), seconds: 2, story: teller, clock: clock)
        await rig.session.handle(.wake)
        let turn = Task { await rig.hear("Расскажи сказку!") }
        await eventually { rig.said.count == 1 && clock.sleeping == 2 }
        XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай."])
        XCTAssertEqual(rig.states.log.last, .speaking)
        clock.advanceToNext()
        await turn.value
        let stages = try XCTUnwrap(rig.sink.records.last?.stages)
        XCTAssertEqual(stages["first_sound"], 0)
        XCTAssertGreaterThanOrEqual(stages["bridge_end"] ?? 0, 2)  // the voice's tick races the double's sleep
        XCTAssertGreaterThanOrEqual(stages["story_first_sound"] ?? 0, 5)
    }

    func testNoFirstSentenceInTheTimeoutIsTheCannedReply() async throws {  // T10
        let clock = TestClock(), teller = Teller([[.hang]], clock: clock)
        let rig = Rig(router: RouterRouting(), story: teller, clock: clock)
        await rig.session.handle(.wake)
        let turn = Task { await rig.hear("Расскажи сказку!") }
        await eventually { rig.said.count == 1 && clock.sleeping == 2 }
        clock.advance(by: 10)
        await turn.value
        XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", misheard])
        XCTAssertEqual(rig.sink.records.last?.modelTimeout, true)
    }

    func testABridgeOffTheContractOrABrokenRuleTurnsTheModeOff() async throws {  // T11
        XCTAssertTrue(StoryIntent.shared.healthy)
        var bridge = StoryData.shared, rule = StoryData.shared
        bridge.bridges["story"] = ["Это будет наш секрет!"]
        rule.story.removeFirst()
        XCTAssertFalse(StoryIntent(bridge).healthy)
        XCTAssertFalse(StoryIntent(rule).healthy)
        let teller = Teller(replies: [dragon])
        let rig = Rig(replies: ["Ого!"], router: RouterRouting(), story: teller, intent: StoryIntent(bridge))
        await rig.session.handle(.wake)
        await rig.hear(asks)
        XCTAssertTrue(teller.asked.isEmpty)
        XCTAssertEqual(rig.model.inputs, [asks])
        XCTAssertEqual(rig.sink.records.last?.mode, "talk")
        let none = Rig(replies: ["Ого!"], router: RouterRouting())  // T14: no model of tales — the turn as today
        await none.session.handle(.wake)
        await none.hear(asks)
        XCTAssertEqual(none.model.inputs, [asks])
    }

    func testTheConversationPassesTheModelOfTales() async throws {  // T1
        let teller = Teller(replies: [dragon])
        let talk = Talk([.init(text: asks), .init(text: nil), .init(text: nil)], story: teller)
        await talk.conversation.wake()
        XCTAssertEqual(teller.asked.map(\.utterance), [asks])
    }
}
