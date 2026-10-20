import AllyCore
import Discipline
import XCTest

/// Hard replies for the stream: end marks, numbers, abbreviations, lists, a boundary without a space, markup,
/// endearments, a placeholder, Latin, emoji, thinking, line breaks, long and short, rules of the contract.
let hardReplies = [
    "Ура!! Ты молодец. Давай ещё?", "Ну... я думаю, это кот. А ты как думаешь?",
    "Слон весит 2.5 тонны. Это очень много!", "Правда?! Вот это да. Расскажи ещё!", "Хм… Интересно. А почему?",
    "Это т. е. кошка. Она мяукает.", "1. Кошка. 2. Собака. 3. Рыбка.", "- Кошка.\n- Собака.\nА кто тебе нравится?",
    "Ура!Давай играть? Это весело.", "**Привет!** Как дела? Я Элли.", "Солнышко, привет! Как дела?",
    "Привет, солнышко! Что нового?", "[Имя девочки]! Как дела? Что рисовала?", "Hello! Я тут. Как ты?",
    "Это OK. Всё хорошо.", "У слона 4 ноги. А у курицы 2.", "Мне 5 лет. А тебе?", "Сегодня 10:30. Пора гулять!",
    "Смотри, бабочка 🦋! Она красивая.", "<think>Хм. Думаю.</think> Привет! Как дела?",
    "Привет!\nКак дела?\nЧто делала?", "Давай зажжём спичку! Будет красиво.", "Я буду ждать тебя завтра. Пока!",
    "Ты моя хорошая! Как дела?", "Таблетки нельзя есть, их даёт только мама. А какие ещё штучки ты нашла в шкафу?",
    "Ой, не бойся! Это просто гром. Он далеко. Если страшно, скажи маме.",
    "Слоны очень большие. Они едят траву и листья. Слоны любят купаться. "
        + "А ещё у них длинный хобот. Хочешь узнать про уши?",
    "Ура! Хочешь ещё один раунд? Или расскажешь, как твой братик сегодня?",
    "Ой, какой интересный вопрос! А как ты думаешь, зачем люди спят? Мозг ночью отдыхает и растёт.",
    "Это очень длинное предложение про то, как кошка гуляла по двору и встретила собаку, "
        + "а потом они вместе пошли искать мячик. Здорово?",
    "«Мяу!» — сказала кошка. Смешно?", "5 4 3 2 1. Поехали!", "Смотри на сайт www.kot.ru. Там котики.",
    "Привет! Меня зовут Элли. А тебя зовут Соня?", "Брат Тёма тоже придёт? Ура!",
    "Мурка спит на диване... Тсс! Не буди её.", "Правильно — это (почти) кит. Молодец!",
    "Раз, два, три — замри! Ты замерла?", "А?.. Повтори, пожалуйста.", "Привет", "Я всегда буду с тобой! Обещаю."
]

/// Replies built from pieces by a fixed seed (an LCG): 1–5 pieces, an end mark or none, a space, nothing or a line.
func generatedReplies(count: Int, seed: UInt64) -> [String] {
    let pieces = ["Привет", "Как дела", "Слон весит 2.5 тонны", "Ну", "Это т. е. кошка", "1. Кошка", "Hello", "Это OK",
                  "Солнышко", "**Ура**", "У слона 4 ноги", "Мне 5", "<think>Хм</think> Да", "Давай играть", "Я тут",
                  "Смотри 🦋", "[Имя]", "Мурка спит", "Тёма пришёл", "Пять, четыре", "Нельзя трогать плиту"]
    let marks = [".", "!", "?", "…", "?!", "...", "!!", ""], joints = [" ", "", "\n", "  "]
    var state = seed
    func next(_ bound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state >> 33) % bound
    }
    return (0..<count).map { _ in
        (0...next(5)).map { _ in pieces[next(pieces.count)] + marks[next(marks.count)] }
            .reduce("") { $0.isEmpty ? $1 : $0 + joints[next(joints.count)] + $1 }
    }
}

final class TurnRunnerTests: XCTestCase {
    private func spoken(_ reply: String) async throws -> [String] {
        let clock = TestClock(), voice = RecordingVoice()
        let runner = TurnRunner(model: ScriptedModel.typing(reply, clock: clock), voice: voice, clock: clock)
        _ = try await runner.run("реплика")
        return voice.sentences
    }

    private func whole(_ reply: String) -> [String] { TurnContract(mode: .talk).finish(reply).sentences }

