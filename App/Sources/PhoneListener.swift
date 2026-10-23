import AllyCore
import Foundation
import os

/// The phone's ear for the session (D2.2): the listening half of the D1.2 turn — the recognizer's phrase, the
/// end-of-speech detector with the registry's tail, the microphone until the speech ends or `listen_timeout` passes —
/// and the stage times of that listening for the record of the turn that answers it. Her utterance — the samples that
/// went into the recognizer and the listening times — goes to the black box before the text (`keep`, D3.2).
final class PhoneListener: Listener, @unchecked Sendable {
    private static let log = Logger(subsystem: "com.anthonypriceone.ally", category: "blackbox")
    private let recognizer: DictationRecognizer, audio: AudioIO, registry: ModelRegistry
    private let resetSound: @Sendable () -> Void, firstSound: @Sendable () -> Double?, heard: @Sendable (String) -> Void
    private let keep: @Sendable (Utterance) -> Void
    private let last = Locked<(stages: [String: Double], voiced: Double?)>(([:], nil))

    init(recognizer: DictationRecognizer, audio: AudioIO, registry: ModelRegistry,
         resetSound: @escaping @Sendable () -> Void, firstSound: @escaping @Sendable () -> Double?,
         heard: @escaping @Sendable (String) -> Void, keep: @escaping @Sendable (Utterance) -> Void = { _ in }) {
        (self.recognizer, self.audio, self.registry) = (recognizer, audio, registry)
        (self.resetSound, self.firstSound, self.heard, self.keep) = (resetSound, firstSound, heard, keep)
    }

    func listen() async throws -> String? {
        let fed = Locked<(samples: [Int16], rate: Int)>(([], 16_000))
        let phrase = try await recognizer.phrase(onText: heard) { samples, rate in
            fed { (now: inout (samples: [Int16], rate: Int)) in
                (now.samples, now.rate) = (now.samples + samples, rate)
            }
        }
        let detector = TurnDetector(kind: .closed, timing: registry.turn), opened = ProcessInfo.processInfo.systemUptime
        guard let end = try await audio.listen(detector, timeout: registry.listenTimeout, feed: phrase.feed) else {
            await phrase.cancel()
            heard("(тишина)")
            return nil
        }
        let text = try await phrase.finish(), recognized = ProcessInfo.processInfo.systemUptime
        if text.isEmpty { heard("(не расслышала)") }
        resetSound()
        let stages = ["tail": end.ended - end.voiced, "recognize": recognized - end.ended,
                      "tap_buffer": audio.bufferSeconds]
        last { $0 = (stages, end.voiced) }
        let sound = fed { $0 }  // the speech end is the last voiced frame; its start the audio path does not give (L60)
        keep(Utterance(samples: sound.samples, rate: sound.rate, opened: opened, voiced: nil, ended: end.voiced,
                       closed: end.ended, known: recognized))
        let count = sound.samples.count
        Self.log.info("слух: в распознаватель \(count) отсч.")
        return text
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

/// Her voice as the console hears it: every sentence also goes to the screen.
final class EchoVoice: VoiceOutput, @unchecked Sendable {
    private let voice: VoiceOutput, said: @Sendable (String) -> Void

    init(_ voice: VoiceOutput, said: @escaping @Sendable (String) -> Void) { (self.voice, self.said) = (voice, said) }

    func speak(_ sentence: String) async throws {
        said(sentence)
        try await voice.speak(sentence)
    }

    func stop() { voice.stop() }
}
