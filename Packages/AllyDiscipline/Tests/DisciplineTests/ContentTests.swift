import XCTest
@testable import Discipline

/// A probe of the reference (output_filter.PROBES) the content rules change, or its clean twin; `want` is what the
/// reference says (make_fixtures.py).
struct ContentProbe: Decodable { let reply, heard, mode, want: String }

func contentProbes() throws -> [ContentProbe] {
    let url = try XCTUnwrap(Bundle.module.url(forResource: "contract_probes", withExtension: "jsonl"))
    return try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        .map { try JSONDecoder().decode(ContentProbe.self, from: Data($0.utf8)) }
}

/// The content rules and the adult pointer of router-people, and the rules on the router's decision of
/// contract-fixes: their ablation lives here, not in ContractTests.
let contentRules: Set<ContractRule> = [.humanClaim, .piiEcho, .piiRequest, .promise, .promiseRefusalExempt,
                                       .surpriseExempt, .adviceExempt, .promisePointer, .adultPointer,
                                       .pointerSparesSafety, .dangerOverTopic]

/// The rules that act on the router's decision: the reference's probes carry none, each has its own test.
let decisionRules: Set<ContractRule> = [.adultPointer, .pointerSparesSafety, .dangerOverTopic]

func told(_ reply: String, heard: String = "", decision: RouterDecision = .pass, mode: TurnMode = .talk,
          off: Set<String> = []) -> String {
    spoken(TurnContract(mode: mode, contract: .shared, disabled: off, heard: heard, decision: decision).finish(reply))
}

func told(_ probe: ContentProbe, off: Set<String> = []) -> String {
    told(probe.reply, heard: probe.heard, mode: TurnMode(rawValue: probe.mode) ?? .talk, off: off)
}

final class ContentTests: XCTestCase {
    func testMatchesTheReferenceProbes() throws {  // R14 E20 E33 E34
        let probes = try contentProbes()
        XCTAssertEqual(probes.count, 52)
        XCTAssertEqual(probes.filter { told($0) != $0.want }.map(\.reply), [])
    }

    /// Ablation, the mutation gate's role: with a content rule off, one of the reference's probes comes out otherwise.
    func testEveryContentRuleSwitchedOffChangesAProbe() throws {  // R14
        let probes = try contentProbes()
        let idle = contentRules.subtracting(decisionRules).map(\.rawValue).filter { rule in
            probes.allSatisfy { told($0, off: [rule]) == $0.want }
        }
        XCTAssertEqual(idle, [], "switching these rules off changes none of the probes")
    }

    /// The sentence `first` let out stays when a later sentence claims she is human.
    func testAHumanClaimAfterTheFirstSentence() {  // R14 E20
        let contract = TurnContract(mode: .talk)
        XCTAssertEqual(contract.first("Привет!"), "Привет!")
        let turn = contract.finish("Привет! Я живая девочка, как ты!")
        XCTAssertEqual(turn.source, .canned("alive"))
        XCTAssertEqual(spoken(turn), "Привет! " + (contractData.scripts["alive"] ?? ""))
    }

    func testFearAndLostKeepAnAdultPointer() {  // R13 E18 E30 E31
        let fear = RouterDecision.guard(topic: "fear"), calm = "Не бойся! Я с тобой."
        XCTAssertEqual(told("Не плачь, всё будет хорошо.", decision: .script(key: "lost")),
                       "Не плачь, всё будет хорошо. Стой на месте и громко зови маму, папу или продавца.")
        XCTAssertEqual(told(calm + " Хочешь, споём песенку?", decision: fear),
                       calm + " Если страшно, скажи маме или папе.")
        XCTAssertEqual(told("Я буду ждать тебя!", decision: fear), contractData.canned["fear"])
        XCTAssertEqual(told("Ой, не бойся! Это просто гром. Если страшно, скажи маме.", decision: fear),
                       "Ой, не бойся! Это просто гром. Если страшно, скажи маме.")
        XCTAssertEqual(told(calm, decision: .guard(topic: "socket")), calm)
        XCTAssertEqual(told(calm, decision: fear, off: ["adult_pointer"]), calm)
        let tall = "Гром гремит далеко-далеко за большой зелёной горой у самой реки. "
        XCTAssertEqual(told(tall + "Тучи плывут. Дождик капает.", decision: fear),
                       tall + "Тучи плывут. Если страшно, скажи маме или папе.")
    }

