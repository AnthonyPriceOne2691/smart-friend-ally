import AllyCore
import AVFoundation

/// The microphone, half-duplex: open for one turn, closed before she answers (no echo cancellation in D1). The session
/// is `.playAndRecord` with `.defaultToSpeaker`, so her voice comes from the speaker, not the earpiece.
final class AudioIO: @unchecked Sendable {
    private let engine = AVAudioEngine()
    /// Seconds of the last buffer iOS delivered: 20 ms is asked for, the journal keeps what it gave.
    private(set) var bufferSeconds = 0.0

    static func microphoneAllowed() async -> Bool { await AVAudioApplication.requestRecordPermission() }

    /// Buffers go to `feed`, the detector gets 20 ms frames (its tested frame) until the turn ends or nobody speaks for
    /// `timeout` s: host seconds of the last voiced frame and of the end, nil if nobody spoke; then the mic is closed.
    func listen(_ detector: TurnDetector, timeout: Double,
                feed: @escaping (AVAudioPCMBuffer) -> Void) async throws -> (voiced: Double, ended: Double)? {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)
        let input = engine.inputNode
        var detector = detector, opened: Double?, spoke = false, closing = false
        return try await withCheckedThrowingContinuation { done in
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [self] buffer, at in
                guard !closing, let channel = buffer.floatChannelData?[0] else { return }
                feed(buffer)
                let start = AVAudioTime.seconds(forHostTime: at.hostTime), rate = buffer.format.sampleRate
                let samples = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
                let step = Int(rate) / 50
                bufferSeconds = Double(samples.count) / rate
                for offset in stride(from: 0, to: samples.count, by: step) where !closing {
                    let time = start + Double(offset) / rate
                    let event = detector.process(Array(samples[offset..<min(offset + step, samples.count)]), at: time)
                    if case .started = event { spoke = true }
                    var result: (voiced: Double, ended: Double)?
                    if case .ended(let voiced, _) = event { result = (voiced, time) }
                    guard result != nil || (!spoke && time - (opened ?? time) > timeout) else {
                        opened = opened ?? time
                        continue
                    }
                    closing = true
                    DispatchQueue.main.async {
                        input.removeTap(onBus: 0)
                        engine.stop()
                        done.resume(returning: result)
                    }
                }
            }
            engine.prepare()
            do { try engine.start() } catch {
                input.removeTap(onBus: 0)
                done.resume(throwing: error)
            }
        }
    }
}
