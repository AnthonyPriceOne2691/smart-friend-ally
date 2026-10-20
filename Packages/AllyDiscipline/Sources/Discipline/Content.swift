import Foundation

/// What she said this turn about where she lives and how to call her (`extract_pii` of output_filter.py, over this
/// turn's utterance only): street and surname stems of five letters, house numbers, a phone-like run.
struct Heard: Sendable {
    let text: String, stems: [String], numbers: Set<String>, phone, any: Bool

    init(_ utterance: String, _ contract: Contract) {
        let said = TurnPass.norm(utterance)
        stems = (contract.groups("pii_street", in: said) + contract.groups("pii_surname", in: said))
            .map { String($0.prefix(5)) }
        numbers = Set(contract.groups("pii_numbers", in: said).flatMap { $0.split(whereSeparator: \.isWhitespace) }
            .map(String.init))
        phone = contract.found("pii_digits", in: said)
            || contract.found("pii_run", in: said) && contract.found("pii_phone", in: said)
        text = utterance
        any = phone || !stems.isEmpty || !numbers.isEmpty || contract.found("pii_address", in: said)
    }
}

/// The content rules ported in router-people (`human_claim` is a pattern of `contract.json → content`).
extension TurnPass {
    /// pii_echo: when she named her address or phone this turn — her street, surname or house number back, a house
    /// word with a number, a phone-like run, a promise to remember.
    func echoes(_ text: String) -> Bool {
        guard heard.any else { return false }
        let toks = contract.content["pii_token"]?.first?.matches(in: text) ?? []
        let number = contract.found("pii_number", in: text)
        return heard.stems.contains { stem in stem.count >= 4 && toks.contains { $0.hasPrefix(stem) } }
            || number && (contract.found("pii_word", in: text) || !heard.numbers.isDisjoint(with: toks))
            || heard.phone && contract.found("pii_run", in: text) || contract.found("remember", in: text)
    }

    /// pii_request: a question or a request for her address, phone, surname or kindergarten; advice «только маме» is
    /// none.
    func asks(_ text: String) -> Bool {
        (isQuestion(text) || contract.found("pii_request", in: text)) && !contract.found("pii_safe_advice", in: text)
            && contract.found("pii_ask", in: text)
    }

    /// promise (`secret` of the reference): a promise to keep a secret, or urging her to hide something from mom;
    /// refusing to promise, a surprise for mom (П30) and «не говори никому свой адрес» are none.
    func promises(_ text: String) -> Bool {
        if isOn(.promiseRefusalExempt), contract.found("secret_refusal", in: text) { return false }
        return contract.found("secret", in: text) || contract.found("secret_encourage", in: text)
            && !(isOn(.surpriseExempt) && contract.found("surprise", in: text))
            && !(isOn(.adviceExempt) && contract.found("pii_advice", in: text))
    }

    /// danger_howto: a hazard with encouragement and no safety words.
    func dangerous(_ text: String) -> Bool {
        contract.hazard.found(in: text) && contract.encourage.found(in: text)
            && !(isOn(.dangerSafeExempt) && contract.dangerSafe.found(in: text))
    }

    func hasPointer(_ sentence: String) -> Bool { contract.pointer.found(in: Self.norm(sentence)) }

    /// promise_pointer (`secret_pointer` of the reference): a cut promise of a secret gets the pointer script, unless
    /// a surprise for mom was said (П30); then the topic's adult pointer (fear, lost) when no kept sentence has one:
    /// added, else in place of the tail.
    mutating func pointed(_ kept: [String], _ violation: Violation?, _ reply: String) -> [String] {
        var out = kept
        if isOn(.promisePointer), violation?.rule == .promise, !out.isEmpty, !out.contains(where: hasPointer),
           !contract.found("surprise", in: Self.norm(heard.text + " " + reply)) {
            rescue(&out, as: .promisePointer)
        }
        guard isOn(.adultPointer), let topic, let say = contract.data.pointers[topic]?.first, !out.isEmpty,
              !out.contains(where: hasPointer) else { return out }
        log(.adultPointer)
        return (0..<out.count).lazy.map { Array(out.dropLast($0)) + [say] }.first(where: fits) ?? out
    }
}
