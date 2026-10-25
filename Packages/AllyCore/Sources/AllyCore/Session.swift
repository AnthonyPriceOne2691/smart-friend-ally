import Discipline
import Foundation

/// Where the session is (spec, «Состояния»): what she does and whether the microphone is open.
public enum SessionState: String, Sendable {
    case asleep, greeting, listening, thinking, speaking, windingDown, goodbye

    /// The microphone is open only while she listens: for an utterance or, past the limit, for the last one.
    public var listens: Bool { self == .listening || self == .windingDown }
}

/// What the app tells the session: a tap woke her, the recognizer's text, silence, the parent's stop; while she
/// listens — her tentative end with the text so far and her speech coming back (D7.1).
public enum SessionEvent: Sendable {
    case wake, heard(String), silence, stop, tentative(String), resumed
}

/// What a session needs: the model and the voice, the trace sink, the clock, the router hook, the encyclopedia after it
/// (nil — no lookups), the app's stamp and a watcher of the states (the app opens the microphone by them).
public struct SessionParts: Sendable {
    public let model: LanguageModel, voice: VoiceOutput, sink: TraceSink, clock: TurnClock, router: TurnRouting
    public let knowledge: Encyclopedia?
    public let audience: Audience, stamp: @Sendable () -> TraceStamp, onState: @Sendable (SessionState) -> Void

    public init(model: LanguageModel, voice: VoiceOutput, sink: TraceSink, clock: TurnClock = SystemClock(),
                router: TurnRouting = PassThroughRouting(), knowledge: Encyclopedia? = nil,
                audience: Audience = .parent, stamp: @escaping @Sendable () -> TraceStamp = { TraceStamp() },
                onState: @escaping @Sendable (SessionState) -> Void = { _ in }) {
        (self.model, self.voice, self.sink, self.clock, self.router) = (model, voice, sink, clock, router)
        (self.knowledge, self.audience, self.stamp, self.onState) = (knowledge, audience, stamp, onState)
    }
}

