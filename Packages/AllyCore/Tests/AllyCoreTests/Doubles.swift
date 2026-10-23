import AllyCore
import Foundation

/// Virtual time: `sleep` waits until `advance` moves the clock past its deadline; a cancelled sleep throws.
final class TestClock: TurnClock, @unchecked Sendable {
    private struct Sleeper { let id: Int, until: Double, wake: CheckedContinuation<Void, Error> }
    private struct State { var time = 0.0, nextId = 0, gone: Set<Int> = [], sleepers: [Sleeper] = [] }
    private let state = Locked(State())

    func now() -> Double { state { $0.time } }
    var sleeping: Int { state { $0.sleepers.count } }

    func sleep(seconds: Double) async throws {
        let id = state { (s: inout State) -> Int in s.nextId += 1; return s.nextId }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (wake: CheckedContinuation<Void, Error>) in
                let gone = state { (s: inout State) -> Bool in
                    if !s.gone.contains(id) { s.sleepers.append(Sleeper(id: id, until: s.time + seconds, wake: wake)) }
                    return s.gone.contains(id)
                }
                if gone { wake.resume(throwing: CancellationError()) }
            }
        } onCancel: {
            self.state { (s: inout State) -> CheckedContinuation<Void, Error>? in
                s.gone.insert(id)
                return s.sleepers.firstIndex { $0.id == id }.map { s.sleepers.remove(at: $0).wake }
            }?.resume(throwing: CancellationError())
        }
    }

    func advance(by seconds: Double) {
        state { (s: inout State) -> [Sleeper] in
            s.time += seconds
            let time = s.time, ready = s.sleepers.filter { $0.until <= time + 1e-9 }
            s.sleepers.removeAll { $0.until <= time + 1e-9 }
            return ready
        }.forEach { $0.wake.resume() }
    }
}

/// A model double: plays a script — a virtual wait, text appended, a hang — as accumulated text; `cancel` ends it.
final class ScriptedModel: LanguageModel, @unchecked Sendable {
    enum Step { case wait(Double), say(String), hang }

    private let steps: [Step], clock: TurnClock, state = Locked<(cancelled: Bool, ending: () -> Void)>((false, {}))
    var cancelled: Bool { state { $0.cancelled } }
    init(_ steps: [Step], clock: TurnClock) { (self.steps, self.clock) = (steps, clock) }

    /// The reply typed one character at a time: the runner sees every prefix.
    static func typing(_ reply: String, clock: TurnClock) -> ScriptedModel {
        ScriptedModel(reply.map { .say(String($0)) }, clock: clock)
    }

    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingOldest(10_000))
        let producer = Task { [steps, clock] in
            var text = ""
            for step in steps where !Task.isCancelled {
                switch step {
                case .wait(let seconds): try? await clock.sleep(seconds: seconds)
                case .say(let piece): text += piece; output.yield(text)
                case .hang: try? await clock.sleep(seconds: 1e9)
                }
            }
            output.finish()
        }
        state { $0.ending = { producer.cancel(); output.finish() } }
        return stream
    }

    func cancel() {
        state { $0.cancelled = true }
        state { $0.ending }()
    }
}

/// A voice double: records each sentence and runs `tick` (a session moves virtual time by it); `hold` keeps `speak`
/// suspended until `stop`, from the sentence after the first `from`.
final class RecordingVoice: VoiceOutput, @unchecked Sendable {
    private struct State { var log: [String] = [], stopped = false, held: CheckedContinuation<Void, Never>? }
    private let state = Locked(State()), hold: Bool, from: Int, tick: @Sendable () -> Void
    var sentences: [String] { state { $0.log } }
    var stopped: Bool { state { $0.stopped } }
    init(hold: Bool = false, from: Int = 0, tick: @escaping @Sendable () -> Void = {}) {
        (self.hold, self.from, self.tick) = (hold, from, tick)
    }

