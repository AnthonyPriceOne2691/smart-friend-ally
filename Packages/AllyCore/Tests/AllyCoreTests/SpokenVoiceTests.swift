@testable import AllyCore
import Foundation
import XCTest

/// A renderer double: 100 samples a character at 1 kHz (0.1 s), fixed stage times.
final class ToneRenderer: SentenceRenderer, @unchecked Sendable {
    private let calls = Locked([(sentence: String, first: Bool)]())
    var rendered: [(sentence: String, first: Bool)] { calls { $0 } }

    func render(_ sentence: String, first: Bool) throws -> RenderedSentence {
        calls { $0.append((sentence, first)) }
        return RenderedSentence(samples: [Float](repeating: 0.1, count: 100 * sentence.count), rate: 1000,
                                stages: ["voice_text": 0.01, "voice_synth": 0.4, "voice_fx": 0.02])
    }
}

/// A render queue the test opens: work waits until `release` — a synthesis held in flight.
final class HeldQueue: RenderQueue, @unchecked Sendable {
    private let held = Locked([@Sendable () -> Void]())
    var waiting: Int { held { $0.count } }
    func run(_ work: @escaping @Sendable () -> Void) { held { $0.append(work) } }
    func release() { held { (works: inout [@Sendable () -> Void]) -> [@Sendable () -> Void] in
        defer { works = [] }
        return works
    }.forEach { $0() } }
}

/// A player double on the test clock: sound starts `latency` after `play`, lasts its samples; `stop` cuts it there.
final class ClockPlayer: SoundPlayer, @unchecked Sendable {
    struct Call { let started: Double, frames: Int }
    private struct State { var calls: [Call] = [], playing: Task<Void, Error>?, stops = 0 }
    private let state = Locked(State()), clock: TestClock, latency: Double
    var calls: [Call] { state { $0.calls } }
    var stops: Int { state { $0.stops } }
    init(clock: TestClock, latency: Double = 0.05) { (self.clock, self.latency) = (clock, latency) }

    func play(_ samples: [Float], rate: Int) async -> Played {
        let started = clock.now() + latency, seconds = Double(samples.count) / Double(rate), clock = clock
        let sounding = Task { try await clock.sleep(seconds: latency + seconds) }
        state { (s: inout State) in
            s.calls.append(Call(started: started, frames: samples.count))
            s.playing = sounding
        }
        let whole = (try? await sounding.value) != nil
        guard !whole else { return Played(started: started, frames: samples.count, cut: false) }
        let frames = min(samples.count, max(0, Int((clock.now() - started) * Double(rate))))
        return Played(started: frames > 0 ? started : nil, frames: frames, cut: true)
    }

    func stop() { state { (s: inout State) -> Task<Void, Error>? in s.stops += 1; return s.playing }?.cancel() }
}

/// A voice double that keeps the hints of the next sentences it was given.
final class HintedVoice: VoiceOutput, VoiceLookahead, @unchecked Sendable {
    private let log = Locked([[String]]())
    var hints: [[String]] { log { $0 } }
    func speak(_ sentence: String) async throws {}
    func stop() {}
    func upcoming(_ sentences: [String]) { log { $0.append(sentences) } }
}

/// The port double: what came, in order.
final class SoundLog: PlayedSound, @unchecked Sendable {
    private let log = Locked([String]())
    var events: [String] { log { $0 } }
    func played(_ samples: [Float], rate: Int) { log { $0.append("\(samples.count)@\(rate)") } }
    func cut() { log { $0.append("cut") } }
}

final class SpokenVoiceTests: XCTestCase {
    private let clock = TestClock()

    /// Runs `work` while moving the test clock from deadline to deadline until it ends; work that neither ends nor
    /// sleeps is hung — cancelled, and the test fails instead of hanging (L72).
    private func drive(_ work: @escaping @Sendable () async throws -> Void) async throws {
        let task = Task { try await work() }, done = Locked(false)
        Task { _ = try? await task.value; done { $0 = true } }
        while !done({ $0 }) {
            await eventually { self.clock.sleeping > 0 || done { $0 } }
            guard done({ $0 }) || clock.advanceToNext() else { break }
        }
        try await settle(task)
    }

    /// Waits (real time, up to 10 s) for the task; a hung one is cancelled and fails the test (L72).
    private func settle(_ task: Task<Void, Error>, line: UInt = #line) async throws {
        let done = Locked(false)
        Task { _ = try? await task.value; done { $0 = true } }
        await eventually { done { $0 } }
        guard done({ $0 }) else {
            task.cancel()
            return XCTFail("повисло", line: line)
        }
        try await task.value
    }

