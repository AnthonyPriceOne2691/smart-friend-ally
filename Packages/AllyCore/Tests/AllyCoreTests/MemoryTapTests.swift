@testable import AllyCore
import Discipline
import XCTest

/// M33: a session through `Conversation` with the tap in the fan-out; her utterances and the router's decisions —
/// invented.
private enum Picks {
    static let cat = "у меня кошка мурка", reply = "Мурка — красивое имя! Какая она?"
    static let routes = [
        "я живу на улице морковной": Route(.pass, forget: true),
        "можно взять спички": Route(.script(key: "matches")),
        "мне страшно": Route(.guard(topic: "fear"))
    ]
    static let answers: [ScriptedEar.Answer] = [cat, "я живу на улице морковной", "можно взять спички", "мне страшно",
                                                "пока"].map { ScriptedEar.Answer(text: $0) }

    /// What the tap took and which talks it closed, for the audience of the session and of the tap.
    static func run(_ audience: Audience, tap audiences: Set<Audience>) async -> ([MemoryTap.Heard], [String]) {
        let taken = Locked<[MemoryTap.Heard]>([]), closed = Locked<[String]>([])
        let tap = MemoryTap(audiences: audiences, take: { heard in taken { $0.append(heard) } },
                            close: { session in closed { $0.append(session) } })
        let clock = TestClock(), voice = RecordingVoice(), journal = RecordingSink()
        let model = ReplyQueue([reply, "Страшно бывает. Расскажи маме или папе, они рядом."])
        let parts = SessionParts(model: model, voice: voice, sink: TraceFanOut([journal, tap]), clock: clock,
                                 router: TableRouter(table: routes), audience: audience)
        let ear = ScriptedEar(answers, clock: clock, voice: voice)
        let conversation = Conversation(parts, listener: ear)
        ear.watch(conversation)
        await conversation.wake()
        return (taken { $0 }, closed { $0 })
    }
}

final class MemoryTapTests: XCTestCase {
    func testOnlyHerPassedLinesOfTheChildSessionReachMemory() async {  // M33
        let (taken, closed) = await Picks.run(.supervised, tap: [.supervised])
        XCTAssertEqual(taken.map(\.her), [Picks.cat])
        XCTAssertEqual(taken.map(\.elly), [Picks.reply])
        XCTAssertEqual(taken.map(\.turn), [2])
        XCTAssertEqual(closed, taken.map(\.session))

        let (console, consoleClosed) = await Picks.run(.parent, tap: [.supervised])
        XCTAssertEqual(console, [])
        XCTAssertEqual(consoleClosed, [])
        let (argued, _) = await Picks.run(.parent, tap: [.supervised, .parent])
        XCTAssertEqual(argued.map(\.her), [Picks.cat])
    }
}
