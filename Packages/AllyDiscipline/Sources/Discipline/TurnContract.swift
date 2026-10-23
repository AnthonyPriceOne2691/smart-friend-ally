import Foundation

/// The turn mode sets the limits: in `talk` a closing question may come fourth, `why` gives facts more words,
/// `goodbye` has no question.
public enum TurnMode: String, CaseIterable, Sendable { case talk, why, goodbye }

/// Who speaks: the model's sentences or a canned reply of a kind («generic», «attachment», a hazard script).
public enum TurnSource: Equatable, Sendable { case model, canned(String) }

/// The journal of a turn: rule ids, data hash, source — never a word of the dialogue (the model may echo the girl).
public struct TurnRecord: Equatable, Sendable {
    public let rules: [String], contractHash: String, source: TurnSource
}

/// What goes to the voice, sentence by sentence, and its record.
public struct Turn: Equatable, Sendable {
    public let sentences: [String], source: TurnSource, record: TurnRecord
}

/// What of the reply reaches the voice, one per turn: `contract` of local/spike/discipline/output_filter.py over
/// `Repair`. `first` lets sentence 1 out at once, `finish` keeps it as spoken; nothing left is a canned reply.
public final class TurnContract {
    private let mode: TurnMode, contract: Contract, disabled: Set<String>, heard: Heard, topic: String?
    private var head: (spoken: String?, violation: Violation?)?

    /// - Parameters:
    ///   - heard: her utterance this turn: her address is not echoed, a surprise for mom keeps a secret unrebuked.
    ///   - decision: the router's; a script or guard of a topic of `contract.json → pointers` (fear, lost) keeps an
    ///     adult pointer in the reply, and its fallback when nothing is left.
    public convenience init(mode: TurnMode, heard: String = "", decision: RouterDecision = .pass) {
        self.init(mode: mode, contract: .shared, heard: heard, decision: decision)
    }

    init(mode: TurnMode, contract: Contract, disabled: Set<String> = [], heard: String = "",
         decision: RouterDecision = .pass) {  // disabled: rule ids off (ablation)
        self.mode = mode
        self.contract = contract
        self.disabled = disabled
        self.heard = Heard(heard, contract)
        topic = Self.topic(decision).flatMap { contract.data.pointers[$0] == nil ? nil : $0 }
    }

    static func topic(_ decision: RouterDecision) -> String? {
        switch decision {
        case .script(let key): return key
        case .guard(let topic): return topic
        case .pass: return nil
        }
    }

    /// Sentence 1 after Repair, content rules and limits, to speak at once; nil: nothing of this reply is spoken.
    public func first(_ sentence: String) -> String? {
        var pass = TurnPass(contract: contract, mode: mode, disabled: disabled, heard: heard, topic: topic)
        let (clean, violation) = contract.healthy ? pass.candidates(sentence) : ([], nil)
        let spoken = clean.first.flatMap { pass.fits([$0]) && Rules.shared.cyrillicLetter.found(in: $0) ? $0 : nil }
        head = (spoken, clean.isEmpty ? violation : nil)
        return spoken
    }

    /// The whole reply: the sentences to speak (the first as `first` gave it) or a canned reply, with the record.
    public func finish(_ reply: String) -> Turn {
        var pass = TurnPass(contract: contract, mode: mode, disabled: disabled, heard: heard, topic: topic)
        guard contract.healthy else {
            pass.log("selftest_failed")
            return pass.canned(pass.fallback(nil))
        }
        var (clean, violation) = pass.candidates(reply)
        if let head {
            clean = head.spoken.map { [$0] + clean.dropFirst() } ?? []
            violation = head.spoken == nil ? head.violation : violation
        }
        if violation?.rule == .humanClaim { return pass.canned(pass.fallback(violation), after: head?.spoken) }
        let kept = pass.pointed(pass.select(clean), violation, reply)
        guard kept.contains(where: Rules.shared.cyrillicLetter.found(in:)) else {
            return pass.cannedFallback(violation)
        }
        return pass.turn(kept, source: .model)
    }
}
