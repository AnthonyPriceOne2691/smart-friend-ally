import Foundation

/// Посимвольный токенизатор модели слов RUAccent (`nn_accent/vocab.txt`): `[bos]`, по токену на скаляр слова строчными,
/// `[eos]`; скаляра нет в словаре — `[unk]`. Как `CharTokenizer` RUAccent с `do_lower_case`.
public struct CharTokenizer: Sendable {
    let vocab: [String: Int]

    public init(vocab url: URL) throws {
        var lines = try String(contentsOf: url, encoding: .utf8).components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        vocab = Dictionary(lines.enumerated().map { ($1, $0) }) { first, _ in first }
    }

    public func encode(_ word: String) -> Encoding {
        var out = Encoding()
        out.append("[bos]", id: id(of: "[bos]"), special: true)
        for (index, scalar) in word.lowercased().unicodeScalars.enumerated() {
            let token = vocab[String(scalar)] == nil ? "[unk]" : String(scalar)
            out.append(token, id: id(of: token), offset: index..<index + 1)
        }
        out.append("[eos]", id: id(of: "[eos]"), special: true)
        return out
    }

    private func id(of token: String) -> Int { vocab[token] ?? vocab["[unk]"] ?? 1 }
}
