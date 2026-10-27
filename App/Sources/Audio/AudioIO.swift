import AllyCore
import AVFoundation

/// The microphone and the voice on one engine for a session (D6.1). With Supertonic the engine carries the voice's
/// player and the system's voice processing — echo cancellation, AGC by the hearing registry — and the microphone stays
/// open while Elly speaks: a ring keeps the last seconds for the next listening, a counter counts her speech over the
/// voice. With Milena, whose voice goes past the engine, it is half-duplex as before: what comes outside a listening is
/// dropped. The engine runs from the session's wake to its sleep; all its state lives on one serial queue. Her speech
/// over the voice cuts Elly (`onOverlap`, D6.2); the audio session taken away and given back reaches the session too.
final class AudioIO: @unchecked Sendable {
    typealias End = (voiced: Double, ended: Double)

    /// The engine the voice's player is attached to before voice processing goes on (X9).
    let engine = AVAudioEngine()
    /// Seconds of the last buffer iOS delivered: 20 ms is asked for, the journal keeps what it gave.
    private(set) var bufferSeconds = 0.0
    private let queue = DispatchQueue(label: "ally.audio", qos: .userInitiated)
    private var running = false, listening: Listening?, duplex: Duplex?, overVoice: Double?
    private var onOverlap: (@Sendable () -> Void)?, interruptions: NSObjectProtocol?

    static func microphoneAllowed() async -> Bool { await AVAudioApplication.requestRecordPermission() }

