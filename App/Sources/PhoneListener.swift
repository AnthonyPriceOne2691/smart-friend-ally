import AllyCore
import AllyHearing
import Foundation
import os

/// The phone's ear for the session (D2.2): the listening half of the D1.2 turn — the recognizer's phrase, the
/// end-of-speech detector with the tail of her turn's kind from the hearing registry (D7), the microphone until the
/// speech ends, she says «я всё» or `listen_timeout` passes — and the stage times of that listening for the record of
/// the turn that answers it. Her utterance — the samples that went into the recognizer, dictation's or GigaAM's, and
/// the listening times — goes to the black box before the text (`keep`, D3.2).
final class PhoneListener: Listener, @unchecked Sendable {
    private static let log = Logger(subsystem: "com.anthonypriceone.ally", category: "blackbox")
    private let recognizer: DictationRecognizer, audio: AudioIO, hearing: Hearing
    private let resetSound: @Sendable () -> Void, firstSound: @Sendable () -> Double?, heard: @Sendable (String) -> Void
    private let activity: SileroActivity?  // D7.2: Silero tells speech from silence; nil — energy
    private let last = Locked<(stages: [String: Double], voiced: Double?)>(([:], nil))
    private let ending = Locked<TurnEnding?>(nil), decode: (@Sendable ([Float]) -> String)?
    private let keep: @Sendable (Utterance) -> Void

    /// - Parameter decode: GigaAM's decoder when the registry chose it (D7.3); nil — dictation.
    init(recognizer: DictationRecognizer, audio: AudioIO, hearing: Hearing,
         resetSound: @escaping @Sendable () -> Void, firstSound: @escaping @Sendable () -> Double?,
         heard: @escaping @Sendable (String) -> Void, activity: SileroActivity? = nil,
         decode: (@Sendable ([Float]) -> String)? = nil, keep: @escaping @Sendable (Utterance) -> Void = { _ in }) {
        (self.recognizer, self.audio, self.hearing, self.activity) = (recognizer, audio, hearing, activity)
        (self.decode, self.keep) = (decode, keep)
        (self.resetSound, self.firstSound, self.heard) = (resetSound, firstSound, heard)
    }

    func endTurn() { ending { $0 }?.ask() }

    func listen(_ kind: TurnKind, events: @escaping @Sendable (EarEvent) -> Void) async throws -> String? {
        let fed = Locked<(samples: [Int16], rate: Int)>(([], 16_000))
        let phrase = try await makePhrase { samples, rate in
            fed { (now: inout (samples: [Int16], rate: Int)) in
                now.samples += samples
                now.rate = rate
            }
        }
        let (pauses, feed) = AsyncStream.makeStream(of: TurnEvent.self, bufferingPolicy: .bufferingOldest(128))
        defer { feed.finish() }  // a failed listening ends the relay too
        let relay = Task { await Self.relay(pauses, to: phrase, events: events) }
        let turnEnding = TurnEnding { feed.yield($0) }
        ending { $0 = turnEnding }
        defer { ending { $0 = nil } }
        let detector = TurnDetector(kind: kind, timing: hearing.turn, ending: turnEnding, activity: activity)
        let opened = ProcessInfo.processInfo.systemUptime
        let end = try await audio.listen(detector, timeout: hearing.listenTimeout) { [activity] buffer in
            phrase.feed(buffer)
            activity?.feed(buffer)  // the same tap buffers, before the detector's frames of them (D7.2)
        }
        feed.finish()
        await relay.value
        guard let end else {
            await phrase.cancel()
            heard("(тишина)")
            return nil
        }
        let text = try await phrase.finish(), recognized = ProcessInfo.processInfo.systemUptime
        if text.isEmpty { heard("(не расслышала)") }
        resetSound()
        var stages = ["tail": end.ended - end.voiced, "recognize": recognized - end.ended,
                      "tap_buffer": audio.bufferSeconds]
        if let reason = turnEnding.reason, reason != .tail { stages["turn_" + reason.rawValue] = 1 }
        if let over = audio.startedOverVoice { stages["started_over_voice"] = over }  // D6.1: began over Elly (X11)
        last { $0 = (stages, end.voiced) }
        let sound = fed { $0 }  // the speech end is the last voiced frame; its start the audio path does not give (L60)
        keep(Utterance(samples: sound.samples, rate: sound.rate, opened: opened, voiced: nil, ended: end.voiced,
                       closed: end.ended, known: recognized))
        let count = sound.samples.count
        Self.log.info("слух: в распознаватель \(count) отсч.")
        return text
    }

    /// GigaAM's phrase when the registry chose it (D7.3), else dictation's; `onFed` gets the samples each one gives its
    /// recognizer — the black box's sound of her (D3.2).
    private func makePhrase(onFed: @escaping @Sendable ([Int16], Int) -> Void) async throws -> RecognitionPhrase {
        guard let decode else { return try await recognizer.phrase(onText: heard, onFed: onFed) }
        return GigaAMPhrase(preRoll: hearing.turn.preRoll, decode: decode, onText: heard, onFed: onFed)
    }

    /// Her start, pauses and speech coming back, in order: the phrase hears of them, the session gets the text at her
    /// tentative end (D7.1) and the resumed speech.
    private static func relay(_ pauses: AsyncStream<TurnEvent>, to phrase: RecognitionPhrase,
                              events: @escaping @Sendable (EarEvent) -> Void) async {
        for await pause in pauses {
            switch pause {
            case .started: phrase.started()
            case .tentativeEnd: if let text = try? await phrase.tentative() { events(.tentative(text)) }
            case .resumed:
                phrase.resumed()
                events(.resumed)
            case .ended: break
            }
        }
    }

    /// The stages of the last listening, once — the first record after it takes them — with the first sound of her
    /// answer counted from the end of the speech.
    func takeStages() -> [String: Double] {
        let (stages, voiced) = last { (now: inout (stages: [String: Double], voiced: Double?)) in
            defer { now = ([:], nil) }
            return now
        }
        guard let voiced, let sound = firstSound() else { return stages }
        return stages.merging(["speech_end_to_sound": sound - voiced]) { $1 }
    }
}

/// Her voice as the console hears it: every sentence also goes to the screen; the next sentences reach the voice (L58).
final class EchoVoice: VoiceOutput, VoiceLookahead, @unchecked Sendable {
    private let voice: VoiceOutput, said: @Sendable (String) -> Void

    init(_ voice: VoiceOutput, said: @escaping @Sendable (String) -> Void) { (self.voice, self.said) = (voice, said) }

    func speak(_ sentence: String) async throws {
        said(sentence)
        try await voice.speak(sentence)
    }

    func stop() { voice.stop() }

    func upcoming(_ sentences: [String]) { (voice as? VoiceLookahead)?.upcoming(sentences) }
}
