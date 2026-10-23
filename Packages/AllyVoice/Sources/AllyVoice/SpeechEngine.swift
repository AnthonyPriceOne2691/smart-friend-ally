import Foundation

/// The voice engine: one sentence in, mono samples out. Supertonic is the first implementation; another engine, if the
/// voice samples advise one, is another implementation of this — the app depends only on the protocol.
public protocol SpeechEngine: Sendable {
    func synthesize(_ text: String, voice: VoicePreset) throws -> SpeechAudio
}

/// How she speaks: the style ("F2", "F2+F5:0.5"), the synthesis speed, denoising steps and the noise seed. Below
/// `minSpeed` Supertonic repeats words (3 of 96 long sentences at 0.8, none at 0.85–1.05), so an engine refuses it.
public struct VoicePreset: Sendable, Equatable {
    public static let minSpeed = 0.85
    public var style: String, speed: Double, steps: Int, seed: UInt64

    public init(style: String = "F2", speed: Double = 1.05, steps: Int = 8, seed: UInt64 = 0) {
        (self.style, self.speed, self.steps, self.seed) = (style, speed, steps, seed)
    }
}

/// One synthesized sentence: float32 mono samples at `rate`; `duration` — the predicted length in seconds (the samples
/// run on to whole vocoder chunks, the player trims); stage times in seconds.
public struct SpeechAudio: Sendable {
    public let samples: [Float], rate: Int, duration: Double, stages: [String: Double]

    public init(samples: [Float], rate: Int, duration: Double, stages: [String: Double] = [:]) {
        (self.samples, self.rate, self.duration, self.stages) = (samples, rate, duration, stages)
    }
}

/// Why a sentence did not sound.
public enum SpeechError: Error, Equatable, CustomStringConvertible {
    case emptyText
    case speedBelowFloor(Double)
    case badModel(String)

    public var description: String {
        switch self {
        case .emptyText: "empty text"
        // the console line of Z4 and V4, a refusal rather than speech: short pieces, not a phrase of her voice
        case .speedBelowFloor(let speed):
            "скорость синтеза " + Self.decimal(speed) + " ниже " + Self.decimal(VoicePreset.minSpeed)
        case .badModel(let what): "bad model: \(what)"
        }
    }

    static func decimal(_ value: Double) -> String {
        String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }
}
