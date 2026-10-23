import AllyCore
import XCTest

/// The app's registries as they ship: `App/Resources` of this tree.
let appResources = URL(fileURLWithPath: #filePath).appendingPathComponent("../../../../../App/Resources").standardized

final class HearingTests: XCTestCase {
    func testTheHearingRegistryNamesEveryTailAndTheModelKeepsTheRest() throws {  // U3
        let hearing = try Hearing.decode(Data(contentsOf: appResources.appendingPathComponent("hearing.json")))
        XCTAssertEqual(TurnKind.allCases.map { hearing.turn.tail($0) }, [1.8, 1.2, 2.5])
        XCTAssertEqual([hearing.turn.tentative, hearing.turn.preRoll, hearing.turn.maxTurn, hearing.listenTimeout],
                       [0.3, 1.5, 30, 8])
        let model = try Data(contentsOf: appResources.appendingPathComponent("model.json"))
        let keys = try XCTUnwrap(JSONSerialization.jsonObject(with: model) as? [String: Any]).keys
        XCTAssertEqual(Set(keys), ["model", "runtime", "sampling", "persona", "voice", "voice_rate",
                                   "first_sentence_timeout"])
        XCTAssertEqual(try ModelRegistry.decode(model).model.bytes, 4_977_171_584)
        let partial = TurnTiming(tails: ["open": 1.8, "closed": 1.2], tentative: 0.3, preRoll: 1.5, maxTurn: 30)
        XCTAssertEqual(partial.tail(.counting), 1.8)
    }

    func testTheRecognizerIsChosenByTheRegistryAndTheFiles() throws {  // U22
        let hearing = try Hearing.decode(Data(contentsOf: appResources.appendingPathComponent("hearing.json")))
        let asr = try XCTUnwrap(hearing.asr), files = asr.gigaam
        let sizes = Dictionary(uniqueKeysWithValues: files.map { ($0.file, $0.bytes) })
        XCTAssertEqual(asr.engine, "dictation")
        XCTAssertEqual(asr.choose(sizes: sizes, pairServes: true).engine, "dictation")
        let gigaam = Recognition(engine: "gigaam", gigaam: files)
        XCTAssertEqual(gigaam.choose(sizes: sizes, pairServes: true).engine, "gigaam")
        XCTAssertNil(gigaam.choose(sizes: sizes, pairServes: true).line)
        let missing = sizes.filter { $0.key != "model.int8.onnx.data" }, small = sizes.merging(["tokens.txt": 5]) { $1 }
        XCTAssertEqual(gigaam.choose(sizes: missing, pairServes: true).engine, "dictation")
        XCTAssertEqual(gigaam.choose(sizes: missing, pairServes: true).line,
                       "GigaAM нет: нет файла model.int8.onnx.data — диктовка")
        XCTAssertEqual(gigaam.choose(sizes: small, pairServes: true).line,
                       "GigaAM нет: tokens.txt — 5 байт вместо 196 — диктовка")
        XCTAssertEqual(gigaam.choose(sizes: sizes, pairServes: false).line,
                       "GigaAM нет: ONNX Runtime без API 28 — диктовка")
        XCTAssertEqual(asr.label("dictation"), "dictation")
        XCTAssertEqual(gigaam.label("gigaam"), "gigaam-v3-ctc:224757733")
    }
}
