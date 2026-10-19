import XCTest
@testable import Discipline

/// One row of router_parity.jsonl: an open-set utterance and the decision of the Python reference (make_router.py).
struct RouterRow: Decodable {
    let text: String, game: Bool, kind: String, topic: String?, key: String?, rules: [String]
}

let routerData = RouterData.decode(RouterData.bytes)

func routerRows() throws -> [RouterRow] {
    let url = try XCTUnwrap(Bundle.module.url(forResource: "router_parity", withExtension: "jsonl"))
    return try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        .map { try JSONDecoder().decode(RouterRow.self, from: Data($0.utf8)) }
}

/// The decision as a probe writes it: «script:matches», «guard:socket», «pass».
func decided(_ text: String, game: Bool = false, off: Set<String> = [], by router: Router = .shared) -> String {
    Router.want(router.route(text, state: RouterState(game: game), off: off))
}

/// Context rules and mechanisms of the router that can be switched off.
let routerRules = ["known_exact", "glue", "child_costs", "negation", "adult_agent", "pretend", "rule", "story",
                   "adult_scene", "ask", "fear", "stove_source", "fire_verb", "game"]

final class RouterTests: XCTestCase {
    func testMatchesTheReferenceOnTheOpenSets() throws {  // R10 E26
        let rows = try routerRows()
        XCTAssertEqual(rows.count, 50)
        let mismatches = rows.compactMap { row -> String? in
            let got = Router.shared.route(row.text, state: RouterState(game: row.game)).record
            let same = (got.kind, got.topic, got.key, got.rules) == (row.kind, row.topic, row.key, row.rules)
            return same ? nil : "«\(row.text)»: \(got)"
        }
        XCTAssertEqual(mismatches, [])
    }

    func testExamplesOfTheSpec() {  // R1 R3 R11 E2 E3 E5 E6 E21 E22 E23 E24
        let examples = [
            ("спички трогать нельзя, будет пожар", "pass", false), ("спички трогать нельзя, будет пожар", "pass", true),
            ("Я так радовалась! Мама зажгла свечки на торте, и я задула все пять.", "pass", false),
            ("давай поиграем в костёр понарошку из кубиков и жёлтой бумаж", "pass", false),
            ("давай играть, я возьму спички", "script:matches", true),
            ("А если в розетку засунуть шпильку?", "script:socket", false),
            ("я хачу вилку в лазетку засунуть", "script:socket", false),
            ("мона я вазьму зазыгалку", "script:matches", false),
            ("я не трогала розетку", "guard:socket", false),
            ("в мультике у кота были спички, страшно", "guard:matches", false)
        ].map { RouterData.Probe(text: $0.0, want: $0.1, game: $0.2) }
        XCTAssertEqual(examples.filter { decided($0.text, game: $0.game ?? false) != $0.want }.map(\.text), [])
    }

    /// Probes both ways (R8 runs the same list at load): dangerous ones script, look-alike harmless ones do not.
    func testEveryTopicHasProbesBothWays() {  // R11 R8
        XCTAssertTrue(Router.shared.healthy)
        let wrong = routerData.selftest.filter { decided($0.text, game: $0.game ?? false) != $0.want }
        XCTAssertEqual(wrong.map(\.text), [])
        for hazard in routerData.hazards {
            let mine = routerData.selftest.filter { probe in
                Router.shared.route(probe.text, state: RouterState(game: probe.game ?? false)).record.rules
                    .contains { $0.hasPrefix(hazard.topic + ".") }
            }
            XCTAssertGreaterThanOrEqual(mine.filter { $0.want == "script:" + hazard.topic }.count, 3, hazard.topic)
            XCTAssertGreaterThanOrEqual(mine.filter { $0.want != "script:" + hazard.topic }.count, 3, hazard.topic)
        }
    }

