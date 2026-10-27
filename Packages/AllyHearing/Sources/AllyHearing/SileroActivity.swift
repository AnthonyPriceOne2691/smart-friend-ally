import AllyCore
import AVFoundation
import os

/// Silero as the detector's activity on the phone (D7.2): the tap's buffers — the same the dictation gets, with their
/// format — resampled to 16 kHz mono and cut into windows of 512 samples; the flag after the last window is the
/// loudness of the detector's next frames, `lag` behind the speech. Each listening's window times go to the journal
/// (U20).
public final class SileroActivity: VoiceActivity, @unchecked Sendable {
    private static let log = Logger(subsystem: "com.anthonypriceone.ally", category: "hearing")
    public let lag: Double
    private let vad: SileroVAD, target: AVAudioFormat
    private var converter: AVAudioConverter?, pending: [Float] = [], flag = false, windowTimes: [Double] = []

    public init?(model: URL, hearing: Hearing) {
        guard let settings = hearing.vad,
              let vad = SileroVAD(model: model, vad: settings, maxSpeech: hearing.turn.maxTurn),
              let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(SileroVAD.rate),
                                         channels: 1, interleaved: false) else { return nil }
        (self.vad, self.target, lag) = (vad, target, settings.lag)
    }

    /// Who listens on the phone, from the registry, the runtime pair and the models folder; no activity — energy.
    public static func choose(_ hearing: Hearing, models: URL) -> (activity: SileroActivity?, listening: Listening) {
        let bytes = { (name: String) -> Int? in
            let attributes = try? FileManager.default.attributesOfItem(atPath: models.appendingPathComponent(name).path)
            return (attributes?[.size] as? NSNumber)?.intValue
        }
        let choice = hearing.listening(pair: { OnnxPair.current }, fileBytes: bytes)
        guard case .silero = choice, let file = hearing.vad?.file else { return (nil, choice) }
        guard let activity = SileroActivity(model: models.appendingPathComponent(file), hearing: hearing) else {
            return (nil, .failed)
        }
        return (activity, choice)
    }

    /// One buffer of the tap, fed before the detector's frames of it.
    public func feed(_ buffer: AVAudioPCMBuffer) {
        pending += resampled(buffer)
        while pending.count >= SileroVAD.window {
            let start = ProcessInfo.processInfo.systemUptime
            flag = vad.accept(Array(pending.prefix(SileroVAD.window)))
            windowTimes.append(ProcessInfo.processInfo.systemUptime - start)
            pending.removeFirst(SileroVAD.window)
        }
    }

    public func loud(_ samples: [Float]) -> Bool? { flag }

    /// A new listening: the last one's window times go to the journal, the detector and the converter start afresh.
    public func reset() {
        if !windowTimes.isEmpty {
            let sorted = windowTimes.sorted(), count = sorted.count
            let p95 = sorted[Int(Double(count - 1) * 0.95)] * 1_000
            Self.log.info("silero: windows \(count) p95 \(p95, format: .fixed(precision: 2)) ms")
        }
        vad.reset()
        (converter, pending, flag, windowTimes) = (nil, [], false, [])
    }

    private func resampled(_ buffer: AVAudioPCMBuffer) -> [Float] {
        if converter?.inputFormat != buffer.format { converter = AVAudioConverter(from: buffer.format, to: target) }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * target.sampleRate / buffer.format.sampleRate) + 64
        guard let converter, let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return [] }
        var given = false
        converter.convert(to: out, error: nil) { _, status in
            status.pointee = given ? .noDataNow : .haveData
            defer { given = true }
            return given ? nil : buffer
        }
        guard let channel = out.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
    }
}
