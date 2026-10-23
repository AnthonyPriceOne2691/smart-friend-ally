import Foundation
import XCTest
@testable import AllyAccent

/// Доля V3b в примерах Z14–Z16 спеки серии голоса (коммит 68202f0): логика RUAccent на Swift повторяет текст Python
/// (RUAccent 1.5.8.3, turbo3.1 int8, tiny mode, «поняла») по записанным выходам моделей. Ожидание — текст, который
/// вернул Python, а не автор: запись стенда, пробы причуд на настоящем конвейере Python с заданными логитами и sha256
/// источников — в `Fixtures/accent_replay.json`. Двойник отказывает на входе, которого Python не подавал.
final class RuAccentReplayTests: XCTestCase {
    /// Расхождения повтора: «позиция: получено ≠ ожидалось» — и позиции, где логика сделала не все вызовы Python.
    private func mismatches(_ items: [Replay.Item]) throws -> [String] {
        let replay = try Replay.shared.get()
        return try items.compactMap { item in
            let twin = ReplayTwin(item.calls)
            let dictionaries = try replay.dictionaries(for: item)
            let placer = RuAccentPlacer(dictionaries: dictionaries, tokenizers: twin, models: twin)
            do {
                let got = try placer.place(item.textIn)
                let same = got == item.textOut && twin.unused == 0
                return same ? nil : "\(item.pos): \(got) ≠ \(item.textOut), не сделано вызовов: \(twin.unused)"
            } catch {
                return "\(item.pos): \(error)"
            }
        }
    }

    /// Проба причуды: текст Python из записи и расхождения Swift с ним.
    private func probe(_ name: String) throws -> (python: String, mismatches: [String]) {
        let item = try XCTUnwrap(try Replay.shared.get().probes.first { $0.pos == name })
        return (item.textOut, try mismatches([item]))
    }

    func testStandPhrasesMatchPython() throws {
        // Z14: 163 позиции стенда без имён — текст Python в 163 из 163; 9 фраз страницы (несколько предложений) — тоже
        let positions = try Replay.shared.get().positions
        let stand = positions.filter { $0.cat != "page" && $0.cat != "Z16" }
        let page = positions.filter { $0.cat == "page" }
        XCTAssertEqual(stand.count, 163)
        XCTAssertEqual(try mismatches(stand), [])
        XCTAssertEqual(page.count, 9)
        XCTAssertEqual(try mismatches(page), [])
    }

    func testNoYoInInputGroup() throws {
        // Z15: группа «ё нет во входе» того же повтора — 8 из 8, как у Python
        let group = try Replay.shared.get().positions.filter { $0.cat == "Y" }
        XCTAssertEqual(group.count, 8)
        XCTAssertEqual(try mismatches(group), [])
    }

    func testAxolotlByWordModel() throws {
        // Z16: «аксолотлик» с записанными логитами модели слов — «аксол+отлик», как у Python
        let item = try XCTUnwrap(try Replay.shared.get().positions.first { $0.pos == "Z16" })
        XCTAssertEqual(item.textOut, "аксол+отлик")
        XCTAssertEqual(try mismatches([item]), [])
    }

    func testOddHypothesisCountSwitchesToOneByOne() throws {
        // Z14, проба причуды: у «начала» три гипотезы — путь по одной берёт третью, парами её бы не было
        let odd = try probe("odd")
        XCTAssertEqual(odd.python, "Мы уж+е начал+а.")
        XCTAssertEqual(odd.mismatches, [])
    }

    func testSpecialWordInTriplesEvenGroupInPairs() throws {
        // Z14, проба причуды: «начала» дважды — шесть гипотез тройками; «мука» дважды при нечётном соседе — парами
        let triples = try probe("triples"), pairs = try probe("pairs")
        XCTAssertEqual(triples.python, "Я начал+а, ты начал+а.")
        XCTAssertEqual(triples.mismatches, [])
        XCTAssertEqual(pairs.python, "Там мук+а и мук+а начал+а.")
        XCTAssertEqual(pairs.mismatches, [])
    }

    func testFixCapitalKeepsTargetOfOtherLength() throws {
        // Z14, проба причуды: «Еж» → «ёжик» другой длины — цель как есть; «Ежик» → «Ёжик» — регистр исходного
        let capital = try probe("capital")
        XCTAssertEqual(capital.python, "ёжик и Ёжик спят.")
        XCTAssertEqual(capital.mismatches, [])
    }

    func testSeveralPlusesShiftLikePython() throws {
        // Z14, проба причуды: «м+ол+око» словаря на «Молоко» — второй «+» съезжает на букву, как в цикле Python
        let transfer = try probe("transfer")
        XCTAssertEqual(transfer.python, "М+оло+ко.")
        XCTAssertEqual(transfer.mismatches, [])
    }

    func testModelMarkAtPositionZeroLandsOnLastLetter() throws {
        // Z14, проба причуды: STRESS_PRIMARY модели слов на [bos] — «+» перед последней буквой
        let mark = try probe("render0")
        XCTAssertEqual(mark.python, "Кошк+а.")
        XCTAssertEqual(mark.mismatches, [])
    }

    func testLogicCallsV3aTokenizers() throws {
        // Z14: адаптер отдаёт логике выход токенизаторов V3a как есть (игрушечные токенизаторы, обученные HF)
        let fixtures = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let wordPiece = try WordPieceTokenizer(tokenizerJSON: fixtures.appendingPathComponent("wordpiece.json"))
        let bpe = try ByteLevelBPETokenizer(tokenizerJSON: fixtures.appendingPathComponent("bpe.json"))
        let char = try CharTokenizer(vocab: fixtures.appendingPathComponent("char-vocab.txt"))
        let tokenizers = RuAccentTokenizers(wordPiece: wordPiece, bpe: bpe, char: char)
        XCTAssertEqual(tokenizers.yo("ты мне её покажешь?"), wordPiece.encode("ты мне её покажешь?"))
        let text = "Я <w>поняла</w>!"
        XCTAssertEqual(tokenizers.omograph(text, "понял+а"), bpe.encode(text, pair: "понял+а"))
        XCTAssertEqual(tokenizers.accent("Кошка"), char.encode("Кошка"))
    }
}
