@testable import AllyCore
import XCTest

/// M42 through the real `Session`: her lines of D2 «брат» of the persona stand (14 turns, she does not speak of her
/// brother), a model double that calls her by name and asks about the brother in every reply; invented names from the
/// memory — hers «Соня», her brother's «Тёма». What a turn said is what the model's memory got (D5).
private enum Window {
    static let names = FamilyNames(her: "Соня", brothers: ["Тёма"])
    static let reply = "Соня, как здорово! А что сегодня делал братик Тёма?"
    static let d2 = ["Привет!", "У меня всё хорошо.", "Я сегодня рисовала.", "Котика.", "Рыжего.",
                     "Давай поиграем во что-нибудь!", "Давай!", "Не знаю.", "А теперь ты загадай.", "Это яблоко?",
                     "Ура!", "А что ты любишь?", "Расскажи что-нибудь смешное.", "Ха-ха!"]

    static func brother(_ said: String) -> Bool { said.lowercased().contains("брат") || said.contains("Тём") }

    static func said(_ model: ReplyQueue) -> [String] { model.memory.turns.map { $0.said ?? "" } }
}

final class WindowTests: XCTestCase {
    func testOverTheFourteenTurnsOfD2TheBrotherSoundsTwiceAndHerNameInFourReplies() async {  // M42
        let rig = Rig(replies: [Window.reply], names: Window.names)
        await rig.session.handle(.wake)
        for line in Window.d2 { await rig.hear(line) }
        let said = Window.said(rig.model)
        XCTAssertEqual(said.count, 14)
        XCTAssertEqual(said.indices.filter { Window.brother(said[$0]) }, [0, 1])
        XCTAssertEqual(said.indices.filter { said[$0].contains("Соня") }, [2, 5, 8, 11])
        XCTAssertEqual(Array(said.prefix(4)), ["Как здорово! А что сегодня делал братик Тёма?",
                                               "Как здорово! А что сегодня делал братик Тёма?", "Соня, как здорово!",
                                               "Как здорово!"])
    }

    func testWhenSheSpeaksOfHerBrotherTheReplyAboutHimStaysAndDoesNotCount() async {  // M42
        let rig = Rig(replies: [Window.reply], names: Window.names)
        await rig.session.handle(.wake)
        for line in ["Привет!", "А мой брат сегодня забил гол!", "Я рисовала.", "А Тёма тоже рисовал!", "Ура!"] {
            await rig.hear(line)
        }
        XCTAssertEqual(Window.said(rig.model).map(Window.brother), [true, true, true, true, false])
    }

    func testTheNamesReachTheSessionThroughTheConversation() async {  // M42
        let talk = Talk([.init(text: "Привет!")], replies: [Window.reply], names: Window.names)
        await talk.conversation.wake()
        XCTAssertEqual(Window.said(talk.model).first, "Как здорово! А что сегодня делал братик Тёма?")
    }

    func testWithoutNamesTheWordBrotherIsStillCounted() async {  // M42
        let rig = Rig(replies: ["Здорово! А братик дома?"])
        await rig.session.handle(.wake)
        for line in ["Привет!", "Я рисовала.", "Котика."] { await rig.hear(line) }
        XCTAssertEqual(Window.said(rig.model), ["Здорово! А братик дома?", "Здорово! А братик дома?", "Здорово!"])
    }
}
