@testable import AllySpeechText

/// Двойник расстановщика: «+»-формы по слову строчными, регистр первой буквы — как во входе; входы запоминает (Z12).
final class FormsPlacer: StressPlacer, @unchecked Sendable {
    let forms: [String: String]
    private(set) var received: [String] = []

    init(_ forms: [String: String]) {
        self.forms = forms
    }

    func place(_ text: String) -> String {
        received.append(text)
        return text.replacing(#/[а-яА-ЯёЁ]+/#) { match -> String in
            let word = String(match.output)
            guard let form = forms[word.lowercased()] else { return word }
            let plus = form.hasPrefix("+") ? "+" : ""
            return plus + SpokenWord.cased(String(form.dropFirst(plus.count)), like: word)
        }
    }
}

/// Двойник с одним ответом: слово в «+»-форме, как его отдал бы расстановщик.
struct FixedPlacer: StressPlacer {
    let form: String

    func place(_ text: String) -> String { form }
}

/// Генератор с зерном (LCG Кнута, старшие биты): словарь тестов воспроизводится от прогона к прогону.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state >> 11 | state << 53
    }
}

/// Словарь тестов свойства Z11: формы примеров и исключений и слова из слогов с окончаниями и словами таблиц.
/// Записей имён и закреплённых ударений в нём нет: они заменяют ударение нарочно, а свойство судит правила чтения.
enum TestLexicon {
    static let examples = ["сег+одня", "Сег+одня", "н+ового", "ег+о", "ничег+о", "тог+о", "+этого", "всег+о",
                           "моег+о", "мн+ого", "немн+ого", "стр+ого", "д+орого", "уб+ого", "пол+ого", "ог+о",
                           "кон+ечно", "прив+ет", "+это", "теб+я", "+ёжик", "М+урка", "С+оня", "Т+ёма", "с+олнце",
                           "сч+астье", "улыб+ается", "сме+яться", "н+овый"]
    static let onsets = ["", "б", "в", "г", "д", "ж", "з", "к", "л", "м", "н", "п", "р", "с", "т", "х", "ч", "ш",
                         "сч", "лн", "ст", "тс"]
    static let vowels = Array("аеиоуыэюяё")
    static let tails = ["", "", "ого", "его", "ться", "тся", "нце", "сегодня"]

    static func words(count: Int, seed: UInt64) -> [String] {
        var rng = SeededGenerator(state: seed)
        return (0..<count).map { _ in
            Bool.random(using: &rng) ? examples.randomElement(using: &rng) ?? "" : synthetic(&rng)
        }
    }

    /// Слово из 1–3 слогов и хвоста; ударение — на случайной гласной, у каждого восьмого слова неизвестно.
    static func synthetic(_ rng: inout SeededGenerator) -> String {
        let syllables = (0..<Int.random(in: 1...3, using: &rng)).map { _ in
            (onsets.randomElement(using: &rng) ?? "") + String(vowels.randomElement(using: &rng) ?? "а")
        }
        let letters = Array(syllables.joined() + (tails.randomElement(using: &rng) ?? ""))
        let places = letters.indices.filter { SpokenWord.vowels.contains(letters[$0]) }
        guard Int.random(in: 0..<8, using: &rng) > 0, let place = places.randomElement(using: &rng) else {
            return String(letters)
        }
        return String(letters[..<place]) + "+" + String(letters[place...])
    }
}

/// Гласные строки входа движка и номер гласной, за которой стоит знак U+0301.
func vowelsAndMark(_ text: String) -> (vowels: Int, mark: Int?) {
    var vowels = 0
    var mark: Int?
    for scalar in text.unicodeScalars {
        if scalar == "\u{301}" {
            mark = vowels - 1
        } else if SpokenWord.vowels.contains(Character(scalar)) {
            vowels += 1
        }
    }
    return (vowels, mark)
}
