import Foundation

/// Her speech over Elly's voice, counted only (D6.1): a run of her speech of at least `minSpeech` while the voice
/// sounds, or within `afterVoice` after it, is one overlap; a shorter run, or one once the voice has been silent
/// longer, is none. An activity whose flag already holds back short speech (Silero's own minimum) counts from the
/// flag's rise. Nothing is stopped: the barge-in that acts on it is D6.2.
public struct OverlapCounter: Sendable {
    private let minimum: Double, afterVoice: Double
    private var sounding = false, voiceEnd: Double?, runStart: Double?, counted = false, count = 0

    /// - Parameter flagMinimum: the speech the activity's flag demands before it rises — Silero's `min_speech`; energy
    ///   flags every loud frame, none.
    public init(_ overlap: Hearing.Overlap, flagMinimum: Double = 0) {
        (minimum, afterVoice) = (max(overlap.minSpeech - flagMinimum, 0), overlap.afterVoice)
    }

    /// The voice began to sound.
    public mutating func voiceStarted() { (sounding, voiceEnd) = (true, nil) }

    /// The voice's last sample sounded at `time`.
    public mutating func voiceEnded(at time: Double) { (sounding, voiceEnd) = (false, time) }

    /// One frame heard from `time` for `length` seconds: her speech as the activity flags it (nil — no say yet).
    public mutating func frame(speech: Bool?, at time: Double, length: Double) {
        guard speech == true, inWindow(time) else {
            (runStart, counted) = (nil, false)
            return
        }
        let start = runStart ?? time
        runStart = start
        guard !counted, time + length - start >= minimum - 1e-9 else { return }
        (counted, count) = (true, count + 1)
    }

    /// The overlaps since the last call — for the record of the answer they came over.
    public mutating func take() -> Int {
        defer { count = 0 }
        return count
    }

    private func inWindow(_ time: Double) -> Bool {
        sounding || voiceEnd.map { time - $0 <= afterVoice + 1e-9 } ?? false
    }
}

/// The microphone while the session does not listen (D6.1): the last `seconds` of what came, each piece with its time
/// and whether the activity flagged her speech. A listening opened after Elly's voice starts with the ring from her
/// first speech piece minus `lead`, or with nothing when she did not speak: what is left of Elly's voice after echo
/// cancellation never reaches the recognizer.
public struct VoiceRing<Piece> {
    private struct Held {
        let piece: Piece, time: Double, speech: Bool
    }

    private var held: [Held] = []
    private let seconds: Double, lead: Double

    public init(seconds: Double, lead: Double) { (self.seconds, self.lead) = (seconds, lead) }

    /// One piece heard from `time`: her speech or not; kept back to the newest piece at least `seconds` older.
    public mutating func add(_ piece: Piece, at time: Double, speech: Bool) {
        held.append(Held(piece: piece, time: time, speech: speech))
        while held.count > 1, time - held[1].time >= seconds { held.removeFirst() }
    }

    /// What a listening opened now starts with: the pieces from her first speech minus `lead`; nothing without her
    /// speech. The ring is empty after it either way.
    public mutating func handOver() -> [Piece] {
        defer { held.removeAll() }
        guard let first = held.first(where: { $0.speech }) else { return [] }
        return held.filter { $0.time >= first.time - lead - 1e-9 }.map { $0.piece }
    }

    /// Nothing kept: Milena spoke past the engine, or the session sleeps.
    public mutating func clear() { held.removeAll() }
}