    func speak(_ sentence: String) async throws {
        let count = state { (s: inout State) -> Int in
            s.log.append(sentence)
            return s.log.count
        }
        tick()
        guard hold, count > from else { return }
        await withCheckedContinuation { (wake: CheckedContinuation<Void, Never>) in
            if state({ (s: inout State) -> Bool in
                if !s.stopped { s.held = wake }
                return s.stopped
            }) { wake.resume() }
        }
    }

    func stop() {
        state { (s: inout State) -> CheckedContinuation<Void, Never>? in
            s.stopped = true
            defer { s.held = nil }
            return s.held
        }?.resume()
    }
}

/// Waits (real time, up to 10 s) until the condition holds — the runner moves on its own tasks.
func eventually(_ condition: () -> Bool) async {
    for _ in 0..<10_000 where !condition() { try? await Task.sleep(nanoseconds: 1_000_000) }
}

/// A model double for sessions: each call answers the next reply at once (the last one again when they run out);
/// `fails` ends every reply with an error that is not a cancellation.
final class ReplyQueue: LanguageModel, @unchecked Sendable {
    private struct State { var replies: [String], calls = 0, cancelled = false, ending: () -> Void = {} }
    private let state: Locked<State>, fails: Bool
    var calls: Int { state { $0.calls } }
    var cancelled: Bool { state { $0.cancelled } }
    init(_ replies: [String], fails: Bool = false) { (state, self.fails) = (Locked(State(replies: replies)), fails) }

    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingOldest(10))
        let text = state { (s: inout State) -> String in
            s.calls += 1
            s.ending = { output.finish() }
            return s.replies.count > 1 ? s.replies.removeFirst() : s.replies.first ?? ""
        }
        if fails {
            output.finish(throwing: ReplyFailure())
        } else {
            output.yield(text)
            output.finish()
        }
        return stream
    }

    func cancel() {
        state { (s: inout State) -> () -> Void in
            s.cancelled = true
            return s.ending
        }()
    }
}

struct ReplyFailure: Error {}

/// A router double: a decision by the whole utterance, a pass otherwise.
struct TableRouter: TurnRouting {
    let table: [String: Route]
    func route(_ utterance: String) -> Route { table[utterance] ?? Route(.pass) }
}

/// A trace sink double: keeps every record.
final class RecordingSink: TraceSink, @unchecked Sendable {
    private let state = Locked([TurnTrace]())
    var records: [TurnTrace] { state { $0 } }
    func write(_ trace: TurnTrace) { state { $0.append(trace) } }
}

/// The states a session went through, in order.
final class StateLog: @unchecked Sendable {
    private let state = Locked([SessionState]())
    var log: [SessionState] { state { $0 } }
    func record(_ next: SessionState) { state { $0.append(next) } }
}

extension TestClock {
    func advance(to time: Double) { advance(by: time - now()) }
}

/// An ear double: answers from a script — her text, `""` or silence (nil), at a virtual time if one is given; a held
/// answer waits for `release`. It notes the screen's phase at each call, the most calls at once and the listenings
/// during which she said something.
final class ScriptedEar: Listener, @unchecked Sendable {
    struct Answer { var text: String?, at: Double?, held = false }
    private struct State {
        var answers: [Answer], phases: [SessionState] = [], inFlight = 0, most = 0, overlaps = 0
        var gate: CheckedContinuation<Void, Never>?, open = false
    }
    private let state: Locked<State>, clock: TestClock, voice: RecordingVoice
    private let phase = Locked<@Sendable () -> SessionState>({ .asleep })

    init(_ answers: [Answer], clock: TestClock, voice: RecordingVoice) {
        (state, self.clock, self.voice) = (Locked(State(answers: answers)), clock, voice)
    }

    func watch(_ conversation: Conversation) { phase { $0 = { conversation.state.phase } } }