    /// The adult pointer never pushes out the last sentence with a prohibition or protection: the rest goes first,
    /// and with no room even then the reply keeps its prohibition and goes without the pointer (the parent, H4).
    func testPointerSparesTheLastProhibition() {  // H1 H2 H3 H4 H5
        let fear = RouterDecision.guard(topic: "fear"), say = " Если страшно, скажи маме или папе."
        let wind = "Ой, это просто ветер шумит. Он очень сильный. Не открывай окно!"
        XCTAssertEqual(told(wind, decision: fear), "Ой, это просто ветер шумит. Не открывай окно!" + say)
        XCTAssertEqual(told("Не открывай окно! Это просто ветер шумит. Он очень сильный.", decision: fear),
                       "Не открывай окно! Это просто ветер шумит." + say)
        XCTAssertEqual(told("Ой, это ветер. Не открывай окно! Не трогай провода.", decision: fear),
                       "Ой, это ветер. Не открывай окно!" + say)
        let long = "Это ветер шумит за окном так громко, что даже стёкла в нашем доме тихонько звенят. Не открывай "
            + "окно и не подходи к нему близко, пока на улице такая сильная гроза."
        XCTAssertEqual(told(long, decision: fear), long)
        XCTAssertEqual(told("Ой, это просто гроза. Она скоро пройдёт. Давай споём песенку?", decision: fear),
                       "Ой, это просто гроза. Она скоро пройдёт." + say)
        XCTAssertEqual(told(wind, decision: fear, off: ["pointer_spares_safety"]),
                       "Ой, это просто ветер шумит. Он очень сильный." + say)
    }

    /// The whole reply cut for a hazard how-to: the hazard's script outranks a topic fallback with no protection of
    /// its own (fear, pain), with the topic's pointer when the script names no adult; «потерялась» keeps its own.
    func testDangerScriptOutranksABareTopicFallback() {  // H6 H7 H8
        let fear = RouterDecision.guard(topic: "fear"), match = "Давай зажжём спичку, это весело и красиво!"
        XCTAssertEqual(told(match, decision: fear), contractData.scripts["matches"])
        XCTAssertEqual(told("Давай откроем окно и залезем на подоконник, это весело!", decision: fear),
                       (contractData.scripts["window"] ?? "") + " Если страшно, скажи маме или папе.")
        XCTAssertEqual(told(match, decision: .guard(topic: "pain")), contractData.scripts["matches"])
        XCTAssertEqual(told(match, decision: .guard(topic: "lost")), contractData.scripts["lost"])
        XCTAssertEqual(told(match, decision: fear, off: ["danger_over_topic"]), contractData.canned["fear"])
    }

    func testPainKeepsAnAdultPointer() {  // R13 E45
        XCTAssertEqual(told("Ой, бедная ножка! Давай подуем.", decision: .script(key: "pain")),
                       "Ой, бедная ножка! Давай подуем. Скажи об этом маме или папе.")
        XCTAssertEqual(told("Я буду ждать тебя!", decision: .guard(topic: "pain")), contractData.scripts["pain"])
    }

    /// «скучать» and «по тебе» in either order, with «буду» or without, in every mode; «не буду» stays honest (D2).
    func testMissingInEitherOrderIsCutInEveryMode() {  // R14 E54
        let honest = "Я не буду по тебе скучать, я же всегда в телефоне."
        for mode in TurnMode.allCases {
            XCTAssertEqual(told("Ура! Я буду по тебе скучать!", mode: mode), "Ура!", "\(mode)")
            XCTAssertEqual(told("Пока! Я буду очень скучать по тебе!", mode: mode), "Пока!", "\(mode)")
            XCTAssertEqual(told("Буду по тебе скучать.", mode: mode), contractData.canned["attachment"], "\(mode)")
            XCTAssertEqual(told(honest, mode: mode), honest, "\(mode)")
        }
    }

    /// In a game the fear guard goes (the game flag), so no pointer is added; the fallbacks and pointers pass.
    func testNoPointerInAGameAndEveryPointerPasses() {  // R3 R11 R13 E32
        let decision = Router.shared.route("Мне страшно, тут темно", state: RouterState(game: true)).decision
        XCTAssertEqual(decision, .pass)
        XCTAssertEqual(told("Не бойся!", decision: decision), "Не бойся!")
        for (topic, pointer) in contractData.pointers {
            let fallback = pointer.last ?? "", reply = contractData.canned[fallback] ?? contractData.scripts[fallback]
            for text in [pointer.first, reply].compactMap({ $0 }) {
                XCTAssertEqual(told(text, decision: .guard(topic: topic)), text, topic)
                XCTAssertEqual(TurnMode.allCases.map { told(text, mode: $0) },
                               Array(repeating: text, count: TurnMode.allCases.count))
            }
        }
    }

    /// Data whose content probe is not caught leave only canned replies (as K8).
    func testDataWithAnUncaughtContentProbeAnswerOnlyCanned() {  // R14 R8
        for rule in ["secret", "pii_ask", "human_claim"] {  // content patterns: secret is the promise rule's
            var broken = ContractData.decode(ContractData.bytes)
            broken.content[rule] = []
            XCTAssertFalse(Contract(broken, hash: "broken").healthy, rule)
        }
    }
}
