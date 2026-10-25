import AllyAccent
import AllyVoice
import XCTest

/// Z14–Z17 спеки серии голоса: собранный расстановщик (токенизаторы V3a, логика V3b, модели V3c) против записи
/// конвейера Python на позициях стенда (`~/models/tts/ruaccent-parity/pipeline.jsonl`).
final class AccentParityTests: XCTestCase {
    private func positions() throws -> [[String: Any]] {
        try Fixtures.jsonLines(AccentFixtures.pipeline()).filter { $0["text_in"] != nil }
    }

    private func same(_ placer: RuAccentPlacer, _ rows: [[String: Any]]) throws -> [String] {
        try rows.compactMap { row in
            let text = row["text_in"] as? String ?? "", want = row["text_out"] as? String ?? ""
            let got = try placer.place(text)
            return got == want ? nil : "\(row["pos"] ?? ""): \(got) | Python: \(want)"
        }
    }

    func testStandPositionsMatchPython() throws {
        // Z14: 163 позиции стенда — те же знаки минимум в 162 (цель 163); 9 фраз страницы — те же, что у Python
        let placer = try AccentFixtures.placer()
        let rows = try positions()
        let stand = rows.filter { ($0["pos"] as? Int).map { $0 < 1000 } ?? false }
        let page = rows.filter { ($0["pos"] as? Int).map { $0 >= 1000 } ?? false }
        XCTAssertEqual([stand.count, page.count], [163, 9])
        let misses = try same(placer, stand)
        Fixtures.log("Z14: совпало \(stand.count - misses.count) из \(stand.count); расхождения: \(misses)")
        XCTAssertLessThanOrEqual(misses.count, 1)
        XCTAssertEqual(try same(placer, page), [])
    }

    func testYoGroupMatchesPython() throws {
        // Z15: группа «ё нет во входе» (категория Y стенда) — 8 из 8, как у Python
        let rows = try positions().filter { $0["cat"] as? String == "Y" }
        XCTAssertEqual(rows.count, 8)
        XCTAssertEqual(try same(try AccentFixtures.placer(), rows), [])
    }

    func testUnknownWordGetsTheWordModelStress() throws {
        // Z16: незнакомое слово → ударение модели слов
        let out = try AccentFixtures.placer().place("аксолотлик")
        XCTAssertEqual(out.replacingOccurrences(of: "+о", with: "о\u{301}"), "аксоло́тлик")
    }
}
