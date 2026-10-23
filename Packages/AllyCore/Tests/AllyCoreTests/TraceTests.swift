import AllyCore
import XCTest

final class TraceTests: XCTestCase {
    func testOneRecordPerTurnWithoutWords() async throws {  // S11
        let routes = ["Дай мне спички": Route(.script(key: "matches"), rules: ["matches.ask"], dataHash: "fnv1a:test")]
        let stamp = TraceStamp(versions: ["persona": "329790cc", "llama": "b10809", "girl": "Соня"],
                               memory: ["footprint_mb": 512], thermal: "nominal")
        let rig = Rig(replies: ["Какая пушистая Мурка! А какого она цвета?", "Ух ты, башня! Высокая?",
                                "Здорово, что высокая!"], routes: routes, stamp: stamp)
        await rig.session.handle(.wake)
        await rig.hear("Привет, это Соня, я нарисовала Мурку", at: 10)
        await rig.hear("Дай мне спички", at: 20)
        await rig.hear("", at: 30)
        await rig.hear("А мой брат Тёма строит башню", at: 40)
        await rig.hear("Очень высокая", at: 605)
        let records = rig.sink.records
        XCTAssertEqual(records.map(\.turn), Array(1...7))
        XCTAssertEqual(Set(records.map(\.session)).count, 1)
        XCTAssertEqual(records.map(\.source), ["session:greeting", "model", "script:matches", "session:misheard",
                                               "model", "model", "session:goodbye"])
        XCTAssertEqual(records.map(\.mode), ["talk", "talk", "talk", "talk", "talk", "goodbye", "goodbye"])
        XCTAssertEqual(records.map(\.end), [nil, nil, nil, nil, nil, nil, "limit"])
        let lines = records.compactMap { $0.jsonLine() }
        XCTAssertEqual(lines.count, 7)
        for line in lines {
            XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
            for part in ["\"redacted\"", "\"b10809\"", "\"footprint_mb\":512", "\"elapsed\"", "\"limit\":600"] {
                XCTAssertTrue(line.contains(part), part + " in " + line)
            }
        }
        let script = try XCTUnwrap(records[2].route)
        XCTAssertEqual([script.kind, script.topic, script.key, script.dataHash], ["script", "matches", "matches",
                                                                                  "fnv1a:test"])
        XCTAssertEqual(script.rules, ["matches.ask"])
        XCTAssertFalse(script.forget)
        XCTAssertEqual(records[1].route?.kind, "pass")
        XCTAssertNotNil(records[1].contractHash)
        XCTAssertNotNil(records[1].stages["first_sound"])
        XCTAssertEqual(records[5].elapsed, 605, accuracy: 1e-9)
        XCTAssertNil(records[0].route)
    }

    func testTheTraceFileAppendsALinePerRecordWithTheAppsStages() async throws {  // W6
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("turns.jsonl")
        try Data("{\"turn\":1}\n".utf8).write(to: url)
        let stages = ["tail": 0.90, "recognize": 0.03, "speech_end_to_sound": 1.85, "tap_buffer": 0.02]
        let file = TraceFile(url: url), model = ReplyQueue(["Жирафы очень высокие! У них длинная шея."])
        let parts = SessionParts(model: model, voice: RecordingVoice(), sink: file, clock: TestClock(),
                                 stamp: { TraceStamp(stages: stages) })
        let session = Session(parts)
        await session.handle(.wake)
        await session.handle(.heard("Расскажи про жирафа"))
        await session.handle(.stop)
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines.first, "{\"turn\":1}")
        XCTAssertEqual(file.failures, 0)
        var sources: [String?] = []
        for line in lines.dropFirst() {
            let record = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any], line)
            sources.append(record["source"] as? String)
            XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
            let keys = ["\"cancelled\":", "\"elapsed\":", "\"limit\":", "\"mode\":", "\"phase\":", "\"session\":",
                        "\"source\":", "\"stages\":", "\"turn\":"].compactMap { line.range(of: $0)?.lowerBound }
            XCTAssertEqual(keys.count, 9, line)
            XCTAssertEqual(keys, keys.sorted(), line)
        }
        XCTAssertEqual(sources, ["session:greeting", "model", "session:stop"])
        let turn = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(lines[2].utf8)) as? [String: Any])
        let measured = try XCTUnwrap(turn["stages"] as? [String: Double])
        XCTAssertEqual(Set(measured.keys), Set(stages.keys).union(["first_text", "first_sentence", "first_sound",
                                                                    "reply_end"]))
        for (stage, seconds) in stages { XCTAssertEqual(measured[stage] ?? -1, seconds, accuracy: 1e-9, stage) }
    }
}
