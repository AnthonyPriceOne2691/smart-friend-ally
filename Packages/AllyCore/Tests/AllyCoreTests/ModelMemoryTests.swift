@testable import AllyCore
import XCTest

/// D5 `kv-spoken`: the model's memory keeps her line and what sounded — a sentence cut by a stop does not count, a
/// canned reply and a router's script do, an answer begun in her pause that she talked past leaves entirely, her
/// address never gets there. The doubles keep the memory as `LlamaModel` does; the calls go through the session.
final class ModelMemoryTests: XCTestCase {
    func testAStopKeepsOnlyTheSentencesPlayedToTheEnd() async throws {  // X2
        let clock = TestClock(), voice = RecordingVoice(hold: true, from: 1)
        let model = ScriptedModel.typing("Слоны большие. Они едят траву.", clock: clock)
        let task = Task { try await TurnRunner(model: model, voice: voice, clock: clock).run("Расскажи про слонов") }
        await eventually { voice.sentences.count == 2 }
        task.cancel()
        _ = try? await task.value
        XCTAssertEqual(voice.sentences, ["Слоны большие.", "Они едят траву."])
        XCTAssertEqual(model.memory.turns, [.init(heard: "Расскажи про слонов", said: "Слоны большие.")])
        // The parent's stop through the session: the wrapper of the answer begun in her pause passes `commit` on (L58).
        let rig = Rig(replies: ["Привет! Как дела?"], hold: true)
        await rig.session.handle(.wake)
        let turn = Task { await rig.hear("Привет") }
        await eventually { rig.voice.sentences.count == greeting.count + 1 }
        await rig.session.handle(.stop)
        await turn.value
        XCTAssertEqual(rig.said, ["Привет!"])
        XCTAssertEqual(rig.model.memory.turns, [.init(heard: "Привет", said: "")])
    }

    func testARefusedFirstSentenceLeavesItsCannedReplyInTheMemory() async throws {  // X3
        let clock = TestClock(), voice = RecordingVoice()
        let model = ScriptedModel([.say("Давай зажжём спичку! А"), .wait(1), .say(" ещё мы будем играть.")],
                                  clock: clock)
        let outcome = try await TurnRunner(model: model, voice: voice, clock: clock).run("Мне скучно")
        XCTAssertTrue(model.cancelled && outcome.turn.source != .model)
        XCTAssertFalse(voice.sentences.isEmpty)
        XCTAssertEqual(model.memory.turns, [.init(heard: "Мне скучно", said: voice.sentences.joined(separator: " "))])
    }

    /// Until D5 such an answer stayed in the memory and was counted `spec_stale` (U12 of D7.1). The answer is read to
    /// its end by a task of its own, so her speech comes back only once the session has seen that end.
    func testAnAnswerFinishedBeforeSheWentOnLeavesTheMemory() async {  // X4
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
        let stages = talk.modelTurns.first?.stages ?? [:]
        XCTAssertEqual(stages["spec_retracted"], 1)
        XCTAssertNil(stages["spec_stale"])
        XCTAssertEqual(talk.model.calls.map(\.utterance), ["Ура", "Ура ура"])
        let said = zip(talk.sink.records, talk.sink.words).first { $0.0.source == "model" }?.1.said
        XCTAssertEqual(said, ["Ответ про Ура два!", "Как здорово."])
        XCTAssertEqual(talk.model.memory.turns, [.init(heard: "Ура ура", said: said?.joined(separator: " "))])
    }

    /// Every dropped answer leaves the memory; one the model had finished is counted `spec_retracted`, never stale.
    func testADroppedAnswerLeavesTheMemoryAndAFinishedOneIsCounted() async {  // X4
        let clock = TestClock(), model = SpecModel([held("Ура"), held("Мурку")], clock: clock)
        let speculation = Speculation(model, clock: clock)
        speculation.start("Ура")
        model.finish(0)
        await eventually { speculation.finished }
        speculation.drop()
        XCTAssertEqual(speculation.takeStages(), ["spec_reused": 0, "spec_cancels": 1, "spec_retracted": 1])
        speculation.start("Я нарисовала Мурку")
        speculation.drop()
        XCTAssertEqual(speculation.takeStages(), ["spec_reused": 0, "spec_cancels": 1])
        XCTAssertEqual(model.calls.map(\.cancelled), [false, true])
        XCTAssertEqual(model.memory.turns, [])
    }

    func testAScriptIsRememberedAndAForgottenLineIsNot() async {  // X5
        let lines = ["можно я возьму нож?", "Я живу на улице Морковной, дом семь"]
        let talk = SpecTalk(plans: [], router: RouterRouting()) { _ in
            lines.enumerated().map { .init(text: $1, at: Double($0 + 1) * 100) } + [.init(text: nil)]
        }
        await talk.conversation.wake()
        let records = Array(zip(talk.sink.records, talk.sink.words))
        XCTAssertEqual(records.prefix(3).map(\.0.source), ["session:greeting", "script:knife", "script:pii"])
        XCTAssertEqual(records[2].0.route?.forget, true)
        XCTAssertEqual(talk.model.calls.count, 0)
        let knife = records[1].1.said?.joined(separator: " ")
        XCTAssertEqual(knife?.isEmpty, false)
        XCTAssertEqual(talk.model.memory.turns, [.init(heard: lines[0], said: knife)])
    }
}
