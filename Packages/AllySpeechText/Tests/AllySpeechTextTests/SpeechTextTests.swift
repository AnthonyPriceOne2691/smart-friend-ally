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
        // Z9: двойник ошибается в «здорово» и в имени — таблица поверх него
        let placer = FormsPlacer(["здорово": "здор+ово", "что": "чт+о", "ты": "т+ы", "это": "+это",
                                  "знаешь": "зн+аешь", "привет": "прив+ет", "я": "+я", "элли": "элл+и"])
        let bundled = SpeechTextPipeline(placer: placer, table: try SpeechTextTable.bundled())
        let praise = try bundled.prepare("Здорово, что ты это знаешь!")
        XCTAssertEqual(praise.engine.components(separatedBy: ",").first, "Здо́рово")
        XCTAssertEqual(try bundled.prepare("Привет, я Элли!").engine, "Приве́т, я Э́лли!")
        // Вымышленная запись имени — настоящую даёт второй круг образцов
        let named = SpeechTextPipeline(placer: placer, table: try mechanismTable())
        let hello = try named.prepare("Привет, я Элли!")
        XCTAssertEqual(hello.engine, "Приве́т, я Э́л-ли!")
        XCTAssertEqual(hello.shown, "Привет, я Элли!")
    }

    func testReadingRulesWithExceptions() throws {
        // Z10: таблица пакета; строки второго круга — когда ведущий передаст проверенную таблицу
        let table = try SpeechTextTable.bundled()
        let rules = ["сег+одня": "сево́дня", "н+ового": "но́вова", "ег+о": "ево́", "ничег+о": "ничево́",
                     "тог+о": "тово́", "+этого": "э́това", "всег+о": "всево́", "моег+о": "моево́", "с+инего": "си́нева"]
        for (form, voice) in rules.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(try spoken(form, table), voice, form)
        }
        // Исключения не меняются: мутация «исключение не сработало» краснит каждую строку
        let kept = ["мн+ого": "мно́го", "немн+ого": "немно́го", "стр+ого": "стро́го", "д+орого": "до́рого",
                    "уб+ого": "убо́го", "пол+ого": "поло́го", "ог+о": "ого́"]
        for (form, voice) in kept.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(try spoken(form, table), voice, form)
        }
    }

    func testMarkStaysOnTheSameVowel() throws {
        // Z11: «коне́чно» — фикстурой до строки второго круга; правило, меняющее число гласных, таблицу не грузит
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
        XCTAssertEqual(text.engine, "Приве́т, я Э́лли! Сево́дня здо́рово!")
        let trace = String(bytes: try JSONEncoder().encode(text.trace), encoding: .utf8) ?? "нет следа"
        XCTAssertFalse(trace.unicodeScalars.contains { (0x400...0x4FF).contains($0.value) }, trace)
    }
}
