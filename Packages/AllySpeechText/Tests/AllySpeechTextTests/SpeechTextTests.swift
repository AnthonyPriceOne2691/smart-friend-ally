import Foundation
import XCTest
@testable import AllySpeechText

/// Примеры V2 спеки серии голоса (Z8–Z13, коммит 68202f0), подписанные родителем 2026-10-23. Расстановщик — двойник по
/// протоколу; «звучит» — строка `engine`, которую получил бы движок.
final class SpeechTextTests: XCTestCase {
    /// Вход движка для слова, которое расстановщик отдал «+»-формой: настоящий путь конвейера.
    private func spoken(_ form: String, _ table: SpeechTextTable) throws -> String {
        let plain = form.replacingOccurrences(of: "+", with: "")
        return try SpeechTextPipeline(placer: FixedPlacer(form: form), table: table).prepare(plain).engine
    }

    /// Фикстура со всеми видами правил — не строки второго круга: механизм обязан принять их данными без правки кода.
    private func mechanismTable() throws -> SpeechTextTable {
        try SpeechTextTable(stress: ["здорово": "зд+орово"], names: ["элли": "+эл-ли"],
                            words: ["сегодня": "севодня", "конечно": "конешно"],
                            endings: [.init(end: "ого", to: "ово", unstressed: "ова", except: ["много", "ого"]),
                                      .init(end: "его", to: "ево", unstressed: "ева"),
                                      .init(end: "тся", to: "ца"), .init(end: "ться", to: "ца")],
                            parts: ["сч": "щ", "лнц": "нц"])
    }

    func testMarkOnEveryWordOfTwoSyllablesButNotOnYo() throws {
        // Z8: стадия знаков — пустая таблица; «+» двойника на словах в один слог и на «ё» знаком не становится
        let placer = FormsPlacer(["привет": "прив+ет", "это": "+это", "я": "+я", "элли": "+элли", "что": "чт+о",
                                  "у": "+у", "тебя": "теб+я", "нового": "н+ового", "ёжик": "+ёжик"])
        let pipeline = SpeechTextPipeline(placer: placer, table: try SpeechTextTable())
        XCTAssertEqual(try pipeline.prepare("Привет! Это я, Элли. Что у тебя нового?").engine,
                       "Приве́т! Э́то я, Э́лли. Что у тебя́ но́вого?")
        XCTAssertEqual(try pipeline.prepare("Ёжик").engine, "Ёжик")
    }

    func testPinnedStressAndNameRecordOverThePlacer() throws {
        // Z9: двойник ошибается в «здорово», в «летом» (как RUAccent — «лётом») и в имени — таблица поверх него
        let placer = FormsPlacer(["здорово": "здор+ово", "что": "чт+о", "ты": "т+ы", "это": "+это",
                                  "знаешь": "зн+аешь", "привет": "прив+ет", "я": "+я", "элли": "элл+и",
                                  "купаться": "куп+аться", "летом": "л+ётом"])
        let bundled = SpeechTextPipeline(placer: placer, table: try SpeechTextTable.bundled())
        let praise = try bundled.prepare("Здорово, что ты это знаешь!")
        XCTAssertEqual(praise.engine.components(separatedBy: ",").first, "Здо́рово")
        XCTAssertEqual(try bundled.prepare("Купаться летом").engine, "Купа́ться ле́том")
        // Запись имени второго круга — только во входе движка
        let hello = try bundled.prepare("Привет, я Элли!")
        XCTAssertEqual(hello.engine, "Приве́т, я Э́льли!")
        XCTAssertEqual(hello.shown, "Привет, я Элли!")
    }

    func testPinnedWordsOverTheErrorsOfThePlacer() throws {
        // T1–T5: то, что расстановщик отдаёт на настоящих фразах Элли, — таблица поверх него
        let table = try SpeechTextTable.bundled()
        XCTAssertEqual(try spoken("н+ёбо", table), "не́бо")
        XCTAssertEqual(try spoken("Н+ёбо", table), "Не́бо")
        XCTAssertEqual(try spoken("н+ёбе", table), "не́бе")
        XCTAssertEqual(try spoken("н+ёбу", table), "не́бу")
        XCTAssertEqual(try spoken("н+ёбом", table), "не́бом")
        XCTAssertEqual(try spoken("н+ёба", table), "не́ба")
        XCTAssertEqual(try spoken("само+ё", table), "са́мое")
        XCTAssertEqual(try spoken("смел+ая", table), "сме́лая")
        XCTAssertEqual(try spoken("тв+о+ей", table), "твое́й")
        XCTAssertEqual(try spoken("Ж+ила", table), "Жила́")
    }

    func testPinnedWordsAtTheStartOfASentence() throws {
        // T6–T8: омографы на заглавной первой букве: строчными эти слова модель читает верно
        let table = try SpeechTextTable.bundled()
        XCTAssertEqual(try spoken("К+акая", table), "Кака́я")
        XCTAssertEqual(try spoken("П+ора", table), "Пора́")
        XCTAssertEqual(try spoken("Зубк+и", table), "Зу́бки")
    }

