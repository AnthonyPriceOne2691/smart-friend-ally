import XCTest
@testable import Discipline

/// Rule ids of the contract, in pipeline order.
let ruleIDs = ["placeholder", "markup", "emoji", "symbols", "latin", "digits", "phone_like", "endearment"]

/// A probe for `rule`: `input` must come out as `want` (the input itself when `want` is nil).
struct Probe {
    let rule: String
    let input: String
    let want: String

    init(_ rule: String, _ input: String, _ want: String? = nil) {
        self.rule = rule
        self.input = input
        self.want = want ?? input
    }
}

/// Replies that break a rule: the reference self-tests (output_filter.PROBES, judge_sheet.selftest) and spec C2/C3.
let violators = [
    Probe("placeholder", "Привет, [Имя девочки]! Как дела?", "Привет! Как дела?"),
    Probe("placeholder", "Ой, [Имя девочки], не плачь!", "Ой, не плачь!"),
    Probe("markup", "**Привет** (улыбается) подружка!", "Привет подружка!"),
    Probe("markup", "Смотри:\n1. Возьми кубик.\n2. Поставь его.", "Смотри: Возьми кубик. Поставь его."),
    Probe("markup", "<think>надо ответить</think>Привет, подружка!", "Привет, подружка!"),
    Probe("markup", "Посмотри на www.zoo.ru вместе с мамой.", "Посмотри на вместе с мамой."),
    Probe("markup", "## Сказка\n> Жил-был _ёжик_", "Сказка. Жил-был ёжик."),
    Probe("emoji", "Привет! 🐰✨ Я тебя <3", "Привет! Я тебя"),
    Probe("symbols", "2 + 3 = 5.", "Два плюс три будет пять."),
    Probe("symbols", "Это **cat**, 2+3=5 😺", "Это кэт, два плюс три будет пять"),
    Probe("symbols", "7 - 2 будет 5, а 3×4 и 8/2 — это 12 и 4. Скидка 10%, приз № 1!",
          "Семь минус два будет пять, а три умножить на четыре и восемь разделить на два — это двенадцать и четыре. "
          + "Скидка десять процентов , приз номер один!"),
    Probe("symbols", "Кот & пёс, на улице 5° и @ дома.", "Кот и пёс, на улице пять градусов и дома."),
    Probe("latin", "Кошка по-английски будет cat.", "Кошка по-английски будет кэт."),
    Probe("latin", "Это supercalifragilistic слово!", "Это слово!"),
    Probe("latin", "Вот это да, ты угаdala правильно.", "Вот это да, ты угадала правильно."),
    Probe("latin", "Это DimaTorzok сказал, Hello!", "Это Дима Торзок сказал, Хэллоу!"),
    Probe("latin", "Давай с\u{70}азу играть!", "Давай сразу играть!"),
    Probe("digits", "У меня 21 кубик и 1002 бусинки.", "У меня двадцать один кубик и тысяча два бусинки."),
    Probe("digits", "Возьми 2,3 литра, а не 3, 4.", "Возьми два и три литра, а не три, четыре."),
    Probe("digits", "В 10:30 съели 2,5 яблока на 3-м этаже, а в 2024 году — 12000.",
          "В десять тридцать съели два и пять яблока на три этаже, а в две тысячи двадцать четыре году — ⟦PHONE⟧ ."),
    Probe("phone_like", "Мамин номер 89161234567. Молодец!", "Мамин номер ⟦PHONE⟧ . Молодец!"),
    Probe("phone_like", "Звони 8 (916) 123-45-67!", "Звони ⟦PHONE⟧ !"),
    Probe("phone_like", "8 999 123 45 67", "⟦PHONE⟧"),
    Probe("phone_like", "+7 (999) 123-45-67", "Плюс ⟦PHONE⟧"),
    Probe("phone_like", "7 7 7 1 2", "⟦PHONE⟧"),
    Probe("endearment", "Ой, милая, нельзя совсем!", "Ой, нельзя совсем!"),
    Probe("endearment", "Привет, Солнышко! Я сегодня играла.", "Привет! Я сегодня играла."),
    Probe("endearment", "А ты что делала, мой зайчик?", "А ты что делала?"),
    Probe("endearment", "Милая, не плачь. Позови маму!", "Не плачь. Позови маму!"),
    Probe("endearment", "Ой, какая ты умница, моя солнышко! Листики меняют цвет.",
          "Ой, какая ты умница! Листики меняют цвет."),
    Probe("endearment", "Ты моя хорошая! Давай играть.", "Давай играть."),
    Probe("endearment", "Спасибо тебе моя радость!", "Спасибо тебе!"),
    Probe("endearment", "Спокойной ночи моя радость!", "Спокойной ночи!"),
    Probe("endearment", "Ты такая весёлая, мое солнышко.", "Ты такая весёлая.")
]

