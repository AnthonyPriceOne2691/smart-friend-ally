@testable import AllyCore
import Discipline
import XCTest

let greeting = ["Привет!", "Это я, Элли.", "Что у тебя нового?"]
let goodbye = ["Я так наболталась, что уже засыпаю!", "Беги поиграй с мамой или папой.", "Пока-пока!"]
let misheard = "Ой, повтори, пожалуйста, я не расслышала."

/// A session over doubles: replies from a queue, a voice that records and takes `seconds` of virtual time a sentence
/// (`hold` — from the first sentence after the greeting), a router table (or a given router), an encyclopedia if given,
/// a recording sink, a state log.
struct Rig {
    let clock: TestClock, sink: RecordingSink, states: StateLog, model: ReplyQueue, voice: RecordingVoice
    let session: Session

    init(replies: [String] = [], routes: [String: Route] = [:], router: TurnRouting? = nil, limit: String? = nil,
         seconds: Double = 0, hold: Bool = false, fails: Bool = false, stamp: TraceStamp = TraceStamp(),
         knowledge: Encyclopedia? = nil, names: FamilyNames = FamilyNames(), story: StoryModel? = nil,
         clock: TestClock = TestClock(), intent: StoryIntent = .shared) {
        let sink = RecordingSink(), states = StateLog()
        let voice = RecordingVoice(hold: hold, from: greeting.count) { clock.advance(by: seconds) }
        let model = ReplyQueue(replies, fails: fails)
        let parts = SessionParts(model: model, voice: voice, sink: sink, clock: clock,
                                 router: router ?? TableRouter(table: routes), knowledge: knowledge, story: story,
                                 stamp: { stamp }, names: { names }, onState: { states.record($0) })
        (self.clock, self.sink, self.states, self.model, self.voice) = (clock, sink, states, model, voice)
        session = Session(parts, settings: SessionSettings(limitMinutes: limit), intent: intent)
    }

    /// What she heard after the greeting.
    var said: [String] { Array(voice.sentences.dropFirst(greeting.count)) }

    func hear(_ text: String, at time: Double? = nil) async {
        if let time { clock.advance(to: time) }
        await session.handle(.heard(text))
    }
}

final class SessionTests: XCTestCase {
    func testGreetingTurnAndStates() async {  // S1
        let rig = Rig(replies: ["Ух ты, в зоопарке! А кого ты там видела?"])
        await rig.session.handle(.heard("Привет"))
        XCTAssertTrue(rig.voice.sentences.isEmpty && rig.sink.records.isEmpty)
        await rig.session.handle(.wake)
        XCTAssertEqual(rig.model.calls, 0)
        await rig.session.handle(.wake)
        XCTAssertEqual(rig.sink.records.count, 1)
        await rig.hear("Я сегодня была в зоопарке", at: 5)
        XCTAssertEqual(rig.voice.sentences, greeting + ["Ух ты, в зоопарке!", "А кого ты там видела?"])
        XCTAssertEqual(rig.model.calls, 1)
        XCTAssertEqual(rig.states.log, [.greeting, .listening, .thinking, .speaking, .listening])
        XCTAssertEqual(rig.states.log.map(\.listens), [false, true, false, false, true])
    }

    func testMissesSayMisheardThenRest() async {  // S2
        let rig = Rig()
        await rig.session.handle(.wake)
        await rig.hear("")
        XCTAssertEqual(rig.said, [misheard])
        XCTAssertEqual(rig.session.state, .listening)
        await rig.session.handle(.silence)
        let rest = ["Что-то я тебя не слышу.", "Я немножко посплю.", "Нажми на меня, когда захочешь поболтать!"]
        XCTAssertEqual(rig.said, [misheard] + rest)
        XCTAssertEqual(rig.session.state, .asleep)
        XCTAssertEqual(rig.sink.records.last?.end, "rest")
        XCTAssertEqual(rig.model.calls, 0)
        let reset = Rig(replies: ["Жирафы очень высокие."])
        await reset.session.handle(.wake)
        await reset.hear("?")
        await reset.hear("Расскажи про жирафа")
        await reset.hear("?")
        XCTAssertEqual(reset.said, [misheard, "Жирафы очень высокие.", misheard])
        XCTAssertEqual(reset.session.state, .listening)
    }

