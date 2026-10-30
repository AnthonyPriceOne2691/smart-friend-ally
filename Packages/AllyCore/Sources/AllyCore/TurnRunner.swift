import Discipline
import Foundation

/// Seconds from the moment the utterance was known: first reply text, sentence 1 accepted, first `speak`, reply end;
/// on a story turn the first `speak` is the bridge, then its end and the first `speak` of the story.
public struct TurnTimes: Equatable, Sendable {
    public var firstText: Double?, firstSentence: Double?, firstSound: Double?, replyEnd: Double?
    public var bridgeEnd: Double?, storySound: Double?
}

/// What a turn said and how: the contract's turn (sentences, source, record), the stage times, a model timeout; the
/// model's text before the contract — none for a script or a phrase of the session; whether the hint's card sounded in
/// place of the reply's rest (card-fallback); the bridge of a story turn and the telling's record.
public struct TurnOutcome: Sendable {
    public let turn: Turn, times: TurnTimes, modelTimeout: Bool
    public var modelText: String?
    public var cardSaid = false
    public var bridge: String?, told: StoryStats?

    /// What Elly said: the bridge, then the turn's sentences.
    public var said: [String] { (bridge.map { [$0] } ?? []) + turn.sentences }
}

/// One turn through the contract: sentence 1 sounds once its boundary is safe and `first` lets it out, the rest goes
/// through `finish`. A refused sentence 1 cancels the model and its canned reply sounds; no sentence in the timeout —
/// the mode's canned reply and `modelTimeout`; cancelling the turn stops the voice and the model and rethrows (П28).
/// In `story` a bridge sounds first, while the model starts, and the next sentences sound as they come (`more`).
/// However the turn ends, the model's memory of it becomes what sounded (`commit`, D5).
public final class TurnRunner {
    private let model: LanguageModel, voice: VoiceOutput, clock: TurnClock, mode: TurnMode, firstSentenceTimeout: Double

    public init(model: LanguageModel, voice: VoiceOutput, clock: TurnClock = SystemClock(), mode: TurnMode = .talk,
                firstSentenceTimeout: Double = 10) {
        (self.model, self.voice, self.clock, self.mode) = (model, voice, clock, mode)
        self.firstSentenceTimeout = firstSentenceTimeout
    }

    /// - Parameters:
    ///   - decision: the router's; with her utterance it reaches the contract (her address is not echoed, a topic's
    ///     adult pointer is kept).
    ///   - prompt: what the model gets when it is not her words alone — with the encyclopedia's hint (Э2).
    ///   - card: the hint's card: when the reply's kept sentences miss its essence, its text sounds (card-fallback).
    ///   - window: what the session lets this turn say (M42): it reads the model's text before the contract.
    ///   - bridge: the story turn's phrase: it sounds at once and goes into the memory, not into the contract's turn.
    public func run(_ utterance: String, decision: RouterDecision = .pass, prompt: String? = nil,
                    card: HintCard? = nil, window: TurnWindow = .open, bridge: String? = nil) async throws
        -> TurnOutcome {
        let watchdog = Watchdog(), sounded = Sounded()
        let carded = card.map { CardTurn(card: $0, mode: mode, heard: utterance, decision: decision) }
        let timer = Task { [clock, model, firstSentenceTimeout] in
            try await clock.sleep(seconds: firstSentenceTimeout)
            if watchdog.move(to: .fired) { model.cancel() }
        }
        defer {
            timer.cancel()
            model.commit(spoken: sounded.text)  // after any cancel of the turn: the model's queue keeps the order
        }
        return try await withTaskCancellationHandler {
            let contract = TurnContract(mode: mode, heard: utterance, decision: decision)
            var state = TurnState(contract: contract, start: clock.now(), sounded: sounded, window: window)
            if let bridge { return try await tell(prompt ?? utterance, bridge, &state, watchdog: watchdog) }
            try await stream(prompt ?? utterance, into: &state, watchdog: watchdog)
            try Task.checkCancellation()
            return try await finish(&state, timedOut: watchdog.state == .fired, card: carded)
        } onCancel: { [model, voice] in
            model.cancel()
            voice.stop()
        }
    }

    /// Reads the reply to the model's input: sentence 1 goes through `first` and sounds at once; a refusal cancels it.
    private func stream(_ input: String, into state: inout TurnState, watchdog: Watchdog) async throws {
        for try await text in model.reply(to: input) {
            switch read(text, &state, watchdog: watchdog) {
            case .wait: continue
            case .over: return
            case .say(let spoken): try await say(spoken, &state)
            }
        }
    }

    /// The reply so far: what it means for sentence 1 — it is not whole yet, it sounds now, or the reading is over (the
    /// watchdog was first; a refusal cancels the model).
    private func read(_ text: String, _ state: inout TurnState, watchdog: Watchdog) -> Reading {
        state.text = text
        if state.times.firstText == nil, text.contains(where: \.isLetter) { state.times.firstText = elapsed(state) }
        guard state.head == .pending, let sentence = SentenceStream.first(in: state.window.apply(text)) else {
            return .wait
        }
        guard watchdog.move(to: .disarmed) else { return .over }
        guard let spoken = state.contract.first(sentence) else {
            state.head = .refused
            model.cancel()
            return .over
        }
        state.head = .spoken
        state.times.firstSentence = elapsed(state)
        return .say(spoken)
    }

