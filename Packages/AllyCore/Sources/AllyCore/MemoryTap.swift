import Foundation

/// What memory takes from a session (`memory-app`, M33): her utterance the router passed to the model — no `forget`,
/// not a script or a phrase of the session — with what Elly said back, only from sessions of the given audiences; the
/// record that ends a session closes its talk. It sits beside the journal in the session's fan-out and keeps nothing.
public struct MemoryTap: TraceSink {
    /// One turn for the memory's queue: the session, the turn's number, her words and Elly's.
    public struct Heard: Equatable, Sendable {
        public let session: String, turn: Int, her: String, elly: String
    }

    private let audiences: Set<String>, take: @Sendable (Heard) -> Void, close: @Sendable (String) -> Void

    public init(audiences: Set<Audience>, take: @escaping @Sendable (Heard) -> Void,
                close: @escaping @Sendable (String) -> Void) {
        (self.audiences, self.take, self.close) = (Set(audiences.map(\.rawValue)), take, close)
    }

    public func write(_ trace: TurnTrace) { write(trace, words: TurnWords()) }

    public func write(_ trace: TurnTrace, words: TurnWords) {
        guard audiences.contains(trace.audience) else { return }
        if let route = trace.route, route.kind == "pass", !route.forget, !trace.source.hasPrefix("script:"),
           !trace.source.hasPrefix("session:"), let her = words.heard, her.contains(where: \.isLetter) {
            take(Heard(session: trace.session, turn: trace.turn, her: her,
                       elly: (words.said ?? []).joined(separator: " ")))
        }
        if trace.end != nil { close(trace.session) }
    }
}