    func testHerGoodbyeClosesWithoutTheModel() async {  // S3
        for word in ["Пока!", "Пока-пока, Элли!", "Ну всё, пока", "До свидания"] {
            let rig = Rig()
            await rig.session.handle(.wake)
            await rig.hear(word)
            XCTAssertEqual(rig.said, goodbye, word)
            XCTAssertEqual(rig.model.calls, 0, word)
            XCTAssertEqual(rig.session.state, .asleep, word)
            XCTAssertEqual(rig.sink.records.last?.end, "goodbye_word", word)
        }
        let rig = Rig(replies: ["Давай! Во что играем?"])
        await rig.session.handle(.wake)
        await rig.hear("Пока мама спит, давай играть")
        XCTAssertEqual(rig.model.calls, 1)
        XCTAssertEqual(rig.session.state, .listening)
    }

    func testLimitFinishesTheTurnThenTheLastTurnSaysGoodbye() async {  // S4
        let rig = Rig(replies: ["Какой красивый кот! А какого он цвета?", "Рыжий кот — это здорово! А как его зовут?"],
                      seconds: 3)
        await rig.session.handle(.wake)
        await rig.hear("Смотри, я нарисовала кота", at: 590)
        XCTAssertEqual(rig.clock.now(), 596, accuracy: 1e-9)
        XCTAssertEqual(rig.said, ["Какой красивый кот!", "А какого он цвета?"])
        XCTAssertEqual(rig.session.state, .listening)
        await rig.hear("Он рыжий", at: 605)
        XCTAssertEqual(rig.said, ["Какой красивый кот!", "А какого он цвета?", "Рыжий кот — это здорово!"] + goodbye)
        let records = Array(rig.sink.records.suffix(3))
        XCTAssertEqual(records.map(\.mode), ["talk", "goodbye", "goodbye"])
        XCTAssertEqual(records[1].rules, ["limits"])
        XCTAssertEqual(records.map(\.source), ["model", "model", "session:goodbye"])
        XCTAssertEqual(records.map(\.end), [nil, nil, "limit"])
        XCTAssertEqual(rig.session.state, .asleep)
        XCTAssertFalse(rig.session.state.listens)
        XCTAssertEqual(rig.model.calls, 2)
        let said = Rig(replies: ["Я буду скучать по тебе!"])
        await said.session.handle(.wake)
        await said.hear("Он рыжий", at: 605)
        XCTAssertEqual(said.said, ["Мне с тобой весело!", "А теперь беги поиграй с мамой или папой."])
        XCTAssertEqual(said.sink.records.last?.source, "canned:attachment")
        XCTAssertEqual(said.sink.records.last?.end, "limit")
        XCTAssertEqual(said.session.state, .asleep)
    }

    func testSilenceOrMissAfterTheLimitSaysGoodbye() async {  // S5
        for last in [SessionEvent.silence, .heard("")] {
            let rig = Rig(replies: ["Пять! Правильно."], seconds: 4)
            await rig.session.handle(.wake)
            await rig.hear("Пять", at: 595)
            XCTAssertEqual(rig.clock.now(), 603, accuracy: 1e-9)
            XCTAssertEqual(rig.session.state, .windingDown)
            XCTAssertTrue(rig.session.state.listens)
            rig.clock.advance(to: 611)
            await rig.session.handle(last)
            XCTAssertEqual(rig.said, ["Пять!", "Правильно."] + goodbye)
            XCTAssertEqual(rig.model.calls, 1)
            XCTAssertEqual(rig.sink.records.last?.end, "limit")
            XCTAssertEqual(rig.session.state, .asleep)
        }
    }