    /// story: two hands, so the next sentences are made ahead while one sounds. One reads the reply and lets sentences
    /// out as they come whole; the other says them in order, the bridge first. The model starts before the bridge.
    private func tell(_ input: String, _ bridge: String, _ state: inout TurnState, watchdog: Watchdog) async throws
        -> TurnOutcome {
        let reply = model.reply(to: input)
        let (sentences, hand) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingOldest(32))
        let marks = StoryMarks(clock: clock, start: state.start)
        hand.yield(bridge)
        return try await withThrowingTaskGroup(of: Void.self) { saying in
            saying.addTask { [voice, sounded = state.sounded] in
                for await sentence in sentences {
                    try Task.checkCancellation()
                    marks.begins()
                    try await sounded.say(sentence, voice)
                    marks.ended()
                }
            }
            var over = false
            for try await text in reply where !over { over = letOut(text, &state, hand, watchdog: watchdog) }
            try Task.checkCancellation()
            state.times.replyEnd = elapsed(state)
            let turn = state.contract.finish(watchdog.state == .fired ? "" : state.window.apply(state.text))
            give(Array(turn.sentences.dropFirst(state.said)), hand)
            hand.finish()
            try await saying.waitForAll()
            marks.stamp(&state.times)
            var outcome = TurnOutcome(turn: turn, times: state.times, modelTimeout: watchdog.state == .fired,
                                      modelText: state.text)
            outcome.bridge = bridge
            return outcome
        }
    }

    /// story: the sentences that came whole with this text go to the hand; true — the reading is over: `stopped` or a
    /// refused sentence 1 stops the model.
    private func letOut(_ text: String, _ state: inout TurnState, _ hand: AsyncStream<String>.Continuation,
                        watchdog: Watchdog) -> Bool {
        switch read(text, &state, watchdog: watchdog) {
        case .over: return true
        case .say(let spoken):
            state.said = 1
            give([spoken], hand)
        case .wait: break
        }
        guard state.head == .spoken, !state.contract.stopped,
              let whole = SentenceStream.complete(in: state.window.apply(text), after: state.read) else { return false }
        state.read = whole.count
        let next = state.contract.more(whole)
        state.said += next.count
        give(next, hand)
        if state.contract.stopped { model.cancel() }
        return state.contract.stopped
    }

    private func give(_ sentences: [String], _ hand: AsyncStream<String>.Continuation) {
        (voice as? VoiceLookahead)?.upcoming(sentences)
        sentences.forEach { hand.yield($0) }
    }

    /// The rest through `finish`: after a spoken sentence 1 the turn's other sentences, else the whole turn — or, on a
    /// hinted turn whose kept sentences miss the card's essence, the card's text after what already sounded.
    private func finish(_ state: inout TurnState, timedOut: Bool, card: CardTurn?) async throws -> TurnOutcome {
        state.times.replyEnd = elapsed(state)
        let kept = state.contract.finish(timedOut ? "" : state.window.apply(state.text))
        let carded = card?.turn(after: kept, spoken: state.head == .spoken), turn = carded ?? kept
        let rest = state.head == .spoken ? Array(turn.sentences.dropFirst()) : turn.sentences
        (voice as? VoiceLookahead)?.upcoming(rest)  // made ahead while the first sounds (Z25)
        for sentence in rest {
            try Task.checkCancellation()
            try await say(sentence, &state)
        }
        var outcome = TurnOutcome(turn: turn, times: state.times, modelTimeout: timedOut, modelText: state.text)
        outcome.cardSaid = carded != nil
        return outcome
    }

    private func say(_ sentence: String, _ state: inout TurnState) async throws {
        if state.times.firstSound == nil { state.times.firstSound = elapsed(state) }
        try await state.sounded.say(sentence, voice)
    }

    private func elapsed(_ state: TurnState) -> Double { clock.now() - state.start }
}

/// One turn in flight: its contract, the reply so far, what became of sentence 1, the stage times, what sounded, the
/// session's window over the model's text (M42); in a story — how many of the contract's sentences went to the voice's
/// hand and how much of the reply the contract has read.
struct TurnState {
    enum Head { case pending, refused, spoken }
    let contract: TurnContract, start: Double, sounded: Sounded, window: TurnWindow
    var text = "", head = Head.pending, times = TurnTimes(), said = 0, read = 0
}

/// What the reply so far means for sentence 1.
enum Reading { case wait, over, say(String) }

/// A story's sounds as the voice's hand meets them: the bridge's start and end, the start of the next sentence.
final class StoryMarks: Sendable {
    private struct Marks { var said = 0, first: Double?, end: Double?, story: Double? }
    private let clock: TurnClock, start: Double, marks = Locked(Marks())

    init(clock: TurnClock, start: Double) { (self.clock, self.start) = (clock, start) }

    func begins() {
        let now = clock.now() - start
        marks { (m: inout Marks) in
            if m.said == 0 { m.first = m.first ?? now }
            if m.said == 1 { m.story = m.story ?? now }
        }
    }

    func ended() {
        let now = clock.now() - start
        marks { (m: inout Marks) in
            if m.said == 0 { m.end = now }
            m.said += 1
        }
    }

    func stamp(_ times: inout TurnTimes) {
        (times.firstSound, times.bridgeEnd, times.storySound) = marks { ($0.first, $0.end, $0.story) }
    }
}

/// What sounded of a turn (D5): the sentences whose `speak` returned before the turn was cancelled — one cut by a stop
/// does not count.
final class Sounded: Sendable {
    private let sentences = Locked([String]())
    var text: String { sentences { $0.joined(separator: " ") } }

    func say(_ sentence: String, _ voice: VoiceOutput) async throws {
        try await voice.speak(sentence)
        if !Task.isCancelled { sentences { $0.append(sentence) } }
    }
}

/// The first-sentence timeout: whichever of firing and disarming comes first wins.
final class Watchdog: Sendable {
    enum State { case armed, disarmed, fired }
    private let current = Locked(State.armed)
    var state: State { current { $0 } }

    func move(to next: State) -> Bool {
        current { (now: inout State) -> Bool in
            guard now == .armed else { return false }
            now = next
            return true
        }
    }
}
