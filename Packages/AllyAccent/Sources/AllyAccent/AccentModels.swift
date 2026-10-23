import Foundation

/// Модели RUAccent (стык ведущего 2026-10-23; реализует V3c через `AllyOnnx`): одно `Encoding` — один вызов, softmax и
/// выбор — логика расстановщика.
public protocol AccentModels: Sendable {
    /// Логиты `[2]`; индекс 1 — «гипотеза верна».
    func omograph(_ pair: Encoding) throws -> [Float]
    /// Логиты на токен: 0 NO_YO, 1 PUNCT, 2 YO.
    func yo(_ sentence: Encoding) throws -> [[Float]]
    /// Логиты на токен: 0 NO, 1 STRESS_PRIMARY, 2 STRESS_SECONDARY.
    func accent(_ word: Encoding) throws -> [[Float]]
}

/// Токенизаторы, как их зовёт логика; входы — ровно те строки, что Python подаёт токенизаторам. В тестах — двойник с
/// записанной разметкой: файлов токенизаторов в CI нет.
public protocol AccentTokenizers: Sendable {
    func yo(_ sentence: String) throws -> Encoding
    func omograph(_ text: String, _ hypothesis: String) throws -> Encoding
    func accent(_ word: String) throws -> Encoding
}

/// Токенизаторы V3a за протоколом логики.
public struct RuAccentTokenizers: AccentTokenizers {
    let wordPiece: WordPieceTokenizer
    let bpe: ByteLevelBPETokenizer
    let char: CharTokenizer

    public init(wordPiece: WordPieceTokenizer, bpe: ByteLevelBPETokenizer, char: CharTokenizer) {
        (self.wordPiece, self.bpe, self.char) = (wordPiece, bpe, char)
    }

    public func yo(_ sentence: String) -> Encoding { wordPiece.encode(sentence) }

    public func omograph(_ text: String, _ hypothesis: String) -> Encoding { bpe.encode(text, pair: hypothesis) }

    public func accent(_ word: String) -> Encoding { char.encode(word) }
}

/// Отказ расстановщика: выход модели не той формы, что ждёт логика (Python здесь упал бы).
public enum AccentError: Error, Equatable {
    case shape(model: String)
}

/// Счёт как у numpy в Float: softmax со сдвигом на максимум, сумма строки по порядку, argmax — первый максимум.
enum AccentMath {
    static func softmax(_ row: [Float], shift: Float? = nil) -> [Float] {
        let top = shift ?? row.max() ?? 0
        let exps = row.map { exp($0 - top) }
        let total = exps.reduce(0, +)
        return exps.map { $0 / total }
    }

    static func argmax(_ row: [Float]) -> Int {
        row.indices.max { row[$0] < row[$1] } ?? 0
    }
}
