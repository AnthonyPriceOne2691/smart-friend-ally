@testable import AllyCore
import XCTest

/// A conversation for the answer begun in her pause: the speculation's model double, a voice that notes when each
/// sentence sounds (and lets the model finish while it speaks), the states with their times, a sink with words.
struct SpecTalk {
    let clock = TestClock(), sink = WordSink(), model: SpecModel, voice: RecordingVoice, ear: ScriptedEar
    let conversation: Conversation, sounded: Locked<[(String, Double)]>, phases: Locked<[(SessionState, Double)]>

    init(plans: [SpecModel.Plan], router: TurnRouting = PassThroughRouting(),
         answers: (SpecModel) -> [ScriptedEar.Answer]) {
        let clock = clock, model = SpecModel(plans, clock: clock)
        let sounded = Locked([(String, Double)]()), phases = Locked([(SessionState, Double)]())
        let box = Locked<RecordingVoice?>(nil)
        let voice = RecordingVoice {
            let said = box { $0 }?.sentences.last ?? ""
            sounded { $0.append((said, clock.now())) }
            model.finishLive()
            clock.advance(by: 0.5)
        }
        box { $0 = voice }
        let ear = ScriptedEar(answers(model), clock: clock, voice: voice)
        let parts = SessionParts(model: model, voice: voice, sink: sink, clock: clock, router: router,
                                 onState: { state in phases { $0.append((state, clock.now())) } })
        conversation = Conversation(parts, listener: ear)
        ear.watch(conversation)
        (self.model, self.voice, self.ear, self.sounded, self.phases) = (model, voice, ear, sounded, phases)
    }

    /// What sounded after the greeting, with the times.
    var replies: [(String, Double)] { sounded { Array($0.dropFirst(greeting.count)) } }
    var modelTurns: [TurnTrace] { sink.records.filter { $0.source == "model" } }
}

/// A held answer about her text: the first sentence, then the whole answer.
func held(_ about: String) -> SpecModel.Plan {
    .held(first: "Ответ про \(about)! Как", full: "Ответ про \(about)! Как здорово.")
}

let murka = SpecModel.Plan.held(first: "Какая красивая Мурка! А", full: "Какая красивая Мурка! А какого она цвета?")