    func testReadingRulesWithExceptions() throws {
        // Z10: таблица пакета — проверенные строки второго круга, по утверждению на строку
        let table = try SpeechTextTable.bundled()
        XCTAssertEqual(try spoken("сег+одня", table), "сево́дня")
        XCTAssertEqual(try spoken("чег+о", table), "чево́")
        XCTAssertEqual(try spoken("тог+о", table), "тово́")
        XCTAssertEqual(try spoken("всег+о", table), "всево́")
        XCTAssertEqual(try spoken("моег+о", table), "моево́")
        XCTAssertEqual(try spoken("ничег+о", table), "ничево́")  // ударение — проверить на слух (`notes`)
        XCTAssertEqual(try spoken("ег+о", table), "йиво́")  // не «ево́»: оно сдвигало ударение на первый слог
        XCTAssertEqual(try spoken("больш+ого", table), "большо́ва")
        XCTAssertEqual(try spoken("н+ового", table), "но́вова")
        XCTAssertEqual(try spoken("+этого", table), "э́това")
        XCTAssertEqual(try spoken("с+инего", table), "си́нева")
        XCTAssertEqual(try spoken("д+орого", table), "до́рога")  // синтезатор сам говорит «до́рово»
        XCTAssertEqual(try spoken("ск+учно", table), "ску́шно")
        XCTAssertEqual(try spoken("здр+авствуй", table), "здра́ствуй")
        XCTAssertEqual(try spoken("ч+естный", table), "че́сный")
        XCTAssertEqual(try spoken("сч+астье", table), "ща́стье")
        XCTAssertEqual(try spoken("м+ягкий", table), "мя́хкий")
        // Исключения — «г» остаётся, буквы те же: мутация «исключение не сработало» краснит каждую строку.
        // Не добавлены — синтезатор и так читает верно, 8 из 8: слово идёт в движок без замены.
        let kept = ["мн+ого", "немн+ого", "намн+ого", "ненамн+ого", "премн+ого", "стр+ого", "нестр+ого", "настр+ого",
                    "нед+орого", "зад+орого", "уб+ого", "пол+ого", "отл+ого", "ог+о", "огог+о", "л+его", "ди+его"]
        let plain = ["чт+о", "чт+обы", "кон+ечно", "с+олнце", "с+ердце", "пр+аздник", "гр+устный", "счит+ать",
                     "сме+ётся", "нр+авится", "куп+аться", "бо+яться", "легк+о"]
        for form in kept + plain {
            let letters = form.replacingOccurrences(of: "+", with: "")
            XCTAssertEqual(try spoken(form, table).replacingOccurrences(of: "\u{301}", with: ""), letters, form)
        }
    }

    func testMarkStaysOnTheSameVowel() throws {
        // Z11: «коне́чно» — фикстурой (второй круг строку не взял: синтезатор сам говорит «конешно»); правило,
        // меняющее число гласных, таблицу не грузит
        XCTAssertEqual(try spoken("кон+ечно", try mechanismTable()), "коне́шно")
        XCTAssertEqual(try spoken("Сег+одня", try SpeechTextTable.bundled()), "Сево́дня")
        XCTAssertThrowsError(try SpeechTextTable(words: ["конечно": "кнешн"])) {
            XCTAssertEqual($0 as? SpeechTextError, .vowels("конечно"))
        }
        XCTAssertThrowsError(try SpeechTextTable(endings: [.init(end: "ого", to: "ово", unstressed: "ов")])) {
            XCTAssertEqual($0 as? SpeechTextError, .vowels("ого"))
        }
        XCTAssertThrowsError(try SpeechTextTable(parts: ["сч": "щё"])) {
            XCTAssertEqual($0 as? SpeechTextError, .vowels("сч"))
        }
        XCTAssertThrowsError(try SpeechTextTable(stress: ["здорово": "здорова+"])) {
            XCTAssertEqual($0 as? SpeechTextError, .stress("здорово"))
        }
    }

    func testStressTransferOn500Words() throws {
        // Z11: число гласных и номер ударной до и после переписывания совпадают; знак — у слов от двух гласных без «ё»
        let words = TestLexicon.words(count: 500, seed: 42)
        for table in [try SpeechTextTable.bundled(), try mechanismTable()] {
            for form in words {
                let before = SpokenWord(plus: form)
                let after = vowelsAndMark(try spoken(form, table))
                let markable = before.vowelCount >= 2 && !form.contains(where: { "ёЁ".contains($0) })
                XCTAssertEqual(after.vowels, before.vowelCount, form)
                XCTAssertEqual(after.mark, markable ? before.stress : nil, form)
            }
        }
    }

    func testPlacerGetsTheOriginalSpelling() throws {
        // Z12: ударения ставятся до переписывания
        let placer = FormsPlacer(["я": "+я", "сегодня": "сег+одня", "рисовала": "рисов+ала", "мурку": "м+урку"])
        let text = try SpeechTextPipeline(placer: placer, table: try SpeechTextTable.bundled())
            .prepare("Я сегодня рисовала Мурку")
        XCTAssertEqual(placer.received, ["Я сегодня рисовала Мурку"])
        XCTAssertEqual(text.engine, "Я сево́дня рисова́ла Му́рку")
    }

    func testShownTextAndTraceStayWithoutChanges() throws {
        // Z13: экран и `said` получают `shown`, журнал — `trace`; меняется только вход движка
        let placer = FormsPlacer(["привет": "прив+ет", "я": "+я", "элли": "элл+и", "сегодня": "сег+одня",
                                  "здорово": "здор+ово"])
        let phrase = "Привет, я Элли! Сегодня здорово!"
        let text = try SpeechTextPipeline(placer: placer, table: try SpeechTextTable.bundled()).prepare(phrase)
        XCTAssertEqual(text.shown, phrase)
        XCTAssertEqual(text.engine, "Приве́т, я Э́льли! Сево́дня здо́рово!")
        let trace = String(bytes: try JSONEncoder().encode(text.trace), encoding: .utf8) ?? "нет следа"
        XCTAssertFalse(trace.unicodeScalars.contains { (0x400...0x4FF).contains($0.value) }, trace)
    }
}
