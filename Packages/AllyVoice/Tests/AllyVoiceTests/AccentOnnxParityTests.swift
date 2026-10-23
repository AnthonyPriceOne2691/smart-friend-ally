import AllyAccent
import AllyVoice
import XCTest

/// Z18 спеки серии голоса (переподписан родителем 2026-10-23): логиты моделей RUAccent на ORT 1.28.0 (`AllyOnnx`)
/// бит в бит равны onnxruntime 1.28.0 на Python; против onnxruntime 1.31 — те же решения на всех 804 вызовах и разница
/// логитов ≤ 0,2. Токены фиксированы — id каждого вызова модели, записанного в конвейере Python на 163 позициях
/// (`~/models/tts/ruaccent-parity`, скрипт стенда `record_accent_parity.py`, режим `--relog` для 1.28.0).
final class AccentOnnxParityTests: XCTestCase {
    func testLogitsBitExactWithSameOrtAndSameDecisionsAsNewer() throws {
        // Z18: бит в бит с 1.28.0; против 1.31 — те же решения, разница ≤ 0,2
        let models = try AccentFixtures.models()
        let newer = try Fixtures.jsonLines(AccentFixtures.pipeline()).filter { $0["model"] != nil }
        let same = try Fixtures.jsonLines(AccentFixtures.parity.appendingPathComponent("logits_ort1.28.0.jsonl"))
        XCTAssertEqual([newer.count, same.count], [804, 804])
        var worst: Float = 0
        for (call, exact) in zip(newer, same) {
            let model = call["model"] as? String ?? ""
            let got = try AccentFixtures.run(models, model, ids: (call["ids"] as? [NSNumber] ?? []).map(\.intValue))
            let want = AccentFixtures.rows(call["logits_single"] ?? call["logits"])
            XCTAssertEqual(got, AccentFixtures.rows(exact["logits"]), "1.28.0 \(model): \(call["text"] ?? "")")
            let decide = { (rows: [[Float]]) in rows.map { AccentFixtures.decision(model, $0) } }
            XCTAssertEqual(decide(got), decide(want), "1.31 \(model): \(call["text"] ?? "")")
            worst = max(worst, zip(got.joined(), want.joined()).map { abs($0 - $1) }.max() ?? .infinity)
        }
        Fixtures.log("Z18: вызовов \(newer.count), разница с onnxruntime 1.31 — до \(worst)")
        XCTAssertLessThanOrEqual(worst, 0.2)
    }
}

/// Модели и эталоны RUAccent на Mac — вне git (L47: путь в лог, без файлов — пропуск с причиной).
enum AccentFixtures {
    static let nn = Fixtures.home.appendingPathComponent("models/tts/ruaccent/nn")
    static let parity = Fixtures.home.appendingPathComponent("models/tts/ruaccent-parity")

    static func models() throws -> RUAccentModels {
        let omograph = nn.appendingPathComponent("nn_omograph/turbo3.1-int8/turbo31_int8.onnx")
        guard FileManager.default.fileExists(atPath: omograph.path) else {
            throw XCTSkip("нет моделей RUAccent в \(nn.path) — проверка не выполнена")
        }
        Fixtures.log("модели: \(nn.path)")
        return try RUAccentModels(omograph: omograph,
                                  yo: nn.appendingPathComponent("nn_yo_homograph_resolver/model.onnx"),
                                  accent: nn.appendingPathComponent("nn_accent/model.onnx"))
    }

    /// Расстановщик целиком — один на прогон: словари (≈ 11 МБ JSON) и модели грузятся раз.
    nonisolated(unsafe) static var shared: RuAccentPlacer?

    static func placer() throws -> RuAccentPlacer {
        if let shared { return shared }
        _ = try models()
        let made = try RUAccentVoice.placer(nn: nn, dictionaries: dictionaries)
        shared = made
        return made
    }

    static let dictionaries = Fixtures.home.appendingPathComponent("models/tts/ruaccent/dictionary-json")

    static func pipeline() throws -> URL {
        let file = parity.appendingPathComponent("pipeline.jsonl")
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw XCTSkip("нет записи конвейера Python в \(parity.path) — паритет не проверен")
        }
        Fixtures.log("эталоны: \(file.path)")
        return file
    }

    /// Логиты из JSON строками: у омографов — одна строка `[2]`, у «ё» и модели слов — строка на токен.
    static func rows(_ value: Any?) -> [[Float]] {
        if let row = value as? [NSNumber] { return [row.map(\.floatValue)] }
        return (value as? [[NSNumber]] ?? []).map { $0.map(\.floatValue) }
    }

    static func run(_ models: RUAccentModels, _ model: String, ids: [Int]) throws -> [[Float]] {
        let input = Encoding(ids: ids, tokens: [], typeIds: Array(repeating: 0, count: ids.count))
        switch model {
        case "omograph": return [try models.omograph(input)]
        case "yo": return try models.yo(input)
        default: return try models.accent(input)
        }
    }

    /// Решение по строке логитов, как у Python: омографы и «ё» — argmax; модель слов — ударение, если метка
    /// STRESS_PRIMARY и её вероятность ≥ 0,55 (`render_stress`).
    static func decision(_ model: String, _ row: [Float]) -> Int {
        let best = row.indices.max { row[$0] < row[$1] } ?? 0
        guard model == "accent" else { return best }
        let top = row.max() ?? 0
        let total = row.map { exp($0 - top) }.reduce(0, +)
        return best == 1 && 1 / total >= 0.55 ? 1 : 0
    }
}