/// The structure of a talk is code (П1): a canned greeting, turns through the router hook and the contract, «не
/// расслышала» and rest on misses, her goodbye and the soft limit closed by a canned goodbye — one record per turn.
/// The limit is checked at turn boundaries: a turn begun before it is finished, the first utterance after it is the
/// last turn, in `goodbye` mode; a turn with a router topic does not close the session. What Elly said last sets the
/// kind of her next turn — how long the ear waits for silence (D7).
public actor Session {
    private let parts: SessionParts, settings: SessionSettings, data = SessionData.shared, kinds = TurnKinds.shared
    private let current = Locked(SessionState.asleep), expecting = Locked(TurnKind.open)
    private var id = "", start = 0.0, count = 0, misses = 0, heard: String?, listening: TurnKind?
    private var cancel: (@Sendable () -> Void)?
    private let speculation: Speculation

    public init(_ parts: SessionParts, settings: SessionSettings = SessionSettings()) {
        (self.parts, self.settings) = (parts, settings)
        speculation = Speculation(parts.model, clock: parts.clock)
    }

    public nonisolated var state: SessionState { current { $0 } }

    /// The kind of her next turn, by what Elly said last; «не расслышала» keeps it — she says the same again.
    public nonisolated var expect: TurnKind { expecting { $0 } }

    /// One event at a time; an event of another state changes nothing. `stop` comes in while a turn runs.
    public func handle(_ event: SessionEvent) async {
        switch (state, event) {
        case (.asleep, .wake): await greet()
        case (.listening, .heard), (.windingDown, .heard), (.listening, .silence), (.windingDown, .silence):
            await answer(event)
        case (.listening, .tentative(let text)), (.windingDown, .tentative(let text)): speculate(text)
        case (.listening, .resumed), (.windingDown, .resumed): speculation.drop()
        case (let now, .stop) where now != .asleep: stop()
        default: return
        }
    }

    private var late: Bool { parts.clock.now() - start >= settings.limit }

    /// Her utterance or silence: every record it brings names the kind the ear listened with.
    private func answer(_ event: SessionEvent) async {
        listening = expect
        defer { listening = nil }
        if case .heard(let text) = event { await hear(text) } else { await missed() }
    }

    private func greet() async {
        (id, start, count, misses) = (UUID().uuidString, parts.clock.now(), 0, 0)
        if await phrase("greeting", in: .greeting) { move(to: .listening) }
    }

    /// Her utterance in her pause: the model begins its answer silently — only for an utterance the turn would give
    /// the model; a script, her goodbye and a forgotten one never reach it (D7.1).
    private func speculate(_ text: String) {
        let plan = plan(text)
        guard text.contains(where: \.isLetter), plan.toModel else { return speculation.drop() }
        speculation.start(prompt(text, plan))
    }

    /// Where her utterance goes: the router's decision, her goodbye, a script line, the encyclopedia's lookup — one
    /// answer for the turn and for the answer begun in her pause; the model gets only the rest. The encyclopedia is
    /// asked only on a «pass» that is neither her goodbye nor forgotten: a script and a guard never reach it (Э2).
    private struct Plan {
        let route: Route, goodbye: Bool, script: (key: String, line: String)?, lookup: Lookup?
        var toModel: Bool { !goodbye && script == nil && !route.forget }

        /// A hint gives the turn `why`; the last turn stays `goodbye` — its rules close the session.
        func mode(last: Bool) -> TurnMode { last ? .goodbye : lookup?.hint == nil ? .talk : .why }
    }

    private func plan(_ text: String) -> Plan {
        let route = parts.router.route(text)
        let script = route.key.flatMap { key in Router.script(for: key).map { (key: key, line: $0) } }
        let goodbye = route.decision == .pass && data.isGoodbye(text)
        let asks = route.decision == .pass && !goodbye && !route.forget
        return Plan(route: route, goodbye: goodbye, script: script, lookup: asks ? parts.knowledge?.lookup(text) : nil)
    }

    /// What the model gets: her words, with the hint's line when the encyclopedia gave one (`Knowledge.swift`).
    private func prompt(_ text: String, _ plan: Plan) -> String {
        parts.knowledge?.prompt(text, hint: plan.lookup?.hint) ?? text
    }

    private func hear(_ text: String) async {
        heard = text  // her words go with the next record, whatever it is (D3)
        guard text.contains(where: \.isLetter) else { return await missed() }
        misses = 0
        let plan = plan(text), route = plan.route, script = plan.script, last = state == .windingDown || late
        if !plan.toModel { speculation.drop() }
        if plan.goodbye { return await close("goodbye", end: "goodbye_word") }
        let head = head(script.map { "script:" + $0.key }, mode: plan.mode(last: last), route: route,
                        knowledge: plan.lookup?.record)
        move(to: .thinking)
        // A forgotten utterance never reaches the model: a script sounds as ever, else the contract's canned reply.
        let line = script?.line ?? (route.forget ? "" : nil)
        guard let outcome = await respond(text, prompt: prompt(text, plan), route: route, line: line, head: head)
        else { return }
        await after(outcome, route: route, head: head, last: last)
    }

    /// A script (or, for a forgotten utterance, nothing — the contract's canned reply) sounds without the model; else
    /// the model answers with the decision (an unknown script key — as a guard without a topic). Her utterance and the
    /// decision reach the contract either way.
    private func respond(_ text: String, prompt: String, route: Route, line: String?, head: TraceHead) async
        -> TurnOutcome? {
        if let line {
            let turn = TurnContract(mode: head.mode, heard: text, decision: route.decision).finish(line)
            move(to: .speaking)
            guard await say(turn.sentences, head) else { return nil }
            return TurnOutcome(turn: turn, times: TurnTimes(), modelTimeout: false)
        }
        let decision = route.key == nil ? route.decision : .guard(topic: nil), mode = head.mode
        let voice = Speaking(parts.voice) { self.move(to: .speaking) }
        return await perform(head) { [parts, speculation] in
            try await TurnRunner(model: speculation, voice: voice, clock: parts.clock, mode: mode)
                .run(text, decision: decision, prompt: prompt)
        }
    }

    /// A last turn without a topic closes the session with the goodbye, unless the contract has already said the
    /// mode's own canned goodbye; with a topic she listens on; else she listens — past the limit, for the last time.
    private func after(_ outcome: TurnOutcome, route: Route, head: TraceHead, last: Bool) async {
        expectAfter(outcome.turn.sentences)
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
        speculation.drop()
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
        speculation.drop()
        write(head("session:stop", mode: .talk, route: nil), nil, end: "parent")
        move(to: .asleep)
    }

    /// A phrase of the session through its mode's contract: one turn, one record.
    private func phrase(_ key: String, in next: SessionState, end: String? = nil) async -> Bool {
        let (mode, turn) = data.turn(key)
        let head = head("session:" + key, mode: mode, route: nil)
        move(to: next)
        guard await say(turn.sentences, head) else { return false }
        if key != "misheard" { expectAfter(turn.sentences) }
        write(head, TurnOutcome(turn: turn, times: TurnTimes(), modelTimeout: false), end: end)
        return true
    }

    private func expectAfter(_ sentences: [String]) {
        let next = kinds.kind(after: sentences)
        expecting { $0 = next }
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

    private func head(_ source: String?, mode: TurnMode, route: Route?, knowledge: KnowledgeRecord? = nil)
        -> TraceHead {
        count += 1
        return TraceHead(session: id, turn: count, phase: state, mode: mode, source: source, route: route,
                         knowledge: knowledge, elapsed: parts.clock.now() - start, limit: settings.limit,
                         audience: parts.audience, turnKind: listening)
    }

    private func write(_ head: TraceHead, _ outcome: TurnOutcome?, cancelled: Bool = false, error: String? = nil,
                       end: String? = nil) {
        let app = parts.stamp(), elapsed = parts.clock.now() - start
        let stamp = TraceStamp(versions: app.versions, memory: app.memory, thermal: app.thermal,
                               stages: app.stages.merging(speculation.takeStages()) { $1 })
        let words = TurnWords(heard: heard, modelText: outcome?.modelText, said: outcome?.turn.sentences,
                              elapsed: elapsed)
        heard = nil
        parts.sink.write(TurnTrace(head, outcome: outcome, stamp: stamp, cancelled: cancelled, error: error, end: end),
                         words: words)
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
