import Foundation

/// What the router decides before the model.
public enum RouterDecision: Equatable, Sendable {
    /// A signed script is spoken, the model is not called; `Router.script(for:)` gives its text.
    case script(key: String)
    /// A hazard word without her hazard, or her fear: the model answers (`TurnContract` keeps an adult pointer for
    /// the topics of `contract.json → pointers`); `nil` — data that failed the self-test.
    case `guard`(topic: String?)
    /// The model answers as usual.
    case pass
}

/// What the app passes with each utterance: the game engine's flag.
public struct RouterState: Equatable, Sendable {
    public var game: Bool

    public init(game: Bool = false) { self.game = game }
}

/// The journal of a decision: kind, topic, script key, rule ids «topic.outcome», data hash — never a word of hers.
public struct RouterRecord: Equatable, Sendable {
    public let kind: String, topic: String?, key: String?, rules: [String], dataHash: String
}

/// A decision and its record; `forget` — she named her address, phone or kindergarten (or the data failed the
/// self-test): the app keeps this utterance out of the model's history and memory.
public struct Routed: Equatable, Sendable {
    public let decision: RouterDecision, record: RouterRecord, forget: Bool
}

/// The router before the model: `route` of local/spike/router-proto/router_core.py over `router.json`. A script
/// wins over a guard, topics go by priority; the game flag never silences a script. Data that fail the self-test
/// (the doubles' hash, every probe) leave no script: every turn is a guard without a topic, `selftest_failed`.
public struct Router: Sendable {
    public static let shared = Router(RouterData.decode(RouterData.bytes), hash: fnv1a(RouterData.bytes))

    let lexicon: Lexicon, hash: String
    private(set) var healthy = true

    init(_ data: RouterData, hash: String) {
        (lexicon, self.hash) = (Lexicon(data), hash)
        healthy = data.exactHash == data.lexiconHash && data.selftest.allSatisfy { probe in
            Router.want(route(probe.text, state: RouterState(game: probe.game ?? false), off: [])) == probe.want
        }
    }

    /// The signed text of a script: `contract.json → scripts`, one copy with the turn contract.
    public static func script(for key: String) -> String? { Contract.shared.data.scripts[key] }

    public func route(_ utterance: String, state: RouterState = RouterState()) -> Routed {
        route(utterance, state: state, off: [])
    }

    /// - Parameter off: rule ids switched off (ablation); the self-test always runs with every rule on.
    func route(_ utterance: String, state: RouterState, off: Set<String>) -> Routed {
        guard healthy else { return routed(.guard(topic: nil), rules: ["selftest_failed"], forget: true) }
        let scene = Scene(utterance, lexicon: lexicon, off: off)
        let found = lexicon.data.hazards.compactMap { hazard in
            scene.outcome(hazard).map { (topic: hazard.topic, outcome: $0, forget: hazard.forget == true) }
        }
        var rules = found.map { "\($0.topic).\($0.outcome.rule)" }
        let forget = found.contains { $0.forget && $0.outcome.strength != nil }
        if let hit = found.first(where: { $0.outcome.strength == .script }) {
            return routed(.script(key: hit.topic), rules: rules, forget: forget)
        }
        let guards = found.filter { $0.outcome.strength == .guarded }.map(\.topic)
        let kept = guards.filter { !state.game || off.contains("game") || lexicon.data.gameGuards.contains($0) }
        rules += kept.count < guards.count ? ["game"] : []
        return routed(kept.first.map { .guard(topic: $0) } ?? .pass, rules: rules, forget: forget)
    }

    private func routed(_ decision: RouterDecision, rules: [String], forget: Bool) -> Routed {
        let record = switch decision {
        case .script(let key): RouterRecord(kind: "script", topic: key, key: key, rules: rules, dataHash: hash)
        case .guard(let topic): RouterRecord(kind: "guard", topic: topic, key: nil, rules: rules, dataHash: hash)
        case .pass: RouterRecord(kind: "pass", topic: nil, key: nil, rules: rules, dataHash: hash)
        }
        return Routed(decision: decision, record: record, forget: forget)
    }

    /// The decision as a probe writes it: «script:matches», «guard:socket», «pass».
    static func want(_ routed: Routed) -> String {
        routed.record.topic.map { "\(routed.record.kind):\($0)" } ?? routed.record.kind
    }
}
