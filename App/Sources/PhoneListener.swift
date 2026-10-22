import AllyCore
import Foundation

/// The phone's ear for the session (D2.2): the listening half of the D1.2 turn — the recognizer's phrase, the
/// end-of-speech detector with the registry's tail, the microphone until the speech ends or `listen_timeout` passes —
/// and the stage times of that listening for the record of the turn that answers it.
final class PhoneListener: Listener, @unchecked Sendable {
    private let recognizer: DictationRecognizer, audio: AudioIO, registry: ModelRegistry
    private let resetSound: @Sendable () -> Void, firstSound: @Sendable () -> Double?, heard: @Sendable (String) -> Void
    private let last = Locked<(stages: [String: Double], voiced: Double?)>(([:], nil))

    init(recognizer: DictationRecognizer, audio: AudioIO, registry: ModelRegistry,
         resetSound: @escaping @Sendable () -> Void, firstSound: @escaping @Sendable () -> Double?,
         heard: @escaping @Sendable (String) -> Void) {
        (self.recognizer, self.audio, self.registry) = (recognizer, audio, registry)
        (self.resetSound, self.firstSound, self.heard) = (resetSound, firstSound, heard)
    }

    func listen() async throws -> String? {
        let phrase = try await recognizer.phrase(onText: heard)
        let detector = TurnDetector(kind: .closed, timing: registry.turn)
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
