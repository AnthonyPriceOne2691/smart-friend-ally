import Discipline
import Foundation

/// Where the session is (spec, «Состояния»): what she does and whether the microphone is open.
public enum SessionState: String, Sendable {
    case asleep, greeting, listening, thinking, speaking, windingDown, goodbye

    /// The microphone is open only while she listens: for an utterance or, past the limit, for the last one.
    public var listens: Bool { self == .listening || self == .windingDown }
}

/// What the app tells the session: a tap woke her, the recognizer's text, silence, the parent's stop.
public enum SessionEvent: Sendable {
    case wake, heard(String), silence, stop
}

/// What a session needs: the model and the voice, the trace sink, the clock, the router hook, the app's stamp and a
/// watcher of the states (the app opens the microphone by them).
public struct SessionParts: Sendable {
    public let model: LanguageModel, voice: VoiceOutput, sink: TraceSink, clock: TurnClock, router: TurnRouting
    public let stamp: @Sendable () -> TraceStamp, onState: @Sendable (SessionState) -> Void

    public init(model: LanguageModel, voice: VoiceOutput, sink: TraceSink, clock: TurnClock = SystemClock(),
                router: TurnRouting = PassThroughRouting(),
                stamp: @escaping @Sendable () -> TraceStamp = { TraceStamp() },
                onState: @escaping @Sendable (SessionState) -> Void = { _ in }) {
        (self.model, self.voice, self.sink, self.clock, self.router) = (model, voice, sink, clock, router)
        (self.stamp, self.onState) = (stamp, onState)
    }
}

