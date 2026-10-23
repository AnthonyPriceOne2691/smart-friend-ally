import Foundation

extension TurnPass {
    func fits(_ chosen: [String]) -> Bool {
        guard isOn(.limits) else { return true }
        let counts = chosen.map(words)
        return chosen.count <= limits.maxSentences && chosen.filter(isQuestion).count <= limits.maxQuestions
            && counts.reduce(0, +) <= limits.maxWords && counts.allSatisfy { $0 <= limits.maxSentenceWords }
    }

    /// after_prohibition: questions after a prohibition (a closed list) are blocked as candidates; a referral stays.
    func blockedQuestions(_ cands: [String]) -> Set<Int> {
        guard isOn(.afterProhibition),
              let first = cands.firstIndex(where: { contract.prohibition.found(in: Self.norm($0)) }) else { return [] }
        return Set(cands.indices.filter {
            $0 > first && isQuestion(cands[$0]) && !(isOn(.actionReferral) && referral(cands[$0]))
        })
    }

    /// Skipped candidates: in «why», praise and question-backs after sentence 1; elsewhere, after a statement, of 2+
    /// open questions only the first guarded one (prohibition, referral) or else the last full one; connectives after
    /// them go.
    mutating func narrow(_ cands: [String]) -> [String] {
        guard let head = cands.first, isOn(why ? .whyFiller : .lastQuestion), why || !isQuestion(head) else {
            return cands
        }
        let (gone, yielded) = why ? (Set(cands.indices.dropFirst().filter { filler(cands[$0]) }), false)
            : extraQuestions(cands)
        if !gone.isEmpty { log(why ? .whyFiller : .lastQuestion) }
        if yielded { log(.ellipticTail) }
        return cands.indices.filter { !gone.contains($0) }.map { index in
            !why && gone.contains(index - 1) && isOn(.connective) ? connective(cands[index]) : cands[index]
        }
    }

    func filler(_ sentence: String) -> Bool {
        let text = Self.norm(sentence)
        return contract.filler.found(in: text) || isQuestion(sentence) && contract.fillerQ.found(in: text)
    }

    /// The open questions that go, and whether the last one yielded to a full one before it (elliptic_tail).
    func extraQuestions(_ cands: [String]) -> (gone: Set<Int>, yielded: Bool) {
        let blocked = blockedQuestions(cands)
        let open = cands.indices.dropFirst().filter { isQuestion(cands[$0]) && !blocked.contains($0) }
        let guarded = open.first { contract.prohibition.found(in: Self.norm(cands[$0])) || referral(cands[$0]) }
        guard open.count > 1, let last = open.last else { return ([], false) }
        let full = isOn(.ellipticTail) ? open.last { !elliptic(cands[$0]) } : nil
        let stay = guarded ?? full ?? last
        return (Set(open.filter { $0 != stay }), guarded == nil && stay != last)
    }

    /// elliptic_tail: a tail question that only continues the previous one — a link at the start and after it neither
    /// a question word nor a verb of its own («А слона?», «Может, про животных?»); «А ты любишь слонов?» is full.
    func elliptic(_ sentence: String) -> Bool {
        let text = Self.norm(sentence).trimmingCharacters(in: .whitespaces)
        guard let link = contract.tailLink.ranges(in: text).first, link.location == 0 else { return false }
        let rest = NSString(string: text).substring(from: link.length)
        return !contract.qword.found(in: rest) && !contract.verb.found(in: rest)
    }

    /// select: narrow, keep — in talk with the closing question's slot; a referral the model made and the cut lost
    /// comes back as the pointer script.
    mutating func select(_ cands: [String]) -> [String] {
        let cands = narrow(cands)
        var out = closing(cands) ?? keep(cands)
        if isOn(.actionReferral), cands.contains(where: referral), !out.contains(where: referral) {
            rescue(&out, as: .actionReferral)
        }
        return out
    }

    /// closing_question (target 4, refined 2026-10-18): in talk the question she hands the turn back with may come
    /// fourth, at the end. The last candidate, a question no prohibition blocks that fits with sentence 1, stays; the
    /// statements before it are kept with its question and words reserved. nil: the rule does not apply.
    mutating func closing(_ cands: [String]) -> [String]? {
        guard isOn(.closingQuestion), talk, cands.count > 1, let question = cands.last, isQuestion(question),
              !blockedQuestions(cands).contains(cands.count - 1), fits([cands[0], question]) else { return nil }
        var plain = self
        let full = limits
        limits = full.reserving(words: words(question))
        let out = keep(Array(cands.dropLast())) + [question]  // sentence 1 fits the reserved limits by the guard
        limits = full
        if out != plain.keep(cands) { log(.closingQuestion) }
        return out
    }