final class SpeculationTests: XCTestCase {
    func testTheAnswerBegunInHerPauseSoundsAtTheTail() async {  // U7
        let talk = SpecTalk(plans: [murka]) { model in
            [.init(text: "Я нарисовала Мурку", at: 11.8, pauses: [
                .init(at: 10.3, event: .tentative("Я нарисовала Мурку"), until: { model.calls.count == 1 }),
                .init(at: 11.3, action: { model.first(0) })
            ]), .init(text: nil)]
        }
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.calls.map(\.at), [10.3])
        XCTAssertEqual(talk.replies.first?.0, "Какая красивая Мурка!")
        XCTAssertEqual(talk.replies.first?.1 ?? -1, 11.8, accuracy: 1e-9)
        XCTAssertEqual(talk.phases { $0.first { $0.0 == .thinking }?.1 } ?? -1, 11.8, accuracy: 1e-9)
        XCTAssertEqual(talk.modelTurns.count, 1)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 1)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_lead"] ?? -1, 1.5, accuracy: 1e-9)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 0)
    }

    func testSpeechComingBackDropsTheBegunAnswer() async {  // U8
        let talk = SpecTalk(plans: [held("была"), held("зоопарк")]) { model in
            [.init(text: "Я была в зоопарке", at: 13.8, pauses: [
                .init(at: 10.3, event: .tentative("Я была"), until: { model.calls.count == 1 }),
                .init(at: 10.9, event: .resumed, until: { model.calls.first?.cancelled == true }),
                .init(at: 12.3, event: .tentative("Я была в зоопарке"), until: { model.calls.count == 2 }),
                .init(at: 12.8, action: { model.first(1) })
            ]), .init(text: nil)]
        }
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.calls.map(\.utterance), ["Я была", "Я была в зоопарке"])
        XCTAssertEqual(talk.model.calls.first?.cancelled, true)
        XCTAssertEqual(talk.model.memory, ["Я была в зоопарке"])
        XCTAssertEqual(talk.replies.first?.0, "Ответ про зоопарк!")
        XCTAssertEqual(talk.replies.first?.1 ?? -1, 13.8, accuracy: 1e-9)
        XCTAssertEqual(talk.modelTurns.count, 1)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 1)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 1)
    }

    func testWhatTheModelWouldNotGetIsNotBegun() async {  // U9
        let lines = ["Я живу на улице Морковной, дом семь", "Дай мне спички", "Пока"]
        let talk = SpecTalk(plans: [], router: RouterRouting()) { _ in
            lines.enumerated().map { index, line in
                let base = Double(index + 1) * 100
                return .init(text: line, at: base + 1.8, pauses: [.init(at: base + 0.3, event: .tentative(line))])
            }
        }
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.calls.count, 0)
        XCTAssertEqual(talk.sink.records.map(\.source),
                       ["session:greeting", "script:pii", "script:matches", "session:goodbye"])
        XCTAssertEqual(talk.sink.records[1].route?.forget, true)
    }

    func testAnotherTextAtTheTailBeginsAnew() async {  // U10
        let talk = SpecTalk(plans: [held("жирафа"), .timed("Жирафы высокие! Как башня.", after: 1.0)]) { model in
            [.init(text: "Я видела жирафов", at: 11.8, pauses: [
                .init(at: 10.3, event: .tentative("Я видела жирафа"), until: { model.calls.count == 1 })
            ]), .init(text: nil)]
        }
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.calls.map(\.utterance), ["Я видела жирафа", "Я видела жирафов"])
        XCTAssertEqual(talk.model.calls.first?.cancelled, true)
        XCTAssertEqual(talk.replies.first?.0, "Жирафы высокие!")
        XCTAssertEqual(talk.replies.first?.1 ?? -1, 12.8, accuracy: 1e-9)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 0)
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 1)
        XCTAssertEqual(Speculation.letters("я видела жирафа"), Speculation.letters("Я видела жирафа."))
    }

    func testTheParentsStopDropsTheBegunAnswer() async {  // U11
        let stopper = Locked<Conversation?>(nil)
        let talk = SpecTalk(plans: [held("кот")]) { model in
            [.init(text: nil, at: 12, pauses: [
                .init(at: 10.3, event: .tentative("У меня кот"), until: { model.calls.count == 1 }),
                .init(at: 11.0, action: { if let talk = stopper({ $0 }) { Task { await talk.stop() } } },
                      until: { model.calls.first?.cancelled == true })
            ])]
        }
        stopper { $0 = talk.conversation }
        await talk.conversation.wake()
        XCTAssertEqual(talk.model.calls.first?.cancelled, true)
        XCTAssertEqual(talk.voice.sentences, greeting)
        XCTAssertEqual(talk.conversation.state.phase, .asleep)
        XCTAssertEqual(talk.sink.records.map(\.source), ["session:greeting", "session:stop"])
        XCTAssertEqual(talk.sink.records.last?.end, "parent")
    }

    func testAnAnswerFinishedBeforeSheWentOnIsCountedStale() async {  // U12
        let session = Locked<Session?>(nil)
        let talk = SpecTalk(plans: [.held(first: "Ура!", full: "Ура!"), held("Ура два")]) { model in
            [.init(text: "Ура ура", at: 13.5, pauses: [
                .init(at: 10.3, event: .tentative("Ура"), until: { model.calls.count == 1 }),
                .init(at: 10.9, action: { model.finish(0) }, until: { session { $0 }?.begunAnswerFinished == true }),
                .init(at: 11.2, event: .resumed),
                .init(at: 12.0, event: .tentative("Ура ура"), until: { model.calls.count == 2 }),
                .init(at: 12.5, action: { model.first(1) })
            ]), .init(text: nil)]
        }
        session { $0 = talk.conversation.session }
        await talk.conversation.wake()
        XCTAssertEqual(talk.modelTurns.first?.stages["spec_stale"], 1)
        XCTAssertEqual(talk.model.memory, ["Ура", "Ура ура"])
    }

    /// On 200 random tapes (seeds fixed) the voice never sounds before the tail of its turn, each model turn answers
    /// the text at the tail, there are as many model turns as tails, and two answers never run at once.
    func testEveryTapeKeepsTheVoiceBehindTheTail() async {  // U13
        for seed in 0..<200 {
            var random = SeededGenerator(seed: UInt64(seed))
            let tape = (1...3).map { index in Tape.random(index, &random) }
            let talk = SpecTalk(plans: tape.flatMap(\.plans)) { model in
                var calls = 0
                return tape.map { $0.answer(model, calls: &calls) } + [.init(text: nil)]
            }
            await talk.conversation.wake()
            XCTAssertEqual(talk.ear.overlaps, 0, "\(seed)")
            XCTAssertEqual(talk.modelTurns.count, tape.count, "\(seed)")
            let answered = zip(talk.sink.records, talk.sink.words).filter { $0.0.source == "model" }
            for (record, words) in answered {
                let about = "Ответ про \(words.heard ?? "?")!"
                XCTAssertTrue(words.modelText?.hasPrefix(about) == true, "\(seed) \(record.turn)")
            }
            XCTAssertEqual(talk.model.most, 1, "\(seed)")
        }
    }
}