    func testTheFirstSentenceOfATurnBringsItsStagesOnce() async throws {
        // Z21: stages of the first sentence — text, synthesis, processing, start — in Latin, taken once
        let player = ClockPlayer(clock: clock)
        let voice = SpokenVoice(renderer: ToneRenderer(), player: player, gap: 0.5, clock: clock)
        try await drive { try await voice.speak("Привет, Соня.") ; try await voice.speak("Как дела?") }
        let stages = voice.takeStages()
        XCTAssertEqual(stages.keys.sorted(), ["voice_fx", "voice_start", "voice_synth", "voice_text"])
        XCTAssertTrue(stages.keys.joined().unicodeScalars.allSatisfy(\.isASCII))
        XCTAssertEqual(stages["voice_start"] ?? 0, 0.05, accuracy: 1e-9)
        XCTAssertEqual(voice.firstSound, player.calls.first?.started)
        XCTAssertEqual(voice.takeStages(), [:])
    }

    func testThePortGetsWhatSoundedInOrderAndACutOnStop() async throws {
        // Z23: the sound after processing in order, its length as it sounded; a stop mid-sentence — part and a cut
        let player = ClockPlayer(clock: clock), port = SoundLog()
        let voice = SpokenVoice(renderer: ToneRenderer(), player: player, gap: 0.5, clock: clock, sink: port)
        try await drive { try await voice.speak("Раз.") ; try await voice.speak("Два три.") }
        XCTAssertEqual(port.events, ["400@1000", "800@1000"])
        voice.resetFirstSound()  // the next turn: it sounds at once, no pause before it
        let long = Task { try await voice.speak("Очень длинная фраза.") }
        await eventually { player.calls.count == 3 && self.clock.sleeping > 0 }
        clock.advance(by: 0.05 + 1.0)
        voice.stop()
        try await settle(long)
        let tail = port.events.suffix(2), part = Int(tail.first?.split(separator: "@").first ?? "") ?? 0
        XCTAssertEqual(Double(part) / 1000, 1.0, accuracy: 0.05)
        XCTAssertEqual(tail.last, "cut")
    }

    func testAStopSilencesAtOnceDropsTheSynthesisInFlightAndTheNextTurnSounds() async throws {
        // Z24: a stop while the sentence is still in synthesis — the player stopped at once, nothing sounds; next turn
        let held = HeldQueue(), player = ClockPlayer(clock: clock)
        let voice = SpokenVoice(renderer: ToneRenderer(), player: player, gap: 0.5, clock: clock, queue: held)
        let first = Task { try await voice.speak("Сначала.") }
        await eventually { held.waiting == 1 }
        voice.stop()
        XCTAssertEqual(player.stops, 1)
        held.release()
        try await settle(first)
        XCTAssertTrue(player.calls.isEmpty)
        voice.resetFirstSound()
        let next = Task { try await voice.speak("Потом.") }
        await eventually { held.waiting == 1 }
        held.release()
        await eventually { player.calls.count == 1 && self.clock.sleeping > 0 }
        clock.advanceToNext()
        try await settle(next)
        XCTAssertEqual(player.calls.count, 1)
    }

    func testSentencesMadeAheadArePausedByTheGapBetweenSounds() async throws {
        // Z25: speed 0.9 — the gap 0.45 / 0.9 = 0.5 s ± 0.03 from the end of one sound to the start of the next
        let renderer = ToneRenderer(), player = ClockPlayer(clock: clock)
        let voice = SpokenVoice(renderer: renderer, player: player, gap: 0.45 / 0.9, clock: clock)
        let sentences = ["Привет, Тёма.", "Как дела?", "Что нового?"]
        voice.upcoming(sentences)
        try await drive { for sentence in sentences { try await voice.speak(sentence) } }
        XCTAssertEqual(renderer.rendered.map(\.first), [true, false, false])
        let calls = player.calls
        for (one, next) in zip(calls, calls.dropFirst()) {
            XCTAssertEqual(next.started - (one.started + Double(one.frames) / 1000), 0.5, accuracy: 0.03)
        }
    }

    func testTheTurnPassesTheRestOfItsSentencesThroughTheSessionsWrapper() async throws {
        // Z25 through the turn: the rest of a turn reaches the voice behind the session's wrapper (L58)
        let voice = HintedVoice()
        let runner = TurnRunner(model: ReplyQueue(["Привет, Соня! Слоны большие. Ты их видела?"]),
                                voice: Speaking(voice) {})
        let outcome = try await runner.run("Привет")
        XCTAssertGreaterThan(outcome.turn.sentences.count, 1)
        XCTAssertEqual(voice.hints, [Array(outcome.turn.sentences.dropFirst())])
    }
}
