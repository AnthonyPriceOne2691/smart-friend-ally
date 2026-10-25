import Discipline
import Foundation

/// Seconds from the moment the utterance was known: first reply text, sentence 1 accepted, first `speak`, reply end.
public struct TurnTimes: Equatable, Sendable {
    public var firstText: Double?, firstSentence: Double?, firstSound: Double?, replyEnd: Double?
}

/// What a turn said and how: the contract's turn (sentences, source, record), the stage times, a model timeout; the
/// model's text before the contract — none for a script or a phrase of the session.
public struct TurnOutcome: Sendable {
    public let turn: Turn, times: TurnTimes, modelTimeout: Bool
    public var modelText: String?
}

/// One turn through the contract: sentence 1 sounds once its boundary is safe and `first` lets it out, the rest goes
/// through `finish`. A refused sentence 1 cancels the model and its canned reply sounds; no sentence in the timeout —
/// the mode's canned reply and `modelTimeout`; cancelling the turn stops the voice and the model and rethrows (П28).
/// However the turn ends, the model's memory of it becomes what sounded (`commit`, D5).
public final class TurnRunner {
    private let model: LanguageModel, voice: VoiceOutput, clock: TurnClock, mode: TurnMode, firstSentenceTimeout: Double

    public init(model: LanguageModel, voice: VoiceOutput, clock: TurnClock = SystemClock(), mode: TurnMode = .talk,
                firstSentenceTimeout: Double = 10) {
        (self.model, self.voice, self.clock, self.mode) = (model, voice, clock, mode)
        self.firstSentenceTimeout = firstSentenceTimeout
    }

    /// - Parameter decision: the router's; with her utterance it reaches the contract (her address is not echoed,
    ///   a topic's adult pointer is kept).
    public func run(_ utterance: String, decision: RouterDecision = .pass) async throws -> TurnOutcome {
        let watchdog = Watchdog(), sounded = Sounded()
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
            var state = TurnState(contract: contract, start: clock.now(), sounded: sounded)
            try await stream(utterance, into: &state, watchdog: watchdog)
            try Task.checkCancellation()
            return try await finish(&state, timedOut: watchdog.state == .fired)
        } onCancel: { [model, voice] in
            model.cancel()
            voice.stop()
        }
    }

    /// Reads the reply: sentence 1 goes through `first` and sounds at once; a refusal cancels the model.
    private func stream(_ utterance: String, into state: inout TurnState, watchdog: Watchdog) async throws {
        for try await text in model.reply(to: utterance) {
            state.text = text
            if state.times.firstText == nil, text.contains(where: \.isLetter) { state.times.firstText = elapsed(state) }
            guard state.head == .pending, let sentence = SentenceStream.first(in: text) else { continue }
            guard watchdog.move(to: .disarmed) else { return }
            guard let spoken = state.contract.first(sentence) else {
                state.head = .refused
                model.cancel()
                return
            }
            state.head = .spoken
            state.times.firstSentence = elapsed(state)
            try await say(spoken, &state)
        }
    }

    /// The rest through `finish`: after a spoken sentence 1 the turn's other sentences, else the whole turn.
    private func finish(_ state: inout TurnState, timedOut: Bool) async throws -> TurnOutcome {
        state.times.replyEnd = elapsed(state)
        let turn = state.contract.finish(timedOut ? "" : state.text)
        let rest = state.head == .spoken ? Array(turn.sentences.dropFirst()) : turn.sentences
        (voice as? VoiceLookahead)?.upcoming(rest)  // made ahead while the first sounds (Z25)
        for sentence in rest {
            try Task.checkCancellation()
            try await say(sentence, &state)
        }
        return TurnOutcome(turn: turn, times: state.times, modelTimeout: timedOut, modelText: state.text)
    }

    private func say(_ sentence: String, _ state: inout TurnState) async throws {
        if state.times.firstSound == nil { state.times.firstSound = elapsed(state) }
        try await state.sounded.say(sentence, voice)
    }

    private func elapsed(_ state: TurnState) -> Double { clock.now() - state.start }
}

/// One turn in flight: its contract, the reply so far, what became of sentence 1, the stage times, what sounded.
struct TurnState {
    enum Head { case pending, refused, spoken }
    let contract: TurnContract, start: Double, sounded: Sounded
    var text = "", head = Head.pending, times = TurnTimes()
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
