import AllyCore
import XCTest

let sampleRegistry = """
{"model": {"file": "gemma.gguf", "bytes": 12}, "persona": "persona.v2.4.ru.md",
 "voice": "com.apple.voice.enhanced.ru-RU.Milena", "listen_timeout": 8, "first_sentence_timeout": 10,
 "turn": {"tails": {"open": 1.8, "closed": 0.8, "counting": 2.5}, "tentative": 0.3, "pre_roll": 1.5, "max_turn": 20}}
"""

final class CoreTests: XCTestCase {
    func testJournalHasNoWordOfTheDialogue() async throws {  // A14
        let clock = TestClock(), reply = "Солнышко, привет! Я буду ждать тебя завтра."
        let model = ScriptedModel.typing(reply, clock: clock)
        let runner = TurnRunner(model: model, voice: RecordingVoice(), clock: clock)
        let outcome = try await runner.run("Привет, это Соня, я нарисовала Мурку")
        let versions = ["persona": "329790cc", "model": "85a896", "llama": "b10809", "ios": "27.0.1",
                        "voice": "com.apple.voice.enhanced.ru-RU.Milena", "girl": "Соня"]
        let line = try XCTUnwrap(TurnLog(outcome: outcome, stages: ["tail": 0.8], versions: versions,
                                         memory: ["footprint_mb": 512], thermal: "nominal").jsonLine())
        XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
        for part in ["endearment", "attachment", outcome.turn.record.contractHash, "\"source\":\"model\"",
                     "first_sentence", "reply_end", "b10809", "Milena", "footprint_mb", "redacted"] {
            XCTAssertTrue(line.contains(part), part)
        }
    }

    func testModelCheckSaysWhatIsWrong() throws {  // A15
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let registry = Data(sampleRegistry.utf8), weights = folder.appendingPathComponent("gemma.gguf")
        XCTAssertEqual(ModelCheck.check(registry: registry, in: folder).message, "модели нет: скопируй с Mac")
        try Data(count: 5).write(to: weights)
        XCTAssertEqual(ModelCheck.check(registry: registry, in: folder).message, "модель не та: 5 байт вместо 12")
        let broken = ModelCheck.check(registry: Data("{".utf8), in: folder).message ?? ""
        XCTAssertTrue(broken.hasPrefix("реестр не читается"), broken)
        try Data(count: 12).write(to: weights)
        XCTAssertEqual(ModelCheck.check(registry: registry, in: folder), .ready(weights))
        XCTAssertNil(ModelCheck.check(registry: registry, in: folder).message)
    }

    func testProfileDaysLeft() throws {  // A16
        let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict><key>ExpirationDate</key>"
            + "<date>2026-10-26T10:00:00Z</date></dict></plist>"
        let profile = Data([0x30, 0x82, 0x10]) + Data(plist.utf8) + Data([0xA0, 0x00])
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-19T10:00:00Z"))
        XCTAssertEqual(ProfileExpiry.daysLeft(profile, now: now), 7)
        XCTAssertEqual(ProfileExpiry.line(daysLeft: 7), "подпись: осталось 7 дн.")
        XCTAssertNil(ProfileExpiry.daysLeft(Data("мусор".utf8), now: now))
        XCTAssertNil(ProfileExpiry.daysLeft(nil, now: now))
        XCTAssertEqual(ProfileExpiry.line(daysLeft: nil), "срок подписи неизвестен")
    }

    func testTranscriptKeepsTheVolatileTail() {  // A18
        var collector = TranscriptCollector()
        collector.add("привет", isFinal: false)
        collector.add("привет", isFinal: true)
        XCTAssertEqual(collector.add("как дела", isFinal: false), "привет как дела")
        XCTAssertEqual(TranscriptCollector().text, "")
    }
}
