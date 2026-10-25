@testable import AllyCore
import XCTest

/// D6.2 `barge-in`, the session's part: her speech or tap over Elly cuts the turn the parent's stop would — the voice
/// stops, the model is cancelled, its memory keeps what sounded (D5) — but the session listens at once, and the audio
/// session taken away pauses it until it comes back. The ear and the screen are doubles.
final class BargeInTests: XCTestCase {
    /// A session whose voice holds the second sentence of its first answer until it is stopped.
    private struct Cut {
        let clock = TestClock(), sink = RecordingSink(), model: ReplyQueue, voice: RecordingVoice, session: Session

        init(_ replies: [String]) {
            let voice = RecordingVoice(hold: true, from: greeting.count + 1), model = ReplyQueue(replies)
            (self.voice, self.model) = (voice, model)
            session = Session(SessionParts(model: model, voice: voice, sink: sink, clock: clock))
        }

        /// Her utterance; returns once the voice holds the answer's second sentence.
        func answering(_ text: String) async -> Task<Void, Never> {
            let turn = Task { [session] in await session.handle(.heard(text)) }
            await eventually { voice.sentences.count == greeting.count + 2 }
            return turn
        }
    }

    func testHerSpeechOverElliesVoiceCutsTheTurnAndSheIsHeardAtOnce() async {  // X13
        let cut = Cut(["Слоны очень большие. Они едят траву.", "Жирафы высокие!"])
        await cut.session.handle(.wake)
        let turn = await cut.answering("Расскажи про слонов")
        await cut.session.handle(.bargeIn)
        await turn.value
        XCTAssertTrue(cut.voice.stopped && cut.model.cancelled)
        XCTAssertEqual(cut.session.state, .listening)
        let record = cut.sink.records.last
        XCTAssertEqual(record?.cancelled, true)
        XCTAssertNil(record?.end)
        XCTAssertEqual(record?.stages["barge_in"], 1)
        XCTAssertEqual(cut.model.memory.turns, [.init(heard: "Расскажи про слонов", said: "Слоны очень большие.")])
        await cut.session.handle(.heard("А я видела жирафа"))
        XCTAssertEqual(cut.sink.records.last?.source, "model")
        XCTAssertEqual(cut.sink.records.last?.cancelled, false)
        XCTAssertEqual(Array(cut.voice.sentences.suffix(1)), ["Жирафы высокие!"])
        XCTAssertEqual(cut.model.memory.turns.last, .init(heard: "А я видела жирафа", said: "Жирафы высокие!"))
        // A sleeping session has no Elly to cut: the event changes nothing.
        let idle = Cut([])
        await idle.session.handle(.bargeIn)
        XCTAssertEqual(idle.session.state, .asleep)
        XCTAssertTrue(idle.sink.records.isEmpty)
        // While Elly only thinks, nothing sounds yet: her speech is the next utterance, the answer is not cut.
        let clock = TestClock(), sink = RecordingSink(), voice = RecordingVoice()
        let model = ScriptedModel([.wait(1), .say("Слоны большие. О"), .say("ни серые.")], clock: clock)
        let thinking = Session(SessionParts(model: model, voice: voice, sink: sink, clock: clock))
        await thinking.handle(.wake)
        let answer = Task { await thinking.handle(.heard("Расскажи про слонов")) }
        await eventually { thinking.state == .thinking && clock.sleeping >= 2 }
        await thinking.handle(.bargeIn)
        clock.advance(by: 1)
        await answer.value
        XCTAssertEqual(sink.records.last?.cancelled, false)
        XCTAssertEqual(Array(voice.sentences.suffix(2)), ["Слоны большие.", "Они серые."])
    }

    func testATapOnElliesBubbleWhileSheGreetsIsTheSame() async {  // X14
        let talk = Talk([.init(text: "Привет, Элли"), .init(text: nil)], replies: ["Привет! Как дела?"],
                        holdVoice: true)
        let session = Task { await talk.conversation.wake() }
        await eventually { talk.voice.sentences.count == 1 }
        await talk.conversation.bargeIn()
        await session.value
        let records = talk.sink.records
        XCTAssertEqual(records.first?.source, "session:greeting")
        XCTAssertEqual(records.first?.cancelled, true)
        XCTAssertEqual(records.first?.stages["barge_in"], 1)
        XCTAssertEqual(records.map(\.source), ["session:greeting", "model", "session:misheard", "session:rest"])
        XCTAssertEqual(talk.ear.calls, 3)
        XCTAssertEqual(talk.model.memory.turns.first?.heard, "Привет, Элли")
        XCTAssertEqual(talk.voice.sentences.first, greeting.first)
        XCTAssertFalse(talk.voice.sentences.contains(greeting[1]))
    }

    func testTheAudioSessionTakenAwayPausesAndHerListeningComesBack() async {  // X16
        let cut = Cut(["Слоны очень большие. Они едят траву.", "Жирафы высокие!"])
        await cut.session.handle(.wake)
        let turn = await cut.answering("Расскажи про слонов")
        await cut.session.handle(.interruptionBegan)
        await turn.value
        XCTAssertEqual(cut.session.state, .paused)
        XCTAssertEqual(TalkState(phase: cut.session.state).pose, .sleeps)
        XCTAssertEqual(cut.sink.records.last?.stages["interrupted"], 1)
        XCTAssertNil(cut.sink.records.last?.end)
        XCTAssertEqual(cut.model.memory.turns, [.init(heard: "Расскажи про слонов", said: "Слоны очень большие.")])
        await cut.session.handle(.heard("Это мама звонит"))
        XCTAssertEqual(cut.sink.records.count, 2)  // the greeting and the cut turn: nothing is heard during the pause
        await cut.session.handle(.interruptionEnded)
        XCTAssertEqual(cut.session.state, .listening)
        await cut.session.handle(.heard("А я видела жирафа"))
        XCTAssertEqual(cut.sink.records.last?.source, "model")
        // Through the driver: the pause outlives a listening, the session listens again, the parent's stop ends it.
        let talk = Talk([.init(text: nil, held: true), .init(text: "А я видела жирафа"), .init(text: nil)],
                        replies: ["Жирафы высокие!"])
        let session = Task { await talk.conversation.wake() }
        await eventually { talk.ear.calls == 1 }
        await talk.conversation.interruption(began: true)
        talk.ear.release()
        await eventually { talk.conversation.state.phase == .paused }
        await talk.conversation.interruption(began: false)
        await eventually { talk.ear.calls >= 2 }
        await talk.conversation.stop()
        await session.value
        XCTAssertEqual(talk.conversation.state.phase, .asleep)
        XCTAssertTrue(talk.sink.records.contains { $0.source == "model" })
    }
}
