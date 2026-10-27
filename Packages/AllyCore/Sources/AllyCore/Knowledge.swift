import Foundation

/// The hint's frame from `encyclopedia.json`; it goes on a line after her words — format B of Э2 (P18, decision of the
/// parent 2026-10-27: format A, before her words, read to the model as her own words and is gone).
struct HintFrame: Sendable {
    let text: String
}

extension Encyclopedia {
    /// Her utterance as the model gets it: with a hint, her words and then the frame and the card's answer on a line of
    /// their own; without a hint — her words byte for byte, as before Э2.
    public func prompt(_ utterance: String, hint: String?) -> String {
        guard let hint, let frame else { return utterance }
        return utterance + "\n" + frame.text + hint
    }
}