    /// The voice goes through this engine: the session for voice chat on the speaker, voice processing on the input —
    /// the voice's player is attached by now — and AGC by the registry; then the ring and the counter. Nil — the
    /// registry has no `overlap`, and the microphone stays half-duplex.
    func goDuplex(_ hearing: Hearing, activity: VoiceActivity, feed: ((AVAudioPCMBuffer) -> Void)?,
                  flagMinimum: Double) throws -> String? {
        guard let overlap = hearing.overlap else { return nil }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)
        try engine.inputNode.setVoiceProcessingEnabled(true)
        let agc = hearing.voiceProcessing?.agc ?? true
        engine.inputNode.isVoiceProcessingAGCEnabled = agc
        let ring = VoiceRing<Piece>(seconds: hearing.turn.preRoll, lead: overlap.lead)
        queue.sync {
            duplex = Duplex(ring: ring, counter: OverlapCounter(overlap, flagMinimum: flagMinimum), activity: activity,
                            feed: feed)
        }
        return agc ? "vp+agc" : "vp"
    }

    /// The session woke: the microphone opens for all of it. Half-duplex sets its session here, as D1.2 did.
    func start() throws {
        try queue.sync {
            guard !running else { return }
            if duplex == nil {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setPreferredIOBufferDuration(0.02)
                try session.setActive(true)
            }
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [self] buffer, at in
                guard let copy = Self.copy(buffer) else { return }
                queue.async { self.heard(copy, at: AVAudioTime.seconds(forHostTime: at.hostTime)) }
            }
            engine.prepare()
            do {
                if !engine.isRunning { try engine.start() }
            } catch {
                input.removeTap(onBus: 0)
                throw error
            }
            running = true
        }
    }

    /// The session sleeps: the microphone closes, the ring empties, a listening in flight ends now with no speech.
    func stop() {
        queue.async { [self] in
            guard running else { return }
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            running = false
            duplex?.ring.clear()
            finish(nil)
        }
    }

    /// Her speech over the voice made an overlap — the app cuts Elly (D6.2); called on the audio queue.
    func whenOverlap(_ handler: @escaping @Sendable () -> Void) { queue.sync { onOverlap = handler } }

    /// The audio session taken away (a call, Siri, an alarm) and given back (D6.2): a listening in flight ends with no
    /// speech, and when it is back the engine runs again before the handler hears of it.
    func whenInterrupted(_ handler: @escaping @Sendable (Bool) -> Void) {
        let center = NotificationCenter.default, session = AVAudioSession.sharedInstance()
        interruptions = center.addObserver(forName: AVAudioSession.interruptionNotification, object: session,
                                           queue: nil) { [weak self] note in
            guard let self, let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let kind = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let began = kind == .began
            queue.async {
                if began { return self.finish(nil) }
                guard self.running, !self.engine.isRunning else { return }
                try? AVAudioSession.sharedInstance().setActive(true)
                try? self.engine.start()
            }
            queue.async { handler(began) }
        }
    }

    /// The voice began to sound / went silent at its last sample (`SoundingPlayer`): the counter's window.
    func voiceStarted() { queue.async { self.duplex?.counter.voiceStarted() } }
    func voiceEnded(at time: Double) { queue.async { self.duplex?.counter.voiceEnded(at: time) } }

    /// Her speech over the voice since the last call, for the record of the answer; nil — half-duplex.
    func takeOverlaps() -> Int? { queue.sync { duplex?.counter.take() } }

    /// Seconds her speech had begun before the last listening opened — over Elly's voice (X11); nil — it had not.
    var startedOverVoice: Double? { queue.sync { overVoice } }

    /// Buffers go to `feed`, the detector gets 20 ms frames (its tested frame) until the turn ends or nobody speaks for
    /// `timeout` s: host seconds of the last voiced frame and of the end, nil if nobody spoke. The ring with her speech
    /// over the voice comes first (D6.1); the microphone stays open after it.
    func listen(_ detector: TurnDetector, timeout: Double,
                feed: @escaping (AVAudioPCMBuffer) -> Void) async throws -> End? {
        try start()
        nonisolated(unsafe) let detector = detector  // handed to the queue, used only there
        return try await withCheckedThrowingContinuation { (done: CheckedContinuation<End?, Error>) in
            queue.async { [self] in
                let opened = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                overVoice = nil
                listening = Listening(detector: detector, feed: feed, timeout: timeout, opened: opened, done: done)
                for piece in duplex?.ring.handOver() ?? [] where listening != nil {
                    listen(to: piece.buffer, at: piece.time)
                }
            }
        }
    }

    private func heard(_ buffer: AVAudioPCMBuffer, at start: Double) {
        bufferSeconds = Double(buffer.frameLength) / buffer.format.sampleRate
        if listening != nil { return listen(to: buffer, at: start) }
        outside(buffer, at: start)
    }

    /// A buffer of the listening: to the phrase and the activity, its frames to the detector.
    private func listen(to buffer: AVAudioPCMBuffer, at start: Double) {
        guard var current = listening else { return }
        current.feed(buffer)
        for (frame, time) in Self.frames(buffer, from: start) {
            let event = current.detector.process(frame, at: time)
            if case .started(let at) = event { current.started = current.started ?? at }
            var end: End?
            if case .ended(let voiced, _) = event { end = (voiced, time) }
            if end != nil || (current.started == nil && time - current.opened > current.timeout) {
                listening = current
                return finish(end)
            }
        }
        listening = current
    }

    /// A buffer outside a listening: with the voice through the engine, its frames to the counter and the buffer to
    /// the ring with whether she spoke in it; half-duplex drops it.
    private func outside(_ buffer: AVAudioPCMBuffer, at start: Double) {
        guard var state = duplex else { return }
        state.feed?(buffer)
        var speech = false
        for (frame, time) in Self.frames(buffer, from: start) {
            let loud = state.activity.loud(frame)
            let length = Double(frame.count) / buffer.format.sampleRate
            if state.counter.frame(speech: loud, at: time, length: length) { onOverlap?() }
            speech = speech || loud == true
        }
        state.ring.add(Piece(buffer: buffer, time: start), at: start, speech: speech)
        duplex = state
    }

    private func finish(_ end: End?) {
        guard let current = listening else { return }
        listening = nil
        overVoice = current.started.map { current.opened - $0 }.flatMap { $0 > 0 ? $0 : nil }
        current.done.resume(returning: end)
    }

    /// 20 ms frames of the buffer's first channel with their host times — from the format the tap really gave (L44).
    private static func frames(_ buffer: AVAudioPCMBuffer, from start: Double) -> [(samples: [Float], time: Double)] {
        guard let channel = buffer.floatChannelData?[0] else { return [] }
        let rate = buffer.format.sampleRate, step = max(Int(rate) / 50, 1)
        let samples = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
        return stride(from: 0, to: samples.count, by: step).map { offset in
            (Array(samples[offset..<min(offset + step, samples.count)]), start + Double(offset) / rate)
        }
    }

    /// The tap's buffer copied: it is handled on the queue, after the tap returns.
    private static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength),
              let source = buffer.floatChannelData, let target = copy.floatChannelData else { return nil }
        copy.frameLength = buffer.frameLength
        for channel in 0..<Int(buffer.format.channelCount) {
            target[channel].update(from: source[channel], count: Int(buffer.frameLength))
        }
        return copy
    }
}

/// One listening on the session's microphone: its detector and feed, when it opened, when her speech started.
private struct Listening {
    var detector: TurnDetector
    let feed: (AVAudioPCMBuffer) -> Void, timeout: Double, opened: Double
    var started: Double?
    let done: CheckedContinuation<AudioIO.End?, Error>
}

/// A buffer the ring keeps, with its host time.
private struct Piece {
    let buffer: AVAudioPCMBuffer, time: Double
}

/// The microphone outside a listening while the voice goes through the engine (D6.1): the ring, the counter and the
/// activity that tells her speech in them — its own, not the listening's, which every listening resets.
private struct Duplex {
    var ring: VoiceRing<Piece>, counter: OverlapCounter, activity: VoiceActivity
    let feed: ((AVAudioPCMBuffer) -> Void)?
}
