import Foundation

/// Омографы RUAccent (`_process_omographs`, `classify`): на каждую гипотезу — фраза с `<w>…</w>` вокруг омографа.
/// У всех омографов фразы чётное число гипотез — пары по порядку и «верно» после softmax по всему пакету; хоть у одного
/// нечётное — группы `group_words`, softmax на вызов, фраза группы — фраза её первой гипотезы. Ответы ложатся на
/// найденные омографы по порядку, даже когда их число не совпало.
struct OmographDecision {
    /// `OmographModel.special_words` RUAccent 1.5.8.3: группы этих слов больше трёх режутся тройками.
    static let special: Set<String> = [
        "балчуга", "вертела", "волоки", "волоку", "воронью", "выбродите", "вывозите", "выносите", "выноситесь",
        "выходите", "железы", "начала", "округа", "перепела", "развитая", "развитого", "развитое", "развитой",
        "развитом", "развитому", "развитою", "развитую", "развитые", "развитым", "развитыми", "развитых", "сторожа",
        "сторожи", "сторожу", "удало", "начался", "началась", "началось", "бутиках", "ожила", "создало", "коротки",
        "проклята", "роженица", "роженицы", "рожениц", "роженице", "роженицам", "роженицу", "роженицей", "роженицею",
        "роженицами", "роженицах", "пристава", "приставов", "приставам", "приставами", "приставах", "пережитое",
        "пережитого", "пережитые", "пережитых", "пережитому", "пережитым", "пережитыми", "пережитом", "нипоняла"
    ]

    let dictionaries: AccentDictionaries
    let tokenizers: any AccentTokenizers
    let models: any AccentModels

    func apply(_ words: [String]) throws -> [String] {
        var texts: [String] = [], hypotheses: [String] = [], positions: [Int] = [], even = true
        for (index, word) in words.enumerated() {
            guard let variants = dictionaries.omographs[word], !variants.isEmpty else { continue }
            var marked = words
            marked[index] = " <w>" + word + "</w> "
            let text = Self.preprocess(AccentText.deleteSpacesBeforePunc(marked.joined(separator: " ")))
            texts += Array(repeating: text, count: variants.count)
            hypotheses += variants
            positions.append(index)
            even = even && variants.count % 2 == 0
        }
        guard !positions.isEmpty else { return words }
        let choices = even ? try batched(texts, hypotheses) : try oneByOne(texts, hypotheses)
        var out = words
        for (index, choice) in zip(positions, choices) {
            out[index] = choice
        }
        return out
    }

    /// Пакет: softmax по всем логитам пакета, в каждой паре — гипотеза с большим «верно», при равенстве первая.
    private func batched(_ texts: [String], _ hypotheses: [String]) throws -> [String] {
        let logits = try zip(texts, hypotheses).map { try truth(models.omograph(tokenizers.omograph($0, $1))) }
        let top = logits.joined().max() ?? 0
        let total = logits.joined().map { exp($0 - top) }.reduce(0, +)
        let probs = logits.map { exp($0[1] - top) / total }
        return stride(from: 0, to: hypotheses.count - 1, by: 2).map {
            probs[$0] >= probs[$0 + 1] ? hypotheses[$0] : hypotheses[$0 + 1]
        }
    }

    /// По одной: группы `group_words`, в группе — первая гипотеза с наибольшим «верно».
    private func oneByOne(_ texts: [String], _ hypotheses: [String]) throws -> [String] {
        var start = 0, out: [String] = []
        for length in Self.groups(hypotheses) {
            let probs = try (start..<start + length).map {
                AccentMath.softmax(try truth(models.omograph(tokenizers.omograph(texts[start], hypotheses[$0]))))[1]
            }
            out.append(hypotheses[start + AccentMath.argmax(probs)])
            start += length
        }
        return out
    }

    private func truth(_ logits: [Float]) throws -> [Float] {
        guard logits.count == 2 else { throw AccentError.shape(model: "omograph") }
        return logits
    }

    /// `group_words`: подряд идущие гипотезы одной основы (без «+»); особое слово больше трёх — тройками, чётная
    /// группа больше трёх — парами, остальное — целиком. Ответ — длины групп по порядку.
    static func groups(_ hypotheses: [String]) -> [Int] {
        var lengths: [Int] = [], start = 0
        while start < hypotheses.count {
            let base = hypotheses[start].replacing("+", with: "")
            var end = start + 1
            while end < hypotheses.count, hypotheses[end].replacing("+", with: "") == base {
                end += 1
            }
            let count = end - start
            let size = count > 3 && special.contains(base) ? 3 : count > 3 && count % 2 == 0 ? 2 : count
            lengths += stride(from: 0, to: count, by: size).map { min(size, count - $0) }
            start = end
        }
        return lengths
    }

    /// `classify`: пробельные перед «,.?!:;…» уходят.
    static func preprocess(_ text: String) -> String {
        var out: [Unicode.Scalar] = [], run: [Unicode.Scalar] = []
        for scalar in text.unicodeScalars {
            if AccentText.isSpace(scalar) {
                run.append(scalar)
                continue
            }
            if !",.?!:;…".unicodeScalars.contains(scalar) {
                out += run
            }
            run = []
            out.append(scalar)
        }
        return AccentText.string(out + run)
    }
}