    func testLimitKeyIsReadAndRefusedValuesFallBack() async {  // S6
        XCTAssertEqual(SessionSettings(limitMinutes: "2").limit, 120)
        XCTAssertNil(SessionSettings(limitMinutes: "2").note)
        for raw in ["0", "61", "abc"] {
            XCTAssertEqual(SessionSettings(limitMinutes: raw).limit, 600, raw)
            XCTAssertEqual(SessionSettings(limitMinutes: raw).note, "лимит вне 1–60 мин — взято 10", raw)
        }
        XCTAssertEqual(SessionSettings().limit, 600)
        XCTAssertNil(SessionSettings().note)
        let rig = Rig(replies: ["Ура! Давай считать."], limit: "2", seconds: 3)
        await rig.session.handle(.wake)
        await rig.hear("Давай считать", at: 115)
        XCTAssertEqual(rig.clock.now(), 121, accuracy: 1e-9)
        XCTAssertEqual(rig.session.state, .windingDown)
    }

    /// On a tape of utterances every 30 s (7 s off the minute), at any limit the goodbye comes with the first utterance
    /// after it, and no turn after it is a talk turn.
    func testGoodbyeComesAtTheFirstBoundaryAfterTheLimit() async {  // S6
        for minutes in 1...60 {
            let rig = Rig(replies: ["Ага."], limit: "\(minutes)"), limit = Double(minutes * 60)
            await rig.session.handle(.wake)
            for step in 0..<200 where rig.session.state != .asleep {
                await rig.hear("Раз", at: Double(step * 30 + 7))
            }
            let turns = rig.sink.records.filter { $0.source == "model" }
            XCTAssertTrue(turns.dropLast().allSatisfy { $0.mode == "talk" && $0.elapsed < limit }, "\(minutes)")
            XCTAssertEqual(turns.last?.mode, "goodbye", "\(minutes)")
            XCTAssertEqual(turns.last?.elapsed ?? 0, limit + 7, accuracy: 1e-9, "\(minutes)")
            XCTAssertEqual(rig.sink.records.last?.source, "session:goodbye", "\(minutes)")
        }
    }

    func testScriptSoundsWithoutTheModel() async {  // S7
        let routes = ["Дай мне спички": Route(.script(key: "matches"), rules: ["matches.ask"], dataHash: "fnv1a:test"),
                      "Я потерялась": Route(.script(key: "lost"), rules: ["lost.self"], dataHash: "fnv1a:test")]
        let rig = Rig(replies: ["Ура, как хорошо! Мама рядом."], routes: routes)
        await rig.session.handle(.wake)
        await rig.hear("Дай мне спички")
        XCTAssertEqual(rig.said, ["Спички и зажигалку сама не бери: можно обжечься или устроить пожар.",
                                  "Зажечь свечку попроси маму или папу."])
        XCTAssertEqual(rig.model.calls, 0)
        let record = rig.sink.records.last
        XCTAssertEqual(record?.route?.kind, "script")
        XCTAssertEqual(record?.route?.key, "matches")
        XCTAssertEqual(record?.source, "script:matches")
        await rig.hear("Я потерялась", at: 700)
        let lost = ["Остановись и стой на месте, громко зови маму или папу.",
                    "Если никто не пришёл, скажи продавцу или охраннику, что ты потерялась."]
        XCTAssertEqual(Array(rig.said.suffix(2)), lost)
        XCTAssertEqual(rig.session.state, .windingDown)
        await rig.hear("Я нашла маму")
        XCTAssertEqual(Array(rig.said.suffix(5)), ["Ура, как хорошо!", "Мама рядом."] + goodbye)
        XCTAssertEqual(rig.model.calls, 1)
        XCTAssertEqual(rig.session.state, .asleep)
    }

