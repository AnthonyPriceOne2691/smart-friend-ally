@testable import AllyCore
import XCTest

let restPhrase = ["Что-то я тебя не слышу.", "Я немножко посплю.", "Нажми на меня, когда захочешь поболтать!"]

/// A conversation over doubles: the session parts of `Rig` with a scripted ear; the states the session went through.
struct Talk {
    let clock: TestClock, sink: RecordingSink, model: ReplyQueue, voice: RecordingVoice, ear: ScriptedEar
    let states: StateLog, conversation: Conversation

    init(_ answers: [ScriptedEar.Answer], replies: [String] = [], limit: String? = nil, seconds: Double = 0) {
        let clock = TestClock(), sink = RecordingSink(), states = StateLog()
        let voice = RecordingVoice { clock.advance(by: seconds) }, model = ReplyQueue(replies)
        let ear = ScriptedEar(answers, clock: clock, voice: voice)
        let parts = SessionParts(model: model, voice: voice, sink: sink, clock: clock, onState: { states.record($0) })
        conversation = Conversation(parts, settings: SessionSettings(limitMinutes: limit), listener: ear)
        ear.watch(conversation)
        (self.clock, self.sink, self.model, self.voice) = (clock, sink, model, voice)
        (self.ear, self.states) = (ear, states)
    }
}

final class ConversationTests: XCTestCase {
    func testTheEarListensOnlyWhileTheSessionListens() async {  // W1
        let talk = Talk([.init(text: "Я сегодня была в зоопарке"), .init(text: nil), .init(text: nil)],
                        replies: ["Ух ты, в зоопарке! А кого ты там видела?"])
        await talk.conversation.wake()
        XCTAssertEqual(talk.voice.sentences,
                       greeting + ["Ух ты, в зоопарке!", "А кого ты там видела?", misheard] + restPhrase)
        XCTAssertEqual(talk.ear.phases, [.listening, .listening, .listening])
        XCTAssertEqual(talk.ear.overlaps, 0)
        XCTAssertEqual(talk.model.calls, 1)
        XCTAssertEqual(talk.conversation.state.phase, .asleep)
        XCTAssertEqual(talk.sink.records.map(\.end), [nil, nil, nil, "rest"])
    }

    /// On 200 random tapes of the ear (her text, "", silence, her goodbye; seeds fixed) every session ends asleep,
    /// the ear is called once per entry into listening or windingDown, one at a time and never while she speaks.
    func testEveryTapeEndsAsleepWithOneListeningPerListeningState() async {  // W1
        for seed in 0..<200 {
            var random = SeededGenerator(seed: UInt64(seed))
            let tape = (0..<12).map { _ -> ScriptedEar.Answer in
                switch Int.random(in: 0..<10, using: &random) {
                case 0..<5: .init(text: "Расскажи про жирафа")
                case 5..<7: .init(text: "")
                case 7..<9: .init(text: nil)
                default: .init(text: "Пока!")
                }
            }
            let talk = Talk(tape, replies: ["Жирафы очень высокие."], limit: "1", seconds: 4)
            await talk.conversation.wake()
            let log = talk.states.log
            let entries = zip([SessionState.asleep] + log, log).filter { !$0.0.listens && $0.1.listens }.count
            XCTAssertEqual(talk.conversation.state.phase, .asleep, "\(seed)")
            XCTAssertEqual(talk.ear.calls, entries, "\(seed)")
            XCTAssertEqual(talk.ear.most, 1, "\(seed)")
            XCTAssertEqual(talk.ear.overlaps, 0, "\(seed)")
        }
    }

    func testStopWhileListeningLeavesTheLateResultOut() async {  // W2
        let talk = Talk([.init(text: "Привет", held: true)])
        let first = Task { await talk.conversation.wake() }
        await eventually { talk.ear.calls == 1 }
        await talk.conversation.stop()
        XCTAssertEqual(talk.conversation.state.phase, .asleep)
        XCTAssertEqual(talk.conversation.state.ended, "parent")
        XCTAssertEqual(talk.sink.records.map(\.source), ["session:greeting", "session:stop"])
        let second = Task { await talk.conversation.wake() }
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(talk.voice.sentences, greeting)
        talk.ear.release()
        await first.value
        await second.value
        XCTAssertEqual(talk.model.calls, 0)
        XCTAssertEqual(talk.ear.most, 1)
        XCTAssertEqual(talk.voice.sentences, greeting + greeting + [misheard] + restPhrase)
        XCTAssertEqual(talk.sink.records.map(\.source), ["session:greeting", "session:stop", "session:greeting",
                                                          "session:misheard", "session:rest"])
        XCTAssertEqual(Set(talk.sink.records.map(\.session)).count, 2)
    }

    func testPastTheLimitTheEarHearsTheLastUtterance() async {  // W3
        let talk = Talk([.init(text: "Смотри, я нарисовала кота", at: 110), .init(text: nil)],
                        replies: ["Какой красивый кот! А какого он цвета?"], limit: "2", seconds: 7.5)
        await talk.conversation.wake()
        XCTAssertEqual(talk.ear.phases, [.listening, .windingDown])
        XCTAssertEqual(Array(talk.voice.sentences.suffix(5)), ["Какой красивый кот!", "А какого он цвета?"] + goodbye)
        XCTAssertEqual(talk.model.calls, 1)
        XCTAssertEqual(talk.sink.records.last?.end, "limit")
        XCTAssertEqual(talk.conversation.state.phase, .asleep)
    }

    func testTheScreenSeesEveryPhaseInOrder() async {  // W7
        let talk = Talk([.init(text: "Я сегодня была в зоопарке", held: true), .init(text: nil, held: true),
                         .init(text: nil, held: true)], replies: ["Ух ты, в зоопарке! А кого ты там видела?"])
        let seen = Locked([TalkState]())
        let reader = Task { for await state in talk.conversation.updates { seen { $0.append(state) } } }
        defer { reader.cancel() }
        let session = Task { await talk.conversation.wake() }
        for count in [3, 6, 8] {
            await eventually { seen { $0.count } == count }
            talk.ear.release()
        }
        await session.value
        await eventually { seen { $0.count } == 10 }
        let states = seen { $0 }
        XCTAssertEqual(states.map(\.phase), [.asleep, .greeting, .listening, .thinking, .speaking, .listening,
                                             .speaking, .listening, .goodbye, .asleep])
        XCTAssertEqual(states.map(\.pose), [.sleeps, .speaks, .listens, .thinks, .speaks, .listens, .speaks, .listens,
                                            .speaks, .sleeps])
        XCTAssertEqual(states.map(\.ended), Array(repeating: nil, count: 9) + ["rest"])
        await talk.conversation.wake()
        await eventually { seen { $0.count } == 16 }  // greeting, listening, «не расслышала», listening, rest, asleep
        let next = seen { $0.count > 10 ? $0[10] : nil }
        XCTAssertEqual(next?.phase, .greeting)
        XCTAssertNil(next?.ended)
    }
}
