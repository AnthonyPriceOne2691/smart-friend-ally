import Foundation

/// The model's answer begun in her pause (D7.1): `start` asks the model on the text of her tentative end and keeps the
/// newest text; the turn at the tail takes it when her words are the same (letters only), else it is dropped — a
/// cancelled turn leaves the model's memory (`LlamaModel`). An answer the model finished before it was dropped stays in
/// that memory until D5 and is counted (`spec_stale`).
final class Speculation: LanguageModel, @unchecked Sendable {
    private struct Pending {
        let id: Int, words: String, start: Double
        var latest: String?, finished = false, failure: Error?
        var takers: [AsyncThrowingStream<String, Error>.Continuation] = []
    }
    private struct Counts { var started = false, reused = false, lead = 0.0, cancels = 0, stale = 0 }
    private struct State { var pending: Pending?, task: Task<Void, Never>?, next = 0, counts = Counts() }

    private let model: LanguageModel, clock: TurnClock, state = Locked(State())

    init(_ model: LanguageModel, clock: TurnClock) { (self.model, self.clock) = (model, clock) }

    /// Her tentative end: a new answer on these words, anything begun before is dropped.
    func start(_ utterance: String) {
        drop()
        let stream = model.reply(to: utterance), begun = clock.now()
        let id = state { (now: inout State) -> Int in
            now.next += 1
            now.pending = Pending(id: now.next, words: Self.letters(utterance), start: begun)
            now.counts.started = true
            return now.next
        }
        let task = Task { [weak self] in
            do {
                for try await text in stream { self?.got(text, id) }
                self?.ended(nil, id)
            } catch {
                self?.ended(error, id)
            }
        }
        state { $0.task = task }
    }

    /// The begun answer is not needed: she went on, said nothing, said something else, or the parent stopped her.
    func drop() {
        let (task, running) = state { (now: inout State) -> (Task<Void, Never>?, Bool) in
            guard let pending = now.pending else { return (nil, false) }
            defer { (now.pending, now.task) = (nil, nil) }
            now.counts.cancels += 1
            now.counts.stale += pending.finished ? 1 : 0
            return (now.task, !pending.finished)
        }
        if running { model.cancel() }
        task?.cancel()
    }

    func reply(to utterance: String) -> AsyncThrowingStream<String, Error> {
        let (stream, output) = AsyncThrowingStream<String, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let words = Self.letters(utterance), now = clock.now()
        let taken = state { (state: inout State) -> Bool in
            guard var pending = state.pending, pending.words == words, pending.takers.isEmpty else { return false }
            (state.counts.reused, state.counts.lead) = (true, now - pending.start)
            if let latest = pending.latest { output.yield(latest) }
            if pending.finished {
                output.finish(throwing: pending.failure)
                state.pending = nil
            } else {
                pending.takers.append(output)
                state.pending = pending
            }
            return true
        }
        if taken { return stream }
        drop()
        return model.reply(to: utterance)
    }

    /// The turn's own cancel: the model stops, a taken answer ends; not a dropped speculation.
    func cancel() {
        let takers = state { (now: inout State) -> [AsyncThrowingStream<String, Error>.Continuation] in
            defer { (now.pending, now.task) = (nil, nil) }
            return now.pending?.takers ?? []
        }
        model.cancel()
        takers.forEach { $0.finish() }
    }

    /// The begun answer has come to its end; it is not taken yet.
    var finished: Bool { state { $0.pending?.finished ?? false } }

    /// The counts since the last record, for its stages: only when an answer was begun in a pause.
    func takeStages() -> [String: Double] {
        state { (now: inout State) -> [String: Double] in
            defer { now.counts = Counts() }
            let counts = now.counts
            guard counts.started else { return [:] }
            var stages = ["spec_reused": counts.reused ? 1 : 0, "spec_cancels": Double(counts.cancels)]
            if counts.reused { stages["spec_lead"] = counts.lead }
            if counts.stale > 0 { stages["spec_stale"] = Double(counts.stale) }
            return stages
        }
    }

    private func got(_ text: String, _ id: Int) {
        state { (now: inout State) in
            guard now.pending?.id == id else { return }
            now.pending?.latest = text
            now.pending?.takers.forEach { $0.yield(text) }
        }
    }

    private func ended(_ failure: Error?, _ id: Int) {
        state { (now: inout State) in
            guard var pending = now.pending, pending.id == id else { return }
            (pending.finished, pending.failure) = (true, failure)
            pending.takers.forEach { $0.finish(throwing: failure) }
            now.pending = pending.takers.isEmpty ? pending : nil
        }
    }

    /// Her words as the comparison sees them: letters only, lowercase, «ё» as «е».
    static func letters(_ text: String) -> String {
        String(text.lowercased().replacingOccurrences(of: "ё", with: "е").filter(\.isLetter))
    }
}
