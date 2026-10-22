import Foundation

/// How strong a topic's finding is: a script, or a guard (the model answers).
enum Strength { case script, guarded }

/// What a topic's grammar found — a script, a guard, or no topic (`nil`) — and the rule id that decided.
typealias Outcome = (strength: Strength?, rule: String)

/// One utterance through the lexicon: tokens, the concepts each token reaches, the context rules of the reference
/// (`Ctx`, `hazard` and `topic` of router_core.py). `off` — rule ids switched off (ablation).
struct Scene {
    let text: String, toks: [String], hits: [String: [Int]], lexicon: Lexicon, off: Set<String>

    init(_ text: String, lexicon: Lexicon, off: Set<String>) {
        let toks = lexicon.tokens(text, off: off)
        var hits: [String: [Int]] = [:]
        let table = off.contains("child_costs") ? lexicon.plain : lexicon.noise
        for (index, word) in toks.enumerated() {
            let letters = Lexicon.letters(word), double = !off.contains("known_exact") && lexicon.doubles.contains(word)
            for concept in lexicon.concepts where concept.entries.contains(where: { entry in
                lexicon.reaches(entry, word, letters, double: double, table: table)
            }) {
                hits[concept.name, default: []].append(index)
            }
        }
        (self.text, self.toks, self.hits, self.lexicon, self.off) = (text, toks, hits, lexicon, off)
    }

    func on(_ rule: String) -> Bool { !off.contains(rule) }

    func at(_ concept: String) -> [Int] { hits[concept] ?? [] }

    func has(_ concepts: String...) -> Bool { concepts.contains { hits[$0] != nil } }

    func word(_ index: Int, _ set: String) -> Bool { toks.indices.contains(index) && lexicon.inSet(set, toks[index]) }

    func anyWord(_ set: String) -> Bool { toks.contains { lexicon.inSet(set, $0) } }

    /// «не» right before the word, or before up to two fillers («уже», «совсем»).
    func negated(_ index: Int) -> Bool {
        guard on("negation") else { return false }
        for back in stride(from: index - 1, through: max(0, index - 3), by: -1) {
            if word(back, "neg") { return true }
            if !word(back, "neg_fillers") { return false }
        }
        return false
    }

    var question: Bool { text.contains("?") || anyWord("ask") }

    /// «понарошку», «будто», a toy thing, «из кубиков».
    var pretend: Bool {
        on("pretend") && (has("PRETEND", "FAKE_ADJ")
            || toks.indices.contains { word($0, "made_of") && at("MATERIAL").contains($0 + 1) })
    }

    /// She wants or asks («хочу», «можно», «дай»), not negated; «сама» after a parent is the parent's.
    var intent: Bool {
        at("INTENT").contains { index in
            !(word(index, "self") && at("PARENT").contains { index - 4 <= $0 && $0 < index }) && !negated(index)
        }
    }

    /// «нельзя трогать плиту»: a rule she states, with no request and no question.
    var ruleStatement: Bool { on("rule") && has("RULE") && !text.contains("?") && !anyWord("request") }

    /// The agent of the verb at `index` is a grown-up: «мама зажгла», «она выпила» when a parent is in the line.
    func adultAgent(_ index: Int) -> Bool {
        guard on("adult_agent") else { return false }
        for back in stride(from: index - 1, through: max(0, index - 3), by: -1) {
            if at("PARENT").contains(back) || at("ROLE_ADULT").contains(back) { return true }
            if word(back, "subj_adult_pron") && has("PARENT") { return true }
            if word(back, "me") || at("OTHER_PERSON").contains(back) || word(back, "kid") { return false }
        }
        return false
    }

    func ownVerbs(_ concepts: [String]) -> [Int] { concepts.flatMap(at).filter { !negated($0) && !adultAgent($0) } }

    var parentAway: Bool { has("PARENT") && (has("PARENT_BUSY", "ABSENT") || anyWord("gone")) }

    /// `topic`: a topic of clauses; a stove's fire is not hers; the object's grammar; her fire verb alone; the
    /// clauses of an object's topic when its grammar does not script.
    func outcome(_ hazard: RouterData.Hazard) -> Outcome? {
        guard let object = hazard.object else { return clauses(hazard) }
        if let source = hazard.source, let concept = source.first, on("stove_source"), has(concept),
           at(object).allSatisfy({ index in source.dropFirst().contains { toks[index].hasPrefix($0) } }) {
            return (nil, "stove_source")
        }
        let found = grammar(hazard, object)
        if found?.strength == .script { return found }
        if found?.strength == nil, let verb = hazard.verbAlone, on("fire_verb"), !ownVerbs([verb]).isEmpty, !pretend,
           !ruleStatement {
            return (.script, "fire_verb")
        }
        let extra = clauses(hazard)
        return extra?.strength == .script ? extra : found
    }

    /// `hazard`, its exits first: pretend, a rule she states, a story, a grown-up's scene.
    func grammar(_ hazard: RouterData.Hazard, _ object: String) -> Outcome? {
        guard has(object) else { return nil }
        if pretend { return (nil, "pretend") }
        if ruleStatement { return (nil, "rule") }
        let mine = ownVerbs(hazard.verbs ?? [])
        if on("story"), has("FRAME"), mine.isEmpty, !intent { return (.guarded, "story") }
        if on("adult_scene"), mine.isEmpty, has("PARENT"), !(intent || question || has("FEAR", "HELP")), !parentAway {
            return (nil, "adult_scene")
        }
        return verdict(hazard, mine: mine)
    }

    /// Her own action verb, or (a strong object) intent or a question, or fear (her pain too, when the topic is
    /// `hurt`): a script; the word alone: a guard.
    func verdict(_ hazard: RouterData.Hazard, mine: [Int]) -> Outcome {
        if !mine.isEmpty { return (.script, "own_verb") }
        if on("ask"), hazard.strong == true, intent || question || has("FIND") { return (.script, "ask") }
        if on("fear"), has("FEAR", "HELP") || hazard.hurt == true && has("PAIN") { return (.script, "fear") }
        return (.guarded, "word")
    }
}
