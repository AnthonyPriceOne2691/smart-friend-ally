import Foundation

/// The hint's frame and its place by her words, from `encyclopedia.json`: before them — format A of Э2, after — B.
struct HintFrame: Sendable {
    let text: String, before: Bool
}

extension Encyclopedia {
    /// Her utterance as the model gets it: with a hint, the frame and the card's answer on a line before her words, or
    /// after them by `hint_place`; without a hint — her words byte for byte, as before Э2.
    public func prompt(_ utterance: String, hint: String?) -> String {
        guard let hint, let frame else { return utterance }
        let line = frame.text + hint
        return frame.before ? line + "\n" + utterance : utterance + "\n" + line
    }
}
