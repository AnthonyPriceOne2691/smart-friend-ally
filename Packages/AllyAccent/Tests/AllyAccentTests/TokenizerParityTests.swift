import Foundation
import XCTest
@testable import AllyAccent

/// Z14 спеки серии голоса (часть до моделей): три токенизатора дают те же id, строки токенов и смещения, что
/// токенизаторы HF. Ожидание — из HF, а не от автора: на Linux — игрушечные токенизаторы, обученные HF
/// (`Fixtures/`, генератор `local/spike/tts-swift/scripts/make_tokenizer_toys.py`); на Mac — настоящие файлы RUAccent и
/// входы, записанные в настоящем конвейере Python на 163 позициях (`~/models/tts/ruaccent-parity`, скрипт
/// `record_accent_parity.py`). Версии: tokenizers 0.23.3, transformers 5.20.1, RUAccent 1.5.8.3.
final class TokenizerParityTests: XCTestCase {
    struct Record: Decodable {
        let tok: String
        let text: String
        let pair: String?
        let ids: [Int]
        let tokens: [String]
        let offsets: [[Int]]?
        let special: [Int]?
    }

    private func records(_ url: URL) throws -> [Record] {
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        return try lines.map { try JSONDecoder().decode(Record.self, from: Data($0.utf8)) }
    }

    /// Сверка с HF; число сверенных записей — чтобы пустой файл не прошёл молча.
    private func compare(_ rows: [Record], _ bpe: ByteLevelBPETokenizer, _ wordPiece: WordPieceTokenizer,
                         _ char: CharTokenizer) -> Int {
        // Z14: каждое поле — против записи HF
        for row in rows {
            let got = row.tok == "bpe" ? bpe.encode(row.text, pair: row.pair ?? "")
                : row.tok == "wordpiece" ? wordPiece.encode(row.text) : char.encode(row.text)
            XCTAssertEqual(got.ids, row.ids, "\(row.tok): \(row.text) | \(row.pair ?? "")")
            XCTAssertEqual(got.tokens, row.tokens, "\(row.tok): \(row.text)")
            guard row.tok == "wordpiece" else { continue }
            XCTAssertEqual(got.offsets.map { [$0.lowerBound, $0.upperBound] }, row.offsets, row.text)
            XCTAssertEqual(got.specialTokensMask, row.special?.map { $0 == 1 }, row.text)
        }
        return rows.count
    }

    func testToyTokenizersTrainedByHFMatch() throws {
        // Z14: игрушечные токенизаторы HF на входах настоящего конвейера и краевых случаях (Linux и Mac)
        let fixtures = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let rows = try records(fixtures.appendingPathComponent("expected.jsonl"))
        let bpe = try ByteLevelBPETokenizer(tokenizerJSON: fixtures.appendingPathComponent("bpe.json"))
        let wordPiece = try WordPieceTokenizer(tokenizerJSON: fixtures.appendingPathComponent("wordpiece.json"))
        let char = try CharTokenizer(vocab: fixtures.appendingPathComponent("char-vocab.txt"))
        let checked = compare(rows, bpe, wordPiece, char)
        XCTAssertEqual(checked, 81)
    }

    func testRealTokenizersMatchHFOnStandPositions() throws {
        // Z14: настоящие токенизаторы RUAccent на 163 позициях стенда, гипотезах омографов и словах модели слов
        let home = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("models/tts")
        let parity = home.appendingPathComponent("ruaccent-parity/tokenizers.jsonl")
        let nn = home.appendingPathComponent("ruaccent/nn")
        let files = FileManager.default
        guard files.fileExists(atPath: parity.path), files.fileExists(atPath: nn.path) else {
            throw XCTSkip("пропуск: нет \(parity.path) или \(nn.path) — эталоны и файлы RUAccent лежат вне git")
        }
        let checked = compare(try records(parity),
                              try ByteLevelBPETokenizer(tokenizerJSON: nn.appendingPathComponent(
                                "nn_omograph/turbo3.1/tokenizer.json")),
                              try WordPieceTokenizer(tokenizerJSON: nn.appendingPathComponent(
                                "nn_yo_homograph_resolver/tokenizer.json")),
                              try CharTokenizer(vocab: nn.appendingPathComponent("nn_accent/vocab.txt")))
        XCTAssertEqual(checked, 804)
    }
}
