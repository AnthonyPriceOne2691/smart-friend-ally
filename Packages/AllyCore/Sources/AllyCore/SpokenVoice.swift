import Foundation

/// The app's own voice of a turn (voice series V4b2): each sentence through the renderer and the player.
/// - The first sound of a turn and the stages of its first sentence go to the journal (Z21).
/// - Sentences are `gap` seconds apart from the end of the previous sound; `upcoming` makes them ahead (Z25).
/// - `stop` silences the player at once; a sentence still in synthesis does not sound; the next turn does (Z24).
/// - What sounded goes to the port, with a cut sign on a stop (Z23).
public final class SpokenVoice: VoiceOutput, VoiceLookahead, @unchecked Sendable {
    private typealias Sound = RenderedLater
    private struct State {
        var generation = 0, firstOfTurn = true, firstSound: Double?, stages: [String: Double] = [:], lastEnd: Double?
        var lead = 0.0  // the player's start latency last measured: the pause is counted between sounds
        var ready: [String: Sound] = [:]
    }
    private struct Order { let generation: Int, first: Bool, sound: Sound }

    private let renderer: SentenceRenderer, player: SoundPlayer, gap: Double, clock: TurnClock, sink: PlayedSound?
    private let queue: RenderQueue, state = Locked(State())

    public init(renderer: SentenceRenderer, player: SoundPlayer, gap: Double, clock: TurnClock = SystemClock(),
                sink: PlayedSound? = nil, queue: RenderQueue = SerialRenderQueue()) {
        (self.renderer, self.player, self.gap, self.clock, self.sink) = (renderer, player, gap, clock, sink)
        self.queue = queue
    }

    /// Host seconds of the first sound since `resetFirstSound`.
    public var firstSound: Double? { state { $0.firstSound } }

    /// A new turn: its first sentence sounds without a pause and brings the stages.
    public func resetFirstSound() {
        state { (s: inout State) in (s.firstOfTurn, s.firstSound, s.stages, s.lastEnd) = (true, nil, [:], nil) }
    }

    /// The stages of the turn's first sentence, once.
    public func takeStages() -> [String: Double] {
        state { (s: inout State) -> [String: Double] in
            defer { s.stages = [:] }
            return s.stages
        }
    }

    /// Makes the sentences' sound ahead, one at a time; the first of a turn not yet begun gets the first steps.
    public func upcoming(_ sentences: [String]) {
        state { (s: inout State) in
            for (index, sentence) in sentences.enumerated() where s.ready[sentence] == nil {
                s.ready[sentence] = enqueue(sentence, first: s.firstOfTurn && index == 0)
            }
        }
    }

    public func speak(_ sentence: String) async throws {
        let order = state { (s: inout State) -> Order in
            let first = s.firstOfTurn
            s.firstOfTurn = false
            return Order(generation: s.generation, first: first,
                         sound: s.ready.removeValue(forKey: sentence) ?? enqueue(sentence, first: first))
        }
        let (generation, first, sound) = (order.generation, order.first, try await order.sound.value())
        // A stop landing in the microseconds between this check and the player's start is missed — far below a tap.
        guard try await pause(generation) else { return }
        let asked = clock.now()
        let played = await player.play(sound.samples, rate: sound.rate)
        state { (s: inout State) in
            s.lastEnd = clock.now()
            s.lead = played.started.map { $0 - asked } ?? s.lead
            guard first else { return }
            s.firstSound = played.started
            s.stages = sound.stages.merging(["voice_start": (played.started ?? asked) - asked]) { $1 }
        }
        sink?.played(Array(sound.samples.prefix(played.frames)), rate: sound.rate)
        if played.cut { sink?.cut() }
    }

    /// Silence now: the sentences made ahead are dropped, a synthesis in flight finishes in the background unheard.
    public func stop() {
        state { (s: inout State) in
            s.generation += 1
            s.ready.removeAll()
        }
        player.stop()
    }

    /// The pause after the previous sentence's sound, its start latency counted; false when a stop came since the
    /// sentence was asked for.
    private func pause(_ generation: Int) async throws -> Bool {
        let (lastEnd, lead) = state { ($0.lastEnd, $0.lead) }
        if let lastEnd, lastEnd + gap - lead > clock.now() {
            try await clock.sleep(seconds: lastEnd + gap - lead - clock.now())
        }
        return state { $0.generation == generation }
    }

    /// The render goes to the queue now, in the order asked — one at a time, off the cooperative pool.
    private func enqueue(_ sentence: String, first: Bool) -> Sound {
        let later = RenderedLater(), renderer = renderer
        queue.run { later.finish(Result { try renderer.render(sentence, first: first) }) }
        return later
    }
}

/// A render's result that one `speak` awaits: whichever of the result and the waiter comes first.
final class RenderedLater: @unchecked Sendable {
    private struct State {
        var result: Result<RenderedSentence, Error>?, waiter: CheckedContinuation<RenderedSentence, Error>?
    }
    private let state = Locked(State())

    func finish(_ result: Result<RenderedSentence, Error>) {
        state { (s: inout State) -> CheckedContinuation<RenderedSentence, Error>? in
            s.result = result
            defer { s.waiter = nil }
            return s.waiter
        }?.resume(with: result)
    }

    func value() async throws -> RenderedSentence {
        try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<RenderedSentence, Error>) in
            let ready = state { (s: inout State) -> Result<RenderedSentence, Error>? in
                if s.result == nil { s.waiter = waiter }
                return s.result
            }
            if let ready { waiter.resume(with: ready) }
        }
    }
}

/// Where renders run: one at a time, so one synthesis is in memory.
public protocol RenderQueue: Sendable {
    func run(_ work: @escaping @Sendable () -> Void)
}

/// A serial queue of its own, off the cooperative pool: a second of synthesis does not hold a pool thread.
public struct SerialRenderQueue: RenderQueue {
    private let queue = DispatchQueue(label: "ally.voice.render", qos: .userInitiated)
    public init() {}
    public func run(_ work: @escaping @Sendable () -> Void) { queue.async(execute: work) }
}
