/// Слово для голоса: буквы и номер ударной гласной, считая с нуля; `nil` — ударение неизвестно. Правила чтения меняют
/// буквы, не меняя числа гласных, поэтому номер ударной переносится на ту же по счёту гласную (Z11).
struct SpokenWord: Equatable {
    static let vowels: Set<Character> = Set("аеёиоуыэюяАЕЁИОУЫЭЮЯ")
    static let acute = "\u{301}"

    var letters: String
    var stress: Int?

    var vowelCount: Int { letters.filter(Self.vowels.contains).count }

    /// Буквы со знаком U+0301 после ударной гласной. Без знака — слово в один слог, слово с «ё» и слово без ударения.
    var marked: String {
        guard let stress, vowelCount >= 2, !letters.contains(where: { "ёЁ".contains($0) }) else { return letters }
        var out = ""
        var vowel = 0
        for char in letters {
            out.append(char)
            guard Self.vowels.contains(char) else { continue }
            if vowel == stress { out += Self.acute }
            vowel += 1
        }
        return out
    }

    /// Регистр первой буквы `source` — первой букве `text`: «Сегодня» → «Севодня».
    static func cased(_ text: String, like source: String) -> String {
        guard source.first?.isUppercase == true, let head = text.first else { return text }
        return head.uppercased() + text.dropFirst()
    }
}

extension SpokenWord {
    /// Слово в «+»-форме расстановщика: «+» перед гласной отмечает ударную, в счёт идёт первый.
    init(plus form: String) {
        var letters = ""
        var stress: Int?
        var vowel = 0
        var marked = false
        for char in form {
            if char == "+" {
                marked = true
                continue
            }
            if Self.vowels.contains(char) {
                if marked, stress == nil { stress = vowel }
                vowel += 1
            }
            marked = false
            letters.append(char)
        }
        self.init(letters: letters, stress: stress)
    }
}
