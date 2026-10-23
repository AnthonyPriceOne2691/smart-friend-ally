import Foundation

/// Rule ids of the contract that can be switched off (ablation), as the reference's ENABLED switches.
enum ContractRule: String, CaseIterable {
    case phone, attachment, negationExempt = "negation_exempt", pleaSafetyExempt = "plea_safety_exempt"
    case dangerHowto = "danger_howto", dangerSafeExempt = "danger_safe_exempt", dangerScript = "danger_script"
    case clauses, limits, afterProhibition = "after_prohibition", pointerKeep = "pointer_keep"
    case safetyKeep = "safety_keep", connective = "connective_strip", modes, whyFiller = "why_filler"
    case lastQuestion = "last_question", actionReferral = "action_referral", safetyProhibition = "safety_prohibition"
    case closingQuestion = "closing_question", humanClaim = "human_claim", piiEcho = "pii_echo"
    case piiRequest = "pii_request", promise, promiseRefusalExempt = "promise_refusal_exempt"
    case surpriseExempt = "surprise_exempt", adviceExempt = "advice_exempt", promisePointer = "promise_pointer"
    case adultPointer = "adult_pointer", pointerSparesSafety = "pointer_spares_safety"
    case dangerOverTopic = "danger_over_topic", ellipticTail = "elliptic_tail"
}

/// The first sentence that broke a content rule: nothing after it is spoken.
typealias Violation = (rule: ContractRule, sentence: String)

/// One turn through the contract: the mode's limits (narrowed for the statements before a closing question), the
/// rules switched off, what she said this turn, the topic whose adult pointer the turn keeps, the rule ids fired.
struct TurnPass {
    let contract: Contract, disabled: Set<String>, why: Bool, talk: Bool, heard: Heard, topic: String?
    var limits: ContractData.Limits
    private(set) var fired: [String] = []

    init(contract: Contract, mode: TurnMode, disabled: Set<String>, heard: Heard, topic: String?) {
        let mode = disabled.contains(ContractRule.modes.rawValue) ? .talk : mode
        (self.contract, self.disabled, self.heard, self.topic) = (contract, disabled, heard, topic)
        (limits, why, talk) = (contract.limits(mode), mode == .why, mode == .talk)
    }

    func isOn(_ rule: ContractRule) -> Bool { !disabled.contains(rule.rawValue) }

    /// A referral: tell / show / call / ask an adult («покажи маме»); «для взрослых» is none.
    func referral(_ text: String) -> Bool { contract.action.found(in: Self.norm(text)) }

    mutating func log(_ rule: ContractRule) { log(rule.rawValue) }

    mutating func log(_ id: String) { fired += fired.contains(id) ? [] : [id] }

    /// Repair, sentences, content rules: the clean sentences up to the first violation, and the violation.
    mutating func candidates(_ reply: String) -> ([String], Violation?) {
        let repaired = Repair.apply(reply)
        for action in repaired.actions { log(action.rule) }
        var clean: [String] = []
        for sentence in sentences(repaired.text) {
            if let rule = violation(sentence) {
                log(rule)
                return (clean, (rule, sentence))
            }
            clean.append(sentence)
        }
        return (clean, nil)
    }

    /// In the reference's order: a phone mark, a claim to be human, her address echoed or asked, a secret promised,
    /// attachment, danger how-to.
    func violation(_ sentence: String) -> ContractRule? {
        let text = Self.norm(sentence)
        let checks: [(rule: ContractRule, broken: () -> Bool)] = [
            (.phone, { sentence.contains(contract.phoneMark) }),
            (.humanClaim, { contract.found("human_claim", in: text) }), (.piiEcho, { echoes(text) }),
            (.piiRequest, { asks(text) }), (.promise, { promises(text) }), (.attachment, { attached(text) }),
            (.dangerHowto, { dangerous(text) })
        ]
        return checks.first { isOn($0.rule) && $0.broken() }?.rule
    }

    /// attachment: a match no exemption takes — an honest «я не скучаю», safety advice «никуда не уходи».
    func attached(_ text: String) -> Bool {
        contract.attachment.contains { group, patterns in
            patterns.contains { pattern in pattern.ranges(in: text).contains { !exempt(group, $0, in: text) } }
        }
    }

    func exempt(_ group: String, _ range: NSRange, in text: String) -> Bool {
        let string = NSString(string: text), start = max(0, range.location - 4)
        let inside = string.substring(with: range)
        let before = string.substring(with: NSRange(location: start, length: range.location - start))
        let negated = contract.negationInside.found(in: inside) || contract.negationBefore.found(in: before)
        return isOn(.negationExempt) && contract.data.negatable.contains(group) && negated
            || group == "plea" && isOn(.pleaSafetyExempt) && contract.pleaSafety.found(in: text)
    }

    /// split_sentences: a run up to its end marks that holds a word character.
    func split(_ text: String) -> [String] {
        contract.sentence.matches(in: text).map(Rules.shared.strip).filter(Rules.shared.wordChar.found(in:))
    }

    mutating func sentences(_ text: String) -> [String] { split(text).flatMap { splitLong($0) } }

    /// split_long: over the limit, split where both halves fit — conjunction before comma, the most balanced first.
    mutating func splitLong(_ sentence: String) -> [String] {
        guard isOn(.clauses), words(sentence) > limits.maxSentenceWords else { return [sentence] }
        let string = NSString(string: sentence)
        let points = contract.clauses.flatMap { $0.ranges(in: sentence).map { ($0.location, 0) } }
            + contract.comma.ranges(in: sentence).map { ($0.location, 1) }
        let splits = points.compactMap { at, comma -> (key: [Int], halves: (head: String, tail: String))? in
            let head = trim(string.substring(to: at), end: true), tail = trim(string.substring(from: at), end: false)
            let longest = max(words(head), words(tail))
            guard words(head) > 0, words(tail) > 0 else { return nil }
            return ([longest > limits.maxSentenceWords ? 1 : 0, comma, longest], (head, tail))
        }
        guard let (head, tail) = splits.min(by: { $0.key.lexicographicallyPrecedes($1.key) })?.halves else {
            return [sentence]
        }
        log(.clauses)
        let end = isQuestion(sentence) && words(tail) <= 2 ? "?" : "."
        return splitLong(contract.endMark.found(in: head) ? head : head + end) + splitLong(Self.capitalized(tail))
    }

    /// str.rstrip(" ,;—") at the end, str.lstrip(" ,;—") at the start.
    func trim(_ text: String, end: Bool) -> String {
        var scalars = Substring(text).unicodeScalars
        while let edge = end ? scalars.last : scalars.first, [" ", ",", ";", "—"].contains(edge) {
            _ = end ? scalars.removeLast() : scalars.removeFirst()
        }
        return String(scalars)
    }

    func words(_ text: String) -> Int { contract.words.matches(in: text.lowercased()).count }

    func isQuestion(_ text: String) -> Bool { text.unicodeScalars.suffix(3).contains("?") }

    static func norm(_ text: String) -> String { text.lowercased().replacingOccurrences(of: "ё", with: "е") }

    static func capitalized(_ text: String) -> String {
        guard let first = text.unicodeScalars.first else { return text }
        return String(first).uppercased() + String(text.unicodeScalars.dropFirst())
    }
}
