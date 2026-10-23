import Discipline

/// The router's decision as the session acts on it, with the journal fields of its record: a script sounds without
/// the model, a guard and a pass go to the model with the decision. `Routed` of Discipline has no public init, so the
/// fields are carried here; `RouterRouting` maps `Router.shared` into this.
public struct Route: Equatable, Sendable {
    public let decision: RouterDecision, rules: [String], dataHash: String, forget: Bool

    public init(_ decision: RouterDecision, rules: [String] = [], dataHash: String = "none", forget: Bool = false) {
        (self.decision, self.rules, self.dataHash, self.forget) = (decision, rules, dataHash, forget)
    }

    var kind: String {
        switch decision {
        case .script: "script"
        case .guard: "guard"
        case .pass: "pass"
        }
    }

    var key: String? { if case .script(let key) = decision { key } else { nil } }

    var topic: String? { if case .guard(let topic) = decision { topic } else { key } }
}

/// The hook before the model: the session asks it about every utterance she says.
public protocol TurnRouting: Sendable {
    func route(_ utterance: String) -> Route
}

/// Every utterance to the model: sessions without the router (tests, the default of `SessionParts`).
public struct PassThroughRouting: TurnRouting {
    public init() {}

    public func route(_ utterance: String) -> Route { Route(.pass) }
}

/// The router of `Discipline` before the model, on the live turn (D2.2): every utterance, the game flag off — there
/// are no games yet.
public struct RouterRouting: TurnRouting {
    public init() {}

    /// The router's data passed their self-test at load; when not, every turn is a guard without a topic (fail-closed).
    public static var healthy: Bool { !Router.shared.route("").record.rules.contains("selftest_failed") }

    public func route(_ utterance: String) -> Route {
        let routed = Router.shared.route(utterance, state: RouterState(game: false))
        return Route(routed.decision, rules: routed.record.rules, dataHash: routed.record.dataHash,
                     forget: routed.forget)
    }
}