    /// keep: sentence 1, the adult pointer, safety sentences, then the rest in order to the first misfit.
    mutating func keep(_ cands: [String]) -> [String] {
        guard let head = cands.first else { return [] }
        guard fits([head]) else {
            log(.limits)
            return []
        }
        let blocked = blockedQuestions(cands)
        let pointers = cands.indices.dropFirst().filter { contract.pointer.found(in: Self.norm(cands[$0])) }
        let safety = cands.indices.dropFirst().filter { protects(cands[$0]) && !pointers.contains($0) }
        let pulled = (isOn(.pointerKeep) ? Array(pointers.filter { !blocked.contains($0) }.prefix(1)) : [])
            + (isOn(.safetyKeep) ? safety : [])
        let chosen = choose(cands, pulled: pulled.filter { !blocked.contains($0) }, blocked: blocked)
        for index in cands.indices where !chosen.contains(index) {
            log(blocked.contains(index) ? .afterProhibition : .limits)
        }
        var out = chosen.map { index in
            index == 0 || chosen.contains(index - 1) || !isOn(.connective) ? cands[index] : connective(cands[index])
        }
        if isOn(.pointerKeep), !pointers.isEmpty, Set(pointers).isDisjoint(with: chosen),
           !out.contains(where: { contract.pointer.found(in: Self.norm($0)) }) {
            rescue(&out, as: .pointerKeep)
        }
        return out
    }

    /// The kept indices: 0, the pulled ones that fit, then the rest in order up to the first blocked or misfit.
    func choose(_ cands: [String], pulled: [Int], blocked: Set<Int>) -> [Int] {
        var chosen = [0]
        for index in pulled where fits(pick(cands, chosen + [index])) {
            chosen.append(index)
        }
        for index in cands.indices.dropFirst() where !chosen.contains(index) {
            guard !blocked.contains(index), fits(pick(cands, chosen + [index])) else { break }
            chosen.append(index)
        }
        return chosen.sorted()
    }

    func pick(_ cands: [String], _ indices: [Int]) -> [String] { indices.sorted().map { cands[$0] } }

    /// The script after the kept sentences or in place of the last one — never invented: the model said it.
    mutating func rescue(_ out: inout [String], as rule: ContractRule) {
        let added = out + [contract.data.pointerScript], swapped = out.dropLast() + [contract.data.pointerScript]
        guard fits(added) || out.count > 1 && fits(Array(swapped)) else { return }
        out = fits(added) ? added : Array(swapped)
        log(rule)
    }

    /// strip_connective: a sentence pulled past a dropped one does not open with «Поэтому,» pointing at nothing.
    mutating func connective(_ sentence: String) -> String {
        let out = contract.connective.replacing(in: sentence, with: "")
        guard out != sentence else { return sentence }
        log(.connective)
        return Self.capitalized(out)
    }

    /// A sentence `keep` holds on to and the adult pointer never pushes out: safety, or a prohibition (closed lists).
    func protects(_ sentence: String) -> Bool {
        let text = Self.norm(sentence)
        return contract.safety.found(in: text) || isOn(.safetyProhibition) && contract.prohibition.found(in: text)
    }

    /// The canned kind: the topic's fallback when the turn keeps an adult pointer, unless it yields to the hazard's
    /// script; by the violation (for danger, the ready script of the hazard found); else the mode's.
    func fallback(_ violation: Violation?) -> String {
        if isOn(.adultPointer), let topic, let kind = contract.data.pointers[topic]?.last, !yields(kind, violation) {
            return kind
        }
        guard let violation else { return limits.canned }
        let kind = contract.data.fallbackOf[violation.rule.rawValue] ?? "generic"
        guard kind == "danger", isOn(.dangerScript),
              let word = contract.hazard.matches(in: Self.norm(violation.sentence)).first else { return kind }
        return contract.hazardScripts.first { $0.word.found(in: word) }?.script ?? kind
    }

    /// danger_over_topic: a topic's fallback with no protection of its own (fear, pain) yields when the reply was cut
    /// for a hazard how-to; «потерялась» keeps its own («стой на месте»).
    func yields(_ kind: String, _ violation: Violation?) -> Bool {
        isOn(.dangerOverTopic) && violation?.rule == .dangerHowto && !split(cannedText(kind)).contains(where: protects)
    }

    /// Nothing of the reply is left: the canned reply of `fallback`. A hazard's script that outranked the topic's
    /// fallback keeps the topic's adult pointer, added as to the model's sentences (danger_over_topic).
    mutating func cannedFallback(_ violation: Violation?) -> Turn {
        let kind = fallback(violation)
        guard isOn(.adultPointer), let own = topic.flatMap({ contract.data.pointers[$0]?.last }), kind != own else {
            return canned(kind)
        }
        log(.dangerOverTopic)
        return turn(pointed(split(cannedText(kind)), nil, ""), source: .canned(kind))
    }

    /// A canned reply of the kind, after the sentence `first` already let out.
    func canned(_ kind: String, after spoken: String? = nil) -> Turn {
        turn((spoken.map { [$0] } ?? []) + split(cannedText(kind)), source: .canned(kind))
    }

    func cannedText(_ kind: String) -> String { contract.data.canned[kind] ?? contract.data.scripts[kind] ?? "" }

    func turn(_ sentences: [String], source: TurnSource) -> Turn {
        Turn(sentences: sentences, source: source,
             record: TurnRecord(rules: fired, contractHash: contract.hash, source: source))
    }
}
