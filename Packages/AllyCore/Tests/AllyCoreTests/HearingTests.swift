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
}
