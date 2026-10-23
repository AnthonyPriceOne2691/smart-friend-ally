import Foundation

/// «ё» RUAccent (`_process_yo`): слово — по `yo_words`; если во фразе есть «е», модель «ё» метит слова, и слово
/// с меткой YO берётся из `yo_homographs`. Метка ложится на слово RUAccent с тем же номером, даже когда слов у модели
/// больше.
struct YoDecision {
    /// `unk_token` WordPiece модели «ё»: неизвестный токен — всегда начало слова.
    static let unknown = "[UNK]"

    let dictionaries: AccentDictionaries
    let tokenizers: any AccentTokenizers
    let models: any AccentModels

    func apply(_ words: [String], sentence: String) throws -> [String] {
        let lower = sentence.lowercased()
        let labels = lower.unicodeScalars.contains("е") ? try Self.labels(tokenizers.yo(lower), models) : []
        return words.enumerated().map { index, word in
            let homograph = index < labels.count && labels[index] == 2
            let table = homograph ? dictionaries.yoHomographs : dictionaries.yoWords
            return AccentText.fixCapital(word, table[word.lowercased()] ?? word)
        }
    }

    /// Метки слов (`predict_yo_homographs`, AVERAGE): softmax на токен, служебные пропущены; подслово — токен, чья
    /// строка длиннее его куска фразы (`##`), кроме неизвестного; метка слова — первый максимум среднего.
    static func labels(_ encoding: Encoding, _ models: any AccentModels) throws -> [Int] {
        let logits = try models.yo(encoding)
        let count = encoding.ids.count
        guard logits.count == count, logits.allSatisfy({ $0.count == 3 }), encoding.tokens.count == count,
              encoding.offsets.count == count, encoding.specialTokensMask.count == count else {
            throw AccentError.shape(model: "yo")
        }
        var words: [[[Float]]] = []
        for index in 0..<count where !encoding.specialTokensMask[index] {
            let token = encoding.tokens[index]
            let subword = token != unknown && token.unicodeScalars.count != encoding.offsets[index].count
            let scores = AccentMath.softmax(logits[index])
            if subword, !words.isEmpty {
                words[words.count - 1].append(scores)
            } else {
                words.append([scores])
            }
        }
        return words.map { AccentMath.argmax(mean($0)) }
    }

    /// `np.nanmean` по токенам слова: сумма в Float, деление — в Double, как у numpy с делителем-счётчиком.
    static func mean(_ rows: [[Float]]) -> [Float] {
        (0..<3).map { label in Float(Double(rows.map { $0[label] }.reduce(0, +)) / Double(rows.count)) }
    }
}