    /// Ablation, the mutation gate's role: with a rule off, one of the probes comes out differently.
    func testEveryRuleSwitchedOffChangesAProbe() {  // R11
        let idle = routerRules.filter { rule in
            routerData.selftest.allSatisfy { decided($0.text, game: $0.game ?? false, off: [rule]) == $0.want }
        }
        XCTAssertEqual(idle, [], "switching these rules off changes none of the probes")
    }

    func testEveryScriptPassesTheTurnContractUnchanged() {  // R11
        for hazard in routerData.hazards {
            let text = Router.script(for: hazard.topic)
            XCTAssertNotNil(text, hazard.topic)
            for mode in TurnMode.allCases {
                XCTAssertEqual(text.map { spoken(say($0, mode)) }, text, "\(hazard.topic) in \(mode)")
            }
        }
    }

    func testDataWithAnUncaughtProbeLeaveNoScript() {  // R8 E16
        var broken = routerData
        broken.lexicon["SOCKET"] = []
        broken.exactHash = broken.lexiconHash
        let router = Router(broken, hash: "broken"), routed = router.route("можно засунуть шпильку в розетку?")
        XCTAssertEqual(routed.decision, .guard(topic: nil))
        XCTAssertEqual(routed.record.rules, ["selftest_failed"])
        XCTAssertEqual(router.route("Привет! Давай играть").decision, .guard(topic: nil))
    }

    func testStaleDoublesLeaveNoScript() {  // R8 E25
        var stale = routerData
        stale.lexicon["SOCKET", default: []].append(["тройник", "\\w*"])
        XCTAssertEqual(Router(stale, hash: "stale").route("дай мне спички").record.rules, ["selftest_failed"])
        stale.exactHash = stale.lexiconHash
        XCTAssertEqual(decided("дай мне спички", by: Router(stale, hash: "stale")), "script:matches")
    }

    func testRecordHoldsNoWordOfTheGirl() {  // R9 E15
        let girl = "Соня сказала: можно я возьму у Тёмы спички и зажгу свечку на кухне?"
        let routed = Router.shared.route(girl)
        let journal = String(describing: routed.record)
        XCTAssertEqual(routed.decision, .script(key: "matches"))
        XCTAssertEqual(routed.record.rules, ["matches.own_verb"])
        XCTAssertEqual(routed.record.dataHash, fnv1a(RouterData.bytes))
        XCTAssertEqual(girl.split { !$0.isLetter }.filter { journal.localizedCaseInsensitiveContains($0) }, [])
        XCTAssertFalse(Rules.shared.cyrillicLetter.found(in: journal), journal)
    }

    func testTheGameFlagNeverSilencesAScript() throws {  // R3 E6 E27
        let scripts = try routerRows().filter { $0.kind == "script" }
        XCTAssertGreaterThanOrEqual(scripts.count, 20)
        XCTAssertEqual(scripts.filter { decided($0.text, game: true) != "script:" + ($0.topic ?? "") }.map(\.text), [])
        let guarded = Router.shared.route("у тебя в игре есть спички", state: RouterState(game: true)).record
        XCTAssertEqual(guarded.rules, ["matches.word", "game"])
        XCTAssertEqual(decided("у тебя в игре есть спички"), "guard:matches")
    }

    /// ё written as е, extra spaces, the first letter's case: the same record.
    func testNoiseKeepsTheDecision() throws {  // R10
        let inputs = try routerRows().map(\.text) + routerData.selftest.map(\.text)
        let broken = inputs.flatMap { input in
            noise.filter { Router.shared.route($0.apply(input)).record != Router.shared.route(input).record }
                .map { "\($0.name): «\(input)»" }
        }
        XCTAssertEqual(broken, [])
    }

    /// A guard against a slow decision in the test build; R12's 5 ms p95 is measured in release (discipline-replay).
    func testDecisionIsFast() throws {  // R12 E28
        let clock = ContinuousClock()
        let times = try routerRows().map { row in clock.measure { _ = Router.shared.route(row.text) } }.sorted()
        XCTAssertLessThan(times[times.count * 95 / 100], .milliseconds(50))
    }
}