    func testGuardKeepsTheTopicPointer() async {  // S8
        let reply = "Не бойся! Я с тобой. Хочешь, споём песенку?", heard = "Мне страшно, там гром"
        let fear = Rig(replies: [reply], routes: [heard: Route(.guard(topic: "fear"))])
        await fear.session.handle(.wake)
        await fear.hear(heard)
        XCTAssertEqual(fear.said, ["Не бойся!", "Я с тобой.", "Если страшно, скажи маме или папе."])
        XCTAssertEqual(fear.sink.records.last?.rules.contains("adult_pointer"), true)
        let pass = Rig(replies: [reply])
        await pass.session.handle(.wake)
        await pass.hear(heard)
        XCTAssertEqual(pass.said, ["Не бойся!", "Я с тобой.", "Хочешь, споём песенку?"])
    }

    func testHerUtteranceReachesTheContract() async {  // S9
        let reply = "Улица Морковная — какое смешное название! Там растёт морковка?"
        let rig = Rig(replies: [reply])
        await rig.session.handle(.wake)
        await rig.hear("Я живу на улице Морковной, дом семь")
        XCTAssertEqual(rig.said, ["Адрес и телефон говорят только маме, папе и знакомым взрослым."])
        XCTAssertEqual(rig.sink.records.last?.rules.contains("pii_echo"), true)
        XCTAssertEqual(TurnContract(mode: .talk).finish(reply).sentences.joined(separator: " "), reply)
    }

    func testStopCancelsTheTurnAndAnErrorEndsTheSession() async {  // S10
        let rig = Rig(replies: ["Привет! Как дела?"], hold: true)
        await rig.session.handle(.wake)
        let turn = Task { await rig.hear("Привет") }
        await eventually { rig.voice.sentences.count == greeting.count + 1 }
        await rig.session.handle(.stop)
        await turn.value
        XCTAssertTrue(rig.voice.stopped && rig.model.cancelled)
        XCTAssertEqual(rig.said, ["Привет!"])
        XCTAssertEqual(rig.session.state, .asleep)
        XCTAssertEqual(rig.sink.records.map(\.cancelled), [false, true])
        XCTAssertEqual(rig.sink.records.last?.end, "parent")
        let idle = Rig()
        await idle.session.handle(.wake)
        await idle.session.handle(.stop)
        XCTAssertEqual(idle.sink.records.last?.source, "session:stop")
        XCTAssertEqual(idle.sink.records.last?.end, "parent")
        XCTAssertEqual(idle.session.state, .asleep)
        let failing = Rig(fails: true)
        await failing.session.handle(.wake)
        await failing.hear("Привет")
        XCTAssertEqual(failing.said, [])
        XCTAssertEqual(failing.sink.records.last?.error, "ReplyFailure")
        XCTAssertEqual(failing.sink.records.last?.end, "error")
        XCTAssertEqual(failing.session.state, .asleep)
    }

    func testEveryPhrasePassesItsModeContract() throws {  // S12
        let phrases = SessionData.shared.phrases
        XCTAssertEqual(Set(phrases.keys), ["greeting", "misheard", "rest", "goodbye"])
        for (key, phrase) in phrases {
            let mode = try XCTUnwrap(TurnMode(rawValue: phrase.mode), key)
            let turn = TurnContract(mode: mode).finish(phrase.text)
            if phrase.text.isEmpty {
                XCTAssertEqual(turn.source, .canned("generic"), key)
                continue
            }
            XCTAssertEqual(turn.sentences.joined(separator: " "), phrase.text, key)
            XCTAssertEqual(turn.record.rules, [], key)
            XCTAssertEqual(turn.source, .model, key)
        }
        XCTAssertEqual(SessionData.shared.turn("greeting").turn.sentences, greeting)
        XCTAssertEqual(SessionData.shared.turn("misheard").turn.sentences, [misheard])
        XCTAssertEqual(SessionData.shared.turn("goodbye").mode, .goodbye)
        XCTAssertEqual(SessionData.shared.turn("rest").mode, .goodbye)
    }
}
