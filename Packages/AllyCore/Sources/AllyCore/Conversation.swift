import Foundation

/// What a screen draws (the console, the shell of the child screen): where the session is and why the last one ended.
public struct TalkState: Equatable, Sendable {
    /// The body's pose, for a screen that does not know the session's states.
    public enum Pose: String, Sendable { case sleeps, listens, thinks, speaks }

    public var phase: SessionState
    /// Why the last session ended — `limit`, `goodbye_word`, `rest`, `parent`, `error`; nil while one runs.
    public var ended: String?

    public init(phase: SessionState = .asleep, ended: String? = nil) { (self.phase, self.ended) = (phase, ended) }

    public var pose: Pose {
        switch phase {
        case .asleep: .sleeps
        case .listening, .windingDown: .listens
        case .thinking: .thinks
        case .greeting, .speaking, .goodbye: .speaks
        }
    }
}

/// The ear of a session, one utterance a call: her text, `""` when she spoke but no words came, nil when nobody spoke
/// before the timeout.
public protocol Listener: Sendable {
    func listen() async throws -> String?
}

/// A session with an ear: `wake` greets, then listens only while the session listens — never while she speaks — and
/// hands it what was heard, until the session sleeps; `stop` is the parent's. One listening at a time: the microphone
/// of D1.2 cannot be cancelled, so a new session waits for a stopped one's listening to end, and its late result goes
/// to a sleeping session, which takes no event of another state. A listening that fails counts as silence.
public actor Conversation {
    /// The screen's states in order: the first is the state at start, the last 8 are kept.
    public nonisolated let updates: AsyncStream<TalkState>
    private let session: Session, listener: Listener, board: Board
    private var loop: Task<Void, Never>?, running = false, starting = false

    public init(_ parts: SessionParts, settings: SessionSettings = SessionSettings(), listener: Listener) {
        let board = Board(), sink = EndWatch(sink: parts.sink, board: board)
        let watched = SessionParts(model: parts.model, voice: parts.voice, sink: sink, clock: parts.clock,
                                   router: parts.router, stamp: parts.stamp) { state in
            parts.onState(state)
            board.move(to: state)
        }
        (self.board, self.listener, updates) = (board, listener, board.stream)
        session = Session(watched, settings: settings)
    }

    /// What a screen shows now.
    public nonisolated var state: TalkState { board.state }

    /// A tap on the sleeping friend; returns when the session sleeps again. Nothing while one runs.
    public func wake() async {
        guard !starting, !running else { return }
        starting = true
        await loop?.value  // a stopped session's listening ends first: its microphone cannot be cancelled
        starting = false
        guard session.state == .asleep else { return }
        running = true
        board.begin()
        let task = Task { await self.run() }
        loop = task
        await task.value
    }

    /// The parent's stop: silence now, no phrase; a listening in flight ends on its own and its result is not taken.
    public func stop() async {
        running = false
        await session.handle(.stop)
    }

    private func run() async {
        defer { running = false }
        await session.handle(.wake)
        while session.state.listens {
            let heard = await Task { [listener] in try await listener.listen() }.result
            if case .success(let text?) = heard {
                await session.handle(.heard(text))
            } else {
                await session.handle(.silence)
            }
        }
    }
}

/// The screen's state behind a lock and its stream.
final class Board: Sendable {
    let stream: AsyncStream<TalkState>
    private let current = Locked(TalkState()), feed: AsyncStream<TalkState>.Continuation

    init() {
        (stream, feed) = AsyncStream.makeStream(of: TalkState.self, bufferingPolicy: .bufferingNewest(8))
        feed.yield(TalkState())
    }

    var state: TalkState { current { $0 } }

    func begin() { current { $0.ended = nil } }

    func end(_ reason: String) { current { $0.ended = reason } }

    func move(to phase: SessionState) {
        current { (now: inout TalkState) in
            now.phase = phase
            feed.yield(now)
        }
    }
}

/// The session's sink as the conversation sees it: every record goes on, and the one that ends a session names why —
/// it is written before the session moves to sleep.
struct EndWatch: TraceSink {
    let sink: TraceSink, board: Board

    func write(_ trace: TurnTrace) {
        if let end = trace.end { board.end(end) }
        sink.write(trace)
    }
}
