@testable import AllyCore
import Discipline
import XCTest

final class RoutingTests: XCTestCase {
    func testTheRealRouterLeadsScriptsPastTheModel() async throws {  // W4
        let giraffe = "Жирафы очень высокие! У них длинная шея, чтобы доставать листья с деревьев."
        let rig = Rig(replies: [giraffe], router: RouterRouting())
        await rig.session.handle(.wake)
        await rig.hear("Дай мне спички")
        XCTAssertEqual(rig.said, ["Спички и зажигалку сама не бери: можно обжечься или устроить пожар.",
                                  "Зажечь свечку попроси маму или папу."])
        XCTAssertEqual(rig.model.calls, 0)
        let matches = try XCTUnwrap(rig.sink.records.last?.route)
        XCTAssertEqual([matches.kind, matches.key], ["script", "matches"])
        XCTAssertNotEqual(matches.dataHash, "none")
        XCTAssertFalse(matches.forget)
        await rig.hear("Я живу на улице Морковной, дом семь")
        XCTAssertEqual(Array(rig.said.suffix(2)), ["Здорово, что ты это знаешь!",
                                                   "Но адрес и телефон говорят только маме, папе и знакомым взрослым."])
        XCTAssertEqual(rig.model.calls, 0)
        let address = try XCTUnwrap(rig.sink.records.last?.route)
        XCTAssertEqual([address.kind, address.key], ["script", "pii"])
        XCTAssertTrue(address.forget)
        await rig.hear("Расскажи про жирафа")
        XCTAssertEqual(Array(rig.said.suffix(2)), ["Жирафы очень высокие!",
                                                   "У них длинная шея, чтобы доставать листья с деревьев."])
        XCTAssertEqual(rig.model.calls, 1)
        XCTAssertEqual(rig.sink.records.last?.route?.kind, "pass")
        XCTAssertEqual(rig.sink.records.last?.route?.dataHash, matches.dataHash)
    }

    func testAForgottenUtteranceNeverReachesTheModel() async {  // W5
        let forgotten = Route(.guard(topic: nil), rules: ["selftest_failed"], dataHash: "fnv1a:test", forget: true)
        let rig = Rig(replies: ["Жила-была принцесса."], routes: ["Расскажи сказку": forgotten])
        await rig.session.handle(.wake)
        await rig.hear("Расскажи сказку")
        XCTAssertEqual(rig.model.calls, 0)
        XCTAssertEqual(rig.said, [misheard])
        XCTAssertEqual(rig.sink.records.last?.route?.forget, true)
        XCTAssertEqual(rig.sink.records.last?.source, "canned:generic")
        XCTAssertEqual(rig.session.state, .listening)
    }
}