/// One answer of a random tape at `100 × index` s: begun and taken, begun and dropped as she went on, begun on another
/// text, or not begun; the first sentence of a taken answer comes at a random moment before the tail.
struct Tape {
    enum Kind: CaseIterable { case taken, resumed, changed, none }
    let index: Int, kind: Kind, first: Double, words: [String]

    static func random(_ index: Int, _ random: inout SeededGenerator) -> Tape {
        let words = ["Мы рисовали кота", "Соня строила дом", "Тёма пел песню", "Мурка спала"].shuffled(using: &random)
        return Tape(index: index, kind: Kind.allCases.randomElement(using: &random) ?? .none,
                    first: Double.random(in: 0.1...1.3, using: &random), words: Array(words.prefix(2)))
    }

    var base: Double { Double(index) * 100 }
    var heard: String { kind == .changed || kind == .resumed ? words[1] : words[0] }

    var plans: [SpecModel.Plan] {
        switch kind {
        case .taken: [held(words[0])]
        case .resumed: [held(words[0]), held(words[1])]
        case .changed: [held(words[0]), .timed("Ответ про \(words[1])! Ага.", after: 0.7)]
        case .none: [.timed("Ответ про \(words[0])! Ага.", after: 0.7)]
        }
    }

    func answer(_ model: SpecModel, calls: inout Int) -> ScriptedEar.Answer {
        let begun = calls, tail = base + 3.0
        func tentative(_ at: Double, _ text: String, count: Int) -> ScriptedEar.Pause {
            .init(at: at, event: .tentative(text), until: { model.calls.count == count })
        }
        switch kind {
        case .taken:
            calls += 1
            return .init(text: words[0], at: tail, pauses: [
                tentative(base + 0.3, words[0], count: begun + 1),
                .init(at: base + 0.3 + first, action: { model.first(begun) })
            ])
        case .resumed:
            calls += 2
            return .init(text: words[1], at: tail + 1, pauses: [
                tentative(base + 0.3, words[0], count: begun + 1),
                .init(at: base + 0.35, event: .resumed, until: { model.calls[begun].cancelled }),
                tentative(base + 1.3, words[1], count: begun + 2),
                .init(at: base + 1.3 + first, action: { model.first(begun + 1) })
            ])
        case .changed:
            calls += 2
            return .init(text: words[1], at: tail, pauses: [tentative(base + 0.3, words[0], count: begun + 1)])
        case .none:
            calls += 1
            return .init(text: words[0], at: tail)
        }
    }
}
