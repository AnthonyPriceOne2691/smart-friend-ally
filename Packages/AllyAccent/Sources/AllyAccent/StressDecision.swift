import Foundation

/// Ударения RUAccent tiny mode (`_process_accent`): слово с «+» (омограф) — как есть; слово словаря `accents_nn` — «+»
/// словаря на исходное написание; слова нет в словаре, в нём нет пунктуации и гласных больше одной — модель слов.
struct StressDecision {
    static let vowels = Set("аеёиоуыэюяАЕЁИОУЫЭЮЯ".unicodeScalars)
    /// `has_punctuation`: `string.punctuation` Python.
    static let punctuation = Set(##"!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~"##.unicodeScalars)
    /// Порог оценки модели слов (`render_stress`).
    static let threshold = 0.55

    let dictionaries: AccentDictionaries
    let tokenizers: any AccentTokenizers
    let models: any AccentModels

    func apply(_ words: [String]) throws -> [String] {
        try words.map { word in
            guard !word.unicodeScalars.contains("+") else { return word }
            let key = word.lowercased()
            let stressed = dictionaries.accents[key] ?? key
            let plain = !key.unicodeScalars.contains(where: Self.punctuation.contains)
            if stressed == key, plain, key.unicodeScalars.filter(Self.vowels.contains).count > 1 {
                return try model(word)
            }
            return Self.transfer(stressed, onto: word)
        }
    }

    /// Перенос «+» словаря на исходное написание — цикл Python как есть: со второго «+» позиция съезжает.
    static func transfer(_ stressed: String, onto word: String) -> String {
        let letters = Array(word.unicodeScalars)
        var fixed = letters
        let marks = stressed.unicodeScalars.enumerated().filter { $0.element == "+" }.map(\.offset)
        for (shift, start) in marks.enumerated() {
            fixed = Array(fixed.prefix(start + shift)) + ["+"] + Array(letters.dropFirst(start))
        }
        return AccentText.string(fixed)
    }

    /// Модель слов (`put_accent`, `render_stress`): метка позиции — argmax логитов, оценка — максимум softmax со
    /// сдвигом на общий максимум всех логитов; «+» — перед буквой с номером позиции минус один при STRESS_PRIMARY и
    /// оценке от 0,55. Позиция 0 ([bos]) метит последнюю букву, как индекс −1 в Python; за концом слова знака нет —
    /// там Python падает.
    private func model(_ word: String) throws -> String {
        let logits = try models.accent(tokenizers.accent(word.lowercased()))
        guard let top = logits.joined().max(), logits.allSatisfy({ $0.count == 3 }) else {
            throw AccentError.shape(model: "accent")
        }
        var letters = word.unicodeScalars.map { String($0) }
        for (position, row) in logits.enumerated() {
            let score = AccentMath.softmax(row, shift: top).max() ?? 0
            let index = position == 0 ? letters.count - 1 : position - 1
            guard AccentMath.argmax(row) == 1, Double(score) >= Self.threshold, letters.indices.contains(index) else {
                continue
            }
            letters[index] = "+" + letters[index]
        }
        return letters.joined()
    }
}
