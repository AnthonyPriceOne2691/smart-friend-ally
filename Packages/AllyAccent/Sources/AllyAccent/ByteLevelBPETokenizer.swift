import Foundation

/// Byte-level BPE модели омографов RUAccent (`tokenizer.json`, turbo3.1): добавленные токены — левый длиннейший
/// (как Aho–Corasick LeftmostLongest HF), остальной текст — регулярка GPT-2 без пробела в начале, байты UTF-8 — знаки
/// карты GPT-2, слияния по рангу; пара — `<s> A </s></s> B </s>` (RobertaProcessing). Смещений нет: логика омографов
/// их не просит.
public struct ByteLevelBPETokenizer: Sendable {
    struct Pair: Hashable {
        let left: String
        let right: String
    }

    let vocab: [String: Int]
    let ranks: [Pair: Int]
    let added: [String: Int]
    let longestAdded: Int
    /// Каждый добавленный токен содержит «+» или «<»: текст без них режется без поиска.
    let addedNeedMarks: Bool
    let bytes: [Character]

    public init(tokenizerJSON url: URL) throws {
        let file = try TokenizerFile.load(url)
        vocab = file.model.vocab
        let merges = (file.model.merges ?? []).enumerated().map { (Pair(left: $1.left, right: $1.right), $0) }
        ranks = Dictionary(merges) { first, _ in first }
        added = Dictionary(file.addedTokens.map { ($0.content, $0.id) }) { first, _ in first }
        longestAdded = file.addedTokens.map(\.content.unicodeScalars.count).max() ?? 0
        addedNeedMarks = file.addedTokens.allSatisfy { $0.content.contains("+") || $0.content.contains("<") }
        bytes = Self.byteMap()
    }

    public func encode(_ text: String, pair: String) -> Encoding {
        var out = Encoding()
        special("<s>", &out)
        sequence(text, &out)
        special("</s>", &out)
        special("</s>", &out)
        sequence(pair, &out)
        special("</s>", &out)
        return out
    }

    private func special(_ token: String, _ out: inout Encoding) {
        out.append(token, id: added[token] ?? vocab[token] ?? 0, offset: nil, special: true)
    }

    private func sequence(_ text: String, _ out: inout Encoding) {
        let unknown = added["<unk>"] ?? vocab["<unk>"] ?? 0
        for segment in segments(text) {
            if let id = segment.id {
                out.append(segment.text, id: id, offset: nil)
                continue
            }
            let words = #/'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+/#
            for match in segment.text.matches(of: words.matchingSemantics(.unicodeScalar)) {
                let mapped = String(String(match.output).utf8.map { bytes[Int($0)] })
                bpe(mapped).forEach { out.append($0, id: vocab[$0] ?? unknown, offset: nil) }
            }
        }
    }

    /// Текст, разрезанный на добавленные токены (с id) и куски между ними.
    private func segments(_ text: String) -> [(text: String, id: Int?)] {
        if addedNeedMarks, !text.contains("+"), !text.contains("<") { return [(text, nil)] }
        let scalars = Array(text.unicodeScalars)
        var out: [(text: String, id: Int?)] = []
        var plain = String.UnicodeScalarView()
        var index = 0
        while index < scalars.count {
            let longest = (1...max(1, min(longestAdded, scalars.count - index))).reversed().lazy
                .map { (length: $0, token: String(String.UnicodeScalarView(scalars[index..<index + $0]))) }
                .first { added[$0.token] != nil }
            guard let longest, let id = added[longest.token] else {
                plain.append(scalars[index])
                index += 1
                continue
            }
            if !plain.isEmpty { out.append((String(plain), nil)) }
            plain = String.UnicodeScalarView()
            out.append((longest.token, id))
            index += longest.length
        }
        if !plain.isEmpty { out.append((String(plain), nil)) }
        return out
    }

    /// Слияния по рангу: каждый раз — пара с наименьшим рангом, все её вхождения слева направо.
    private func bpe(_ word: String) -> [String] {
        var symbols = word.map(String.init)
        while symbols.count > 1 {
            var best: (rank: Int, pair: Pair)?
            for (left, right) in zip(symbols, symbols.dropFirst()) {
                let pair = Pair(left: left, right: right)
                if let rank = ranks[pair], rank < best?.rank ?? .max { best = (rank, pair) }
            }
            guard let pair = best?.pair else { break }
            var merged: [String] = []
            var index = 0
            while index < symbols.count {
                if index + 1 < symbols.count, symbols[index] == pair.left, symbols[index + 1] == pair.right {
                    merged.append(pair.left + pair.right)
                    index += 2
                } else {
                    merged.append(symbols[index])
                    index += 1
                }
            }
            symbols = merged
        }
        return symbols
    }

    /// Карта байтов GPT-2: печатные байты — свои знаки, остальные — U+0100 и дальше по порядку.
    static func byteMap() -> [Character] {
        var order = Array(33...126) + Array(161...172) + Array(174...255)
        var codes = order
        var extra = 0
        for byte in 0..<256 where !order.contains(byte) {
            order.append(byte)
            codes.append(256 + extra)
            extra += 1
        }
        var map = [Character](repeating: " ", count: 256)
        for (byte, code) in zip(order, codes) {
            map[byte] = Unicode.Scalar(UInt32(code)).map(Character.init) ?? " "
        }
        return map
    }
}
