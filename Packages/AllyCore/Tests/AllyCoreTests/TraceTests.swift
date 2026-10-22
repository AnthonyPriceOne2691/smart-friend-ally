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
}