    var calls: Int { state { $0.phases.count } }
    var phases: [SessionState] { state { $0.phases } }
    var most: Int { state { $0.most } }
    var overlaps: Int { state { $0.overlaps } }

    func listen() async throws -> String? {
        let now = phase { $0 }(), spoken = voice.sentences.count
        let answer = state { (s: inout State) -> Answer in
            s.phases.append(now)
            s.inFlight += 1
            s.most = max(s.most, s.inFlight)
            return s.answers.isEmpty ? Answer(text: nil) : s.answers.removeFirst()
        }
        if answer.held { await hold() }
        if let at = answer.at { clock.advance(to: at) }
        let said = voice.sentences.count != spoken
        state { (s: inout State) in
            s.inFlight -= 1
            s.overlaps += said ? 1 : 0
        }
        return answer.text
    }

    /// Lets the held listening answer.
    func release() {
        state { (s: inout State) -> CheckedContinuation<Void, Never>? in
            guard let gate = s.gate else {
                s.open = true
                return nil
            }
            s.gate = nil
            return gate
        }?.resume()
    }

    private func hold() async {
        await withCheckedContinuation { (wake: CheckedContinuation<Void, Never>) in
            let open = state { (s: inout State) -> Bool in
                guard s.open else {
                    s.gate = wake
                    return false
                }
                s.open = false
                return true
            }
            if open { wake.resume() }
        }
    }
}

/// SplitMix64: a fixed seed gives the same tape on every run.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

/// A disk double for the black box: files in memory (bytes, or a size alone for an old preloaded file), the writes in
/// order, a failure on the write whose path ends with `failOn`, and the flag «out of the backup and protected».
final class MemoryDisk: BlackBoxDisk, @unchecked Sendable {
    private struct State { var files: [String: Data] = [:], sizes: [String: Int] = [:], order: [String] = [] }
    private let state: Locked<State>, failOn: String?
    let isPrivate: Bool

    init(isPrivate: Bool = true, preload sizes: [String: Int] = [:], failOn: String? = nil) {
        (state, self.isPrivate, self.failOn) = (Locked(State(sizes: sizes)), isPrivate, failOn)
    }

    var paths: [String] { state { (Array($0.files.keys) + Array($0.sizes.keys)).sorted() } }
    var order: [String] { state { $0.order } }
    func data(_ path: String) -> Data? { state { $0.files[path] } }

    func files() throws -> [String: Int] { state { $0.files.mapValues(\.count).merging($0.sizes) { new, _ in new } } }

    func write(_ data: Data, to path: String) throws {
        if let failOn, path.hasSuffix(failOn) { throw DiskFailure() }
        state { (s: inout State) in
            s.files[path] = data
            s.order.append(path)
        }
    }

    func remove(_ path: String) throws {
        let gone = { (key: String) in key == path || key.hasPrefix(path + "/") }
        state { (s: inout State) in
            s.files = s.files.filter { !gone($0.key) }
            s.sizes = s.sizes.filter { !gone($0.key) }
        }
    }
}

struct DiskFailure: Error {}

/// A tape double: the queued recordings, one per take; nil when they run out.
final class QueueTape: VoiceTape, @unchecked Sendable {
    private let state: Locked<[RecordedVoice]>
    init(_ recordings: [RecordedVoice]) { state = Locked(recordings) }
    func take() -> RecordedVoice? { state { $0.isEmpty ? nil : $0.removeFirst() } }
}

/// A model double that thinks `delay` of virtual time, then answers the whole reply at once.
final class TimedReply: LanguageModel, @unchecked Sendable {
    private let text: String, delay: Double, clock: TestClock
    init(_ text: String, after delay: Double, clock: TestClock) {
        (self.text, self.delay, self.clock) = (text, delay, clock)
    }

    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingOldest(10))
        clock.advance(by: delay)
        output.yield(text)
        output.finish()
        return stream
    }

    func cancel() {}
}