    func testEveryReplyPassesTheContract() async throws {  // A1
        let raw = ["Я буду ждать тебя завтра.", "Солнышко, привет!", "У слона 4 ноги."]
        let many = "Слоны большие. Они серые. "
        for reply in raw + ["Давай зажжём спичку!", many + "Они едят траву. Хочешь про уши? Или про хобот?"] {
            let heard = try await spoken(reply)
            XCTAssertEqual(heard, whole(reply), reply)
            XCTAssertFalse(heard.contains { raw.contains($0) }, reply)
        }
    }

    func testFirstSentenceSoundsBeforeTheReplyEnds() async throws {  // A2
        let clock = TestClock(), voice = RecordingVoice()  // the boundary is safe once a next word begins
        let model = ScriptedModel([.wait(0.3), .say("Слоны очень большие. О"), .wait(2.7), .say("ни едят траву.")],
                                  clock: clock)
        let task = Task { try await TurnRunner(model: model, voice: voice, clock: clock).run("Расскажи про слонов") }
        await eventually { clock.sleeping >= 2 }
        clock.advance(by: 0.3)
        await eventually { voice.sentences.count == 1 && clock.sleeping >= 2 }
        clock.advance(by: 2.7)
        let outcome = try await task.value
        XCTAssertEqual(voice.sentences, ["Слоны очень большие.", "Они едят траву."])
        XCTAssertEqual(outcome.times.firstSound ?? -1, 0.3, accuracy: 1e-9)
        XCTAssertEqual(outcome.times.replyEnd ?? -1, 3.0, accuracy: 1e-9)
    }

    func testStreamedTurnEqualsTheWholeReply() async throws {  // A3
        XCTAssertGreaterThanOrEqual(hardReplies.count, 40)
        for reply in hardReplies + generatedReplies(count: 200, seed: 20_261_019) {
            let heard = try await spoken(reply)
            XCTAssertEqual(heard, whole(reply), reply)
        }
        let elephant = try await spoken("Слон весит 2.5 тонны. Это очень много!")
        XCTAssertEqual(elephant, ["Слон весит два и пять тонны.", "Это очень много!"])
    }

    func testRefusedFirstSentenceCancelsTheModel() async throws {  // A4
        let fire = ["Спички и зажигалку сама не бери: можно обжечься или устроить пожар.",
                    "Зажечь свечку попроси маму или папу."]
        let hug = ["Мне с тобой весело!", "А теперь беги поиграй с мамой или папой."]
        for (first, canned) in [("Я всегда буду с тобой! ", hug), ("Давай зажжём спичку! ", fire)] {
            let clock = TestClock(), voice = RecordingVoice()
            let model = ScriptedModel([.say(first + "А"), .wait(1), .say(" ещё мы будем играть.")], clock: clock)
            let outcome = try await TurnRunner(model: model, voice: voice, clock: clock).run("реплика")
            XCTAssertTrue(model.cancelled && outcome.turn.source != .model, first)
            XCTAssertEqual(voice.sentences, canned)
        }
    }

    func testCancelStopsVoiceAndModelAndRethrows() async throws {  // A5
        let clock = TestClock(), voice = RecordingVoice(hold: true)
        let model = ScriptedModel([.say("Привет! К"), .wait(5), .say("ак дела?")], clock: clock)
        let task = Task { try await TurnRunner(model: model, voice: voice, clock: clock).run("Привет") }
        await eventually { voice.sentences.count == 1 }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("отмена проглочена: ход вернул итог")
        } catch is CancellationError {
            XCTAssertTrue(voice.stopped)
            XCTAssertTrue(model.cancelled)
        }
        XCTAssertEqual(voice.sentences, ["Привет!"])
    }

    func testHangEmptyAndLatin() async throws {  // A6
        let clock = TestClock(), voice = RecordingVoice()
        let model = ScriptedModel([.hang], clock: clock)
        let task = Task { try await TurnRunner(model: model, voice: voice, clock: clock).run("реплика") }
        await eventually { clock.sleeping >= 2 }
        clock.advance(by: 9.9)
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertTrue(voice.sentences.isEmpty)
        clock.advance(by: 0.1)
        let outcome = try await task.value
        XCTAssertTrue(outcome.modelTimeout)
        XCTAssertTrue(model.cancelled)
        XCTAssertEqual(voice.sentences, ["Ой, повтори, пожалуйста, я не расслышала."])
        XCTAssertTrue(TurnLog(outcome: outcome).jsonLine()?.contains("\"model_timeout\":true") ?? false)
        for reply in ["", "Hello! Я тут, привет. Это OK?"] {
            let heard = try await spoken(reply)
            XCTAssertEqual(heard, reply.isEmpty ? ["Ой, повтори, пожалуйста, я не расслышала."] : whole(reply))
            XCTAssertFalse(heard.joined().contains { $0.isASCII && $0.isLetter }, heard.joined())
        }
    }
}
