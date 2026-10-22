import AllyCore
import AVFoundation

/// The temporary voice: the system Russian voice chosen by identifier, not by language (П23) — without the enhanced
/// voice the compact one sounds and the console says so; the rate is set on every utterance (П17). `speak` returns
/// when the sentence has sounded or was stopped.
final class SystemVoice: NSObject, VoiceOutput, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    let voice: AVSpeechSynthesisVoice?, note: String
    private let synth = AVSpeechSynthesizer(), rate: Float
    private let waiting = Locked<[ObjectIdentifier: CheckedContinuation<Void, Never>]>([:])
    private let started = Locked<Double?>(nil)

    init(identifier: String, rate: Float) {
        let compactId = identifier.replacingOccurrences(of: "enhanced", with: "compact")
        let compact = AVSpeechSynthesisVoice(identifier: compactId)
        if let enhanced = AVSpeechSynthesisVoice(identifier: identifier) {
            (voice, note) = (enhanced, "голос: \(enhanced.identifier)")
        } else {
            (voice, note) = (compact, compact.map { "нет enhanced, голос \($0.identifier)" } ?? "нет голоса")
        }
        self.rate = rate
        super.init()
        synth.delegate = self
    }

    /// Host seconds when the first utterance since `resetFirstSound` started sounding.
    var firstSound: Double? { started { $0 } }
    func resetFirstSound() { started { $0 = nil } }

    func speak(_ sentence: String) async throws {
        let utterance = AVSpeechUtterance(string: sentence)
        (utterance.voice, utterance.rate) = (voice, rate)
        await withCheckedContinuation { done in
            waiting { $0[ObjectIdentifier(utterance)] = done }
            synth.speak(utterance)
        }
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let now = ProcessInfo.processInfo.systemUptime
        started { $0 = $0 ?? now }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { done(utterance) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { done(utterance) }
    private func done(_ utterance: AVSpeechUtterance) {
        waiting { $0.removeValue(forKey: ObjectIdentifier(utterance)) }?.resume()
    }
}
