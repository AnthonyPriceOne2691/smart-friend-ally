import Foundation

/// WordPiece модели «ё» RUAccent (`tokenizer.json`, distilbert): BertNormalizer без нижнего регистра и снятия ударений
/// (чистка управляющих, пробельные — пробел), BertPreTokenizer (пробелы режут, каждый знак пунктуации — слово), жадный
/// WordPiece с `##` (слово длиннее предела или без куска в словаре — `[UNK]`), шаблон `[CLS] A [SEP]`. Смещения — в
/// скалярах исходной строки. CJK во входе Элли нет, поэтому `handle_chinese_chars` не повторяется.
public struct WordPieceTokenizer: Sendable {
    let vocab: [String: Int]
    let unk: String
    let prefix: String
    let maxChars: Int

    public init(tokenizerJSON url: URL) throws {
        let model = try TokenizerFile.load(url).model
        vocab = model.vocab
        unk = model.unkToken ?? "[UNK]"
        prefix = model.continuingSubwordPrefix ?? "##"
        maxChars = model.maxInputCharsPerWord ?? 100
    }

    public func encode(_ text: String) -> Encoding {
        var out = Encoding()
        out.append("[CLS]", id: vocab["[CLS]"] ?? 0, special: true)
        for word in Self.words(text) {
            pieces(of: word.scalars, at: word.start, into: &out)
        }
        out.append("[SEP]", id: vocab["[SEP]"] ?? 0, special: true)
        return out
    }

    /// Слова после чистки и разбиения: скаляры и место первого из них в исходной строке.
    static func words(_ text: String) -> [(scalars: [Unicode.Scalar], start: Int)] {
        var words: [(scalars: [Unicode.Scalar], start: Int)] = []
        var current: (scalars: [Unicode.Scalar], start: Int) = ([], 0)
        func flush() {
            if !current.scalars.isEmpty { words.append(current) }
            current = ([], 0)
        }
        for (index, scalar) in text.unicodeScalars.enumerated() where !isDropped(scalar) {
            if scalar.properties.isWhitespace {
                flush()
            } else if isPunctuation(scalar) {
                flush()
                words.append(([scalar], index))
            } else {
                if current.scalars.isEmpty { current.start = index }
                current.scalars.append(scalar)
            }
        }
        flush()
        return words
    }

    private func pieces(of word: [Unicode.Scalar], at start: Int, into out: inout Encoding) {
        var found: [(token: String, range: Range<Int>)] = []
        var begin = 0
        while begin < word.count, word.count <= maxChars {
            let end = stride(from: word.count, to: begin, by: -1).first { vocab[piece(word, begin, $0)] != nil }
            guard let end else { break }
            found.append((piece(word, begin, end), start + begin..<start + end))
            begin = end
        }
        guard begin == word.count, !found.isEmpty else {
            return out.append(unk, id: vocab[unk] ?? 0, offset: start..<start + word.count)
        }
        found.forEach { out.append($0.token, id: vocab[$0.token] ?? 0, offset: $0.range) }
    }

    private func piece(_ word: [Unicode.Scalar], _ begin: Int, _ end: Int) -> String {
        (begin > 0 ? prefix : "") + String(String.UnicodeScalarView(word[begin..<end]))
    }

    /// Чистка BertNormalizer: нулевой, U+FFFD и «прочие» категории, кроме табуляции и переводов строки.
    private static func isDropped(_ scalar: Unicode.Scalar) -> Bool {
        if scalar.value == 0 || scalar.value == 0xFFFD { return true }
        if scalar == "\t" || scalar == "\n" || scalar == "\r" { return false }
        switch scalar.properties.generalCategory {
        case .control, .format, .unassigned, .privateUse, .surrogate: return true
        default: return false
        }
    }

    /// Пунктуация BertPreTokenizer: ASCII-пунктуация или категория P*.
    private static func isPunctuation(_ scalar: Unicode.Scalar) -> Bool {
        let ascii = scalar.value
        if (33...47).contains(ascii) || (58...64).contains(ascii) || (91...96).contains(ascii)
            || (123...126).contains(ascii) {
            return true
        }
        switch scalar.properties.generalCategory {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation, .initialPunctuation,
             .finalPunctuation, .otherPunctuation:
            return true
        default:
            return false
        }
    }
}
