import AllyCore
import AllyOnnx
import AllySherpa
import Foundation

/// Silero VAD v6 through sherpa-onnx's C API (D7.2): one speech flag per window of 512 samples at 16 kHz, with the
/// registry's threshold and shortest speech and silence — the configuration of the speech-in spike (U17). One listening
/// feeds it at a time.
public final class SileroVAD {
    public static let window = 512, rate = 16_000
    private let detector: OpaquePointer

    /// - Parameter maxSpeech: sherpa splits a longer segment — the registry's longest turn (30 s, as in the spike).
    public init?(model: URL, vad: Hearing.VAD, maxSpeech: Double) {
        var settings = SherpaOnnxVadModelConfig()
        settings.silero_vad.threshold = Float(vad.threshold)
        settings.silero_vad.min_silence_duration = Float(vad.minSilence)
        settings.silero_vad.min_speech_duration = Float(vad.minSpeech)
        settings.silero_vad.window_size = Int32(Self.window)
        settings.silero_vad.max_speech_duration = Float(maxSpeech)
        (settings.sample_rate, settings.num_threads) = (Int32(Self.rate), 1)
        let made = model.path.withCString { path in
            "cpu".withCString { cpu in
                (settings.silero_vad.model, settings.provider) = (path, cpu)
                return SherpaOnnxCreateVoiceActivityDetector(&settings, 60)
            }
        }
        guard let made else { return nil }
        detector = made
    }

    deinit { SherpaOnnxDestroyVoiceActivityDetector(detector) }

    /// One window of exactly 512 samples; the speech flag after it. Segments are dropped: the turn keeps its own audio.
    public func accept(_ window: [Float]) -> Bool {
        window.withUnsafeBufferPointer {
            SherpaOnnxVoiceActivityDetectorAcceptWaveform(detector, $0.baseAddress, Int32($0.count))
        }
        while SherpaOnnxVoiceActivityDetectorEmpty(detector) == 0 { SherpaOnnxVoiceActivityDetectorPop(detector) }
        return SherpaOnnxVoiceActivityDetectorDetected(detector) != 0
    }

    /// A new listening or phrase: the detector forgets the last one.
    public func reset() { SherpaOnnxVoiceActivityDetectorReset(detector) }
}

public extension OnnxPair {
    /// The pair linked into this process: ORT's version, sherpa's API and whether ORT serves it, sherpa's version.
    static var current: OnnxPair {
        OnnxPair(ort: OnnxRuntime.version, api: Sherpa.api, served: Sherpa.paired, sherpa: Sherpa.version)
    }
}
