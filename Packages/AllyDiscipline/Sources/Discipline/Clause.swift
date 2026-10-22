import Foundation

/// A condition of a topic's clause in router.json, parsed once (`condition` of router_core.py): alternatives «a|b»,
/// each «!»-negatable. A term is «?predicate»; «free A», «own A», «not A» — an occurrence not negated, hers (not
/// negated, not a grown-up's), negated; «L~R» — within three words, «L>R» — R within three words after L; or atoms.
/// An atom is a CONCEPT, a word of «@set», «#» (a number in digits) or «#5» (five digits or more); «+» joins atoms in
/// every term («own A+B» — an occurrence of either).
struct Condition: Sendable {
    enum Term: Sendable {
        case predicate(String), mode(String, [String]), near([String], [String], after: Bool), atoms([String])
    }

    let alternatives: [(negated: Bool, term: Term)]

    init(_ text: String) {
        alternatives = text.split(separator: "|").map { alternative in
            let negated = alternative.hasPrefix("!")
            return (negated, Self.term(negated ? alternative.dropFirst() : alternative))
        }
    }

    static func term(_ body: Substring) -> Term {
        let atoms = { (side: Substring) in side.split(separator: "+").map(String.init) }
        if body.hasPrefix("?") { return .predicate(String(body.dropFirst())) }
        if let space = body.firstIndex(of: " ") {
            return .mode(String(body[..<space]), atoms(body[body.index(after: space)...]))
        }
        if let mark = body.firstIndex(of: "~") ?? body.firstIndex(of: ">") {
            return .near(atoms(body[..<mark]), atoms(body[body.index(after: mark)...]), after: body[mark] == ">")
        }
        return .atoms(atoms(body))
    }
}

/// A clause of a topic: its id and the conditions that must all hold.
struct Clause: Sendable {
    let id: String, all: [Condition]

    init(_ line: [String]) { (id, all) = (line.first ?? "", line.dropFirst().map(Condition.init)) }
}

extension Scene {
    /// The context predicates a clause or an exit names.
    static let predicates: [String: @Sendable (Scene) -> Bool] = [
        "pretend": { $0.pretend }, "rule": { $0.ruleStatement }, "question": { $0.question },
        "parent_away": { $0.parentAway }, "frame": { $0.has("FRAME") }, "alone": { $0.anyWord("alone") },
        "intent": { $0.intent },
        "tale": { $0.has("FRAME") && !$0.anyWord("me_obj") }  // somebody else's story: no «мне», «меня», «нас»
    ]

    func predicate(_ name: String) -> Bool { Self.predicates[name]?(self) ?? false }

    /// Token indices of the atoms.
    func positions(_ atoms: [String]) -> [Int] {
        atoms.flatMap { atom -> [Int] in
            if atom.hasPrefix("@") { return toks.indices.filter { word($0, String(atom.dropFirst())) } }
            guard atom.hasPrefix("#") else { return at(atom) }
            let least = Int(atom.dropFirst()) ?? 1
            return toks.indices.filter { toks[$0].count >= least && toks[$0].allSatisfy(\.isNumber) }
        }
    }

    func holds(_ condition: Condition) -> Bool { condition.alternatives.contains { $0.negated != holds($0.term) } }

    func holds(_ term: Condition.Term) -> Bool {
        switch term {
        case .predicate(let name): return predicate(name)
        case .mode(let mode, let atoms): return positions(atoms).contains { occurs($0, mode) }
        case .near(let left, let right, let after):
            let rights = positions(right)
            return positions(left).contains { index in
                rights.contains { $0 != index && (after ? index < $0 && $0 <= index + 3 : abs($0 - index) <= 3) }
            }
        case .atoms(let atoms): return !positions(atoms).isEmpty
        }
    }

    /// An occurrence `free` (not negated), `own` (not negated, not a grown-up's) or else negated.
    func occurs(_ index: Int, _ mode: String) -> Bool {
        switch mode {
        case "free": return !negated(index)
        case "own": return !negated(index) && !adultAgent(index)
        default: return negated(index)
        }
    }

    /// A topic of clauses: the first clause that holds decides, unless an exit of the topic holds.
    func clauses(_ hazard: RouterData.Hazard) -> Outcome? {
        guard let clause = lexicon.clauses[hazard.topic]?.first(where: { clause in
            on("\(hazard.topic).\(clause.id)") && clause.all.allSatisfy(holds)
        }) else { return nil }
        if let exit = hazard.exits?.first(where: { on($0) && predicate($0) }) { return (nil, exit) }
        return (hazard.guardOnly == true ? .guarded : .script, clause.id)
    }
}
