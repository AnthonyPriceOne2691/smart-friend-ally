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

/// A voice double: records each sentence; `hold` keeps `speak` suspended until `stop`.
final class RecordingVoice: VoiceOutput, @unchecked Sendable {
    private struct State { var log: [String] = [], stopped = false, held: CheckedContinuation<Void, Never>? }
    private let state = Locked(State()), hold: Bool
    var sentences: [String] { state { $0.log } }
    var stopped: Bool { state { $0.stopped } }
    init(hold: Bool = false) { self.hold = hold }

    func speak(_ sentence: String) async throws {
        state { $0.log.append(sentence) }
        guard hold else { return }
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
