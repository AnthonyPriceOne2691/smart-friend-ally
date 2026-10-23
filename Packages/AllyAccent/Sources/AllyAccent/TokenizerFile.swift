import Foundation

/// `tokenizer.json` HF — только поля, которые читают токенизаторы RUAccent.
struct TokenizerFile: Decodable {
    struct Added: Decodable {
        let content: String
        let id: Int
    }

    struct Model: Decodable {
        let vocab: [String: Int]
        let merges: [Merge]?
        let unkToken: String?
        let continuingSubwordPrefix: String?
        let maxInputCharsPerWord: Int?
    }

    /// Слияние BPE: в файле — строка «a b» (старые tokenizers) или пара строк (новые).
    struct Merge: Decodable {
        let left: String
        let right: String

        init(from decoder: Decoder) throws {
            let box = try decoder.singleValueContainer()
            let parts = (try? box.decode(String.self)).map { $0.split(separator: " ", maxSplits: 1).map(String.init) }
            let pair = try parts ?? box.decode([String].self)
            guard pair.count == 2 else {
                throw DecodingError.dataCorruptedError(in: box, debugDescription: "слияние не из двух частей")
            }
            (left, right) = (pair[0], pair[1])
        }
    }

    let model: Model
    let addedTokens: [Added]

    static func load(_ url: URL) throws -> TokenizerFile {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TokenizerFile.self, from: Data(contentsOf: url))
    }
}
