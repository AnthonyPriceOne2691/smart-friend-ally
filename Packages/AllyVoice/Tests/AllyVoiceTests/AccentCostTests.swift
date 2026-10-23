import AllyAccent
import AllyVoice
import XCTest

/// Z17 спеки серии голоса: цена расстановщика на Mac — медиана ≤ 40 мс на фразу 163 позиций стенда, прирост отпечатка
/// (`phys_footprint`, L22) ≤ 120 МБ с моделью омографов int8 в external data.
final class AccentCostTests: XCTestCase {
    func testPhraseTimeAndFootprintOnMac() throws {
        // Z17: время и отпечаток — в лог; 2 потока, без spin
        _ = try AccentFixtures.placer()  // пропуск, если файлов нет
        let phrases = try Fixtures.jsonLines(AccentFixtures.pipeline())
            .filter { ($0["pos"] as? Int).map { $0 < 1000 } ?? false }.compactMap { $0["text_in"] as? String }
        let before = Footprint.read()
        let placer = try RUAccentVoice.placer(nn: AccentFixtures.nn, dictionaries: AccentFixtures.dictionaries)
        let sampler = FootprintSampler()
        sampler.start()
        _ = try placer.place("Привет!")
        var times: [Double] = []
        for phrase in phrases {
            let begin = Date()
            _ = try placer.place(phrase)
            times.append(Date().timeIntervalSince(begin))
        }
        let peak = max(sampler.stop(), Footprint.read().now)
        let median = times.sorted()[times.count / 2]
        Fixtures.log(String(format: "Z17: фраз %d, медиана %.1f мс (макс %.1f), отпечаток +%.1f МБ, load average %.1f",
                            times.count, median * 1000, (times.max() ?? 0) * 1000, peak - before.now,
                            SupertonicEngineTests.loadAverage()))
        XCTAssertLessThanOrEqual(median, 0.040)
        XCTAssertLessThanOrEqual(peak - before.now, 120)
    }
}