/// Tricky clean probes: look like a breach of `rule`, but the rule must stay silent.
let cleans = [
    Probe("placeholder", "Давай поиграем в «Угадай животное»?"),
    Probe("markup", "Пять — это много, а Маша - молодец!"),
    Probe("emoji", "Ну… «Ёжик» колючий, правда?"),
    Probe("symbols", "Два минус один будет один."),
    Probe("latin", "Кошка по-английски будет кэт."),
    Probe("digits", "Пять, четыре, три, два, один, ноль, пуск!"),
    Probe("phone_like", "Считаем: 5 4 3 2 1, пуск!", "Считаем: пять четыре три два один, пуск!"),
    Probe("phone_like", "1, 2, 3, 4, 5", "Один, два, три, четыре, пять"),
    Probe("endearment", "Солнышко светит, а котик спит."),
    Probe("endearment", "Какая милая собачка!"),
    Probe("endearment", "Ты моя хорошая подружка!"),
    Probe("endearment", "Хорошая погода сегодня!"),
    Probe("endearment", "Собачка такая милая!"),
    Probe("endearment", "Ты очень милая!"),
    Probe("endearment", "Посмотри на солнышко!")
]

/// What went wrong with the probes of `rules`: a wrong text, a silent violator, a clean probe that fired.
func probeFailures(of rules: Set<String>) -> [String] {
    var failures: [String] = []
    for probe in violators + cleans where rules.contains(probe.rule) {
        let result = Repair.apply(probe.input)
        let fired = result.actions.contains { $0.rule == probe.rule }
        let isViolator = violators.contains { $0.input == probe.input }
        if result.text != probe.want || fired != isViolator {
            failures.append("\(probe.rule) fired=\(fired): «\(probe.input)» → «\(result.text)», want «\(probe.want)»")
        }
    }
    return failures
}

final class ProbeTests: XCTestCase {
    func testEndearmentAndPlaceholderProbes() {  // C2
        XCTAssertEqual(probeFailures(of: ["endearment", "placeholder"]), [])
    }

    func testMarkupEmojiSymbolsLatinDigitsPhoneProbes() {  // C3
        XCTAssertEqual(probeFailures(of: ["markup", "emoji", "symbols", "latin", "digits", "phone_like"]), [])
    }

    /// Ablation, the mutation gate's role: with a rule off, one of its probes comes out differently. `phone_like` is
    /// a mark: off, its action goes and the text stays.
    func testEveryRuleSwitchedOffChangesAProbe() {  // C4
        XCTAssertEqual(Rule.allCases.map(\.rawValue), ruleIDs)
        let idle = ruleIDs.filter { rule in
            !violators.contains { probe in
                guard probe.rule == rule else { return false }
                let full = Repair.apply(probe.input), ablated = Repair.apply(probe.input, disabled: [rule])
                guard rule == "phone_like" else { return ablated.text != full.text }
                return ablated.text == full.text && ablated != full && !ablated.actions.contains { $0.rule == rule }
            }
        }
        XCTAssertEqual(idle, [], "switching these rules off changes none of their probes")
    }

    /// Edges the corpus lacks: numbers past the reference's reach, and stress marks, which are not word characters
    /// in Python (`\b` falls before them; ICU's `\w` would take them).
    func testEdgesTheCorpusLacks() {  // C3
        XCTAssertEqual(Rules.shared.numberWords("0021"), "двадцать один")
        XCTAssertEqual(Rules.shared.numberWords("21000"), "двадцать одна тысяча")
        XCTAssertEqual(Rules.shared.numberWords("1234567"), "один два три четыре пять шесть семь")
        XCTAssertEqual(Repair.apply("Ура 12345 раз!", disabled: ["phone_like"]).text, "Ура ⟦PHONE⟧ раз!")
        XCTAssertEqual(Repair.apply("Смотри сайт ёжик.рф\u{301} и 2-я\u{301} глава").text,
                       "Смотри сайт \u{301} и два\u{301} глава")
    }
}