/// The structure of a talk is code (П1): a canned greeting, turns through the router hook and the contract, «не
/// расслышала» and rest on misses, her goodbye and the soft limit closed by a canned goodbye — one record per turn.
/// The limit is checked at turn boundaries: a turn begun before it is finished, the first utterance after it is the
/// last turn, in `goodbye` mode; a turn with a router topic does not close the session.
public actor Session {
    private let parts: SessionParts, settings: SessionSettings, data = SessionData.shared
    private let current = Locked(SessionState.asleep)
    private var id = "", start = 0.0, count = 0, misses = 0, cancel: (@Sendable () -> Void)?

    public init(_ parts: SessionParts, settings: SessionSettings = SessionSettings()) {
        (self.parts, self.settings) = (parts, settings)
    }

    public nonisolated var state: SessionState { current { $0 } }

    /// One event at a time; an event of another state changes nothing. `stop` comes in while a turn runs.
    public func handle(_ event: SessionEvent) async {
        switch (state, event) {
        case (.asleep, .wake): await greet()
        case (.listening, .heard(let text)), (.windingDown, .heard(let text)): await hear(text)
        case (.listening, .silence), (.windingDown, .silence): await missed()
        case (let now, .stop) where now != .asleep: stop()
        default: return
        }
    }

    private var late: Bool { parts.clock.now() - start >= settings.limit }

    private func greet() async {
        (id, start, count, misses) = (UUID().uuidString, parts.clock.now(), 0, 0)
        if await phrase("greeting", in: .greeting) { move(to: .listening) }
    }

    private func hear(_ text: String) async {
        guard text.contains(where: \.isLetter) else { return await missed() }
        misses = 0
        let route = parts.router.route(text), last = state == .windingDown || late
        if route.decision == .pass, data.isGoodbye(text) { return await close("goodbye", end: "goodbye_word") }
        let script = route.key.flatMap { key in Router.script(for: key).map { (key: key, line: $0) } }
        let head = head(script.map { "script:" + $0.key }, mode: last ? .goodbye : .talk, route: route)
        move(to: .thinking)
        // A forgotten utterance never reaches the model: a script sounds as ever, else the contract's canned reply.
        let line = script?.line ?? (route.forget ? "" : nil)
        guard let outcome = await respond(text, route: route, line: line, head: head) else { return }
        await after(outcome, route: route, head: head, last: last)
    }

    /// A script (or, for a forgotten utterance, nothing — the contract's canned reply) sounds without the model; else
    /// the model answers with the decision (an unknown script key — as a guard without a topic). Her utterance and the
    /// decision reach the contract either way.
    private func respond(_ text: String, route: Route, line: String?, head: TraceHead) async -> TurnOutcome? {
        if let line {
            let turn = TurnContract(mode: head.mode, heard: text, decision: route.decision).finish(line)
            move(to: .speaking)
            guard await say(turn.sentences, head) else { return nil }
            return TurnOutcome(turn: turn, times: TurnTimes(), modelTimeout: false)
        }
        let decision = route.key == nil ? route.decision : .guard(topic: nil), mode = head.mode
        let voice = Speaking(parts.voice) { self.move(to: .speaking) }
        return await perform(head) { [parts] in
            try await TurnRunner(model: parts.model, voice: voice, clock: parts.clock, mode: mode)
                .run(text, decision: decision)
        }
    }

    /// A last turn without a topic closes the session with the goodbye, unless the contract has already said the
    /// mode's own canned goodbye; with a topic she listens on; else she listens — past the limit, for the last time.
    private func after(_ outcome: TurnOutcome, route: Route, head: TraceHead, last: Bool) async {
        guard last, route.decision == .pass else {
            write(head, outcome)
            return move(to: last || late ? .windingDown : .listening)
        }
        let said = outcome.turn.source == TurnContract(mode: .goodbye).finish("").source
        write(head, outcome, end: said ? "limit" : nil)
        if said { return move(to: .asleep) }
        await close("goodbye", end: "limit")
    }

    private func missed() async {
        if state == .windingDown || late { return await close("goodbye", end: "limit") }
        misses += 1
        if misses >= data.missesBeforeRest { return await close("rest", end: "rest") }
        if await phrase("misheard", in: .speaking) { move(to: .listening) }
    }

    private func close(_ key: String, end: String) async {
        if await phrase(key, in: .goodbye, end: end) { move(to: .asleep) }
    }

    private func stop() {
        if let cancel { return cancel() }
        write(head("session:stop", mode: .talk, route: nil), nil, end: "parent")
        move(to: .asleep)
    }

    /// A phrase of the session through its mode's contract: one turn, one record.
    private func phrase(_ key: String, in next: SessionState, end: String? = nil) async -> Bool {
        let (mode, turn) = data.turn(key)
        let head = head("session:" + key, mode: mode, route: nil)
        move(to: next)
        guard await say(turn.sentences, head) else { return false }
        write(head, TurnOutcome(turn: turn, times: TurnTimes(), modelTimeout: false), end: end)
        return true
    }

    private func say(_ sentences: [String], _ head: TraceHead) async -> Bool {
        let voice = parts.voice
        let speak: @Sendable () async throws -> Void = {
            for sentence in sentences {
                try Task.checkCancellation()
                try await voice.speak(sentence)
            }
        }
        return await perform(head) { try await withTaskCancellationHandler(operation: speak) { voice.stop() } } != nil
    }

    /// The turn's work as the one child task `stop` cancels. A cancellation ends the session with one record
    /// `cancelled`, a failure with one record `error`, and neither says a phrase. Only these two are caught: the first
    /// is the session's own stop, the second is named in the record (П28).
    private func perform<Value: Sendable>(_ head: TraceHead, _ work: @escaping @Sendable () async throws -> Value)
        async -> Value? {
        let task = Task(operation: work)
        cancel = { task.cancel() }
        defer { cancel = nil }
        do {
            let value = try await task.value
            if task.isCancelled { throw CancellationError() }
            return value
        } catch is CancellationError {
            write(head, nil, cancelled: true, end: "parent")
        } catch {
            write(head, nil, error: String(describing: type(of: error)), end: "error")
        }
        move(to: .asleep)
        return nil
    }

    private func head(_ source: String?, mode: TurnMode, route: Route?) -> TraceHead {
        count += 1
        return TraceHead(session: id, turn: count, phase: state, mode: mode, source: source, route: route,
                         elapsed: parts.clock.now() - start, limit: settings.limit)
    }

    private func write(_ head: TraceHead, _ outcome: TurnOutcome?, cancelled: Bool = false, error: String? = nil,
                       end: String? = nil) {
        let stamp = parts.stamp()
        parts.sink.write(TurnTrace(head, outcome: outcome, stamp: stamp, cancelled: cancelled, error: error, end: end))
    }

    nonisolated func move(to next: SessionState) {
        current { $0 = next }
        parts.onState(next)
    }
}

/// The voice of a model turn: its first `speak` moves the session from thinking to speaking.
final class Speaking: VoiceOutput {
    private let voice: VoiceOutput, first: @Sendable () -> Void, spoke = Locked(false)

    init(_ voice: VoiceOutput, first: @escaping @Sendable () -> Void) { (self.voice, self.first) = (voice, first) }

    func speak(_ sentence: String) async throws {
        let isFirst = spoke { (done: inout Bool) -> Bool in
            defer { done = true }
            return !done
        }
        if isFirst { first() }
        try await voice.speak(sentence)
    }

    func stop() { voice.stop() }
}
