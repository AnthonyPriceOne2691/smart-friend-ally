import AllyCore
import AVFoundation

/// Sound on the session's engine (D6.1 holds one AVAudioEngine for the microphone and the voice): a player node of
/// its own, mono float at the voice's rate. `play` returns when the buffer has played back or a stop cut it.
final class EnginePlayer: SoundPlayer, @unchecked Sendable {
    private struct Playing { let frames: Int, started: Double, done: CheckedContinuation<Played, Never> }
    private let engine: AVAudioEngine, node = AVAudioPlayerNode(), format: AVAudioFormat?
    private let playing = Locked<Playing?>(nil)

    init(engine: AVAudioEngine, rate: Int) {
        self.engine = engine
        format = AVAudioFormat(standardFormatWithSampleRate: Double(rate), channels: 1)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    func play(_ samples: [Float], rate: Int) async -> Played {
        let capacity = AVAudioFrameCount(samples.count)
        guard let format, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity),
              let channel = buffer.floatChannelData?[0] else { return Played(started: nil, frames: 0, cut: false) }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        for (index, sample) in samples.enumerated() { channel[index] = sample }
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return Played(started: nil, frames: 0, cut: false)
        }
        return await withCheckedContinuation { (done: CheckedContinuation<Played, Never>) in
            let session = AVAudioSession.sharedInstance()
            let started = AVAudioTime.seconds(forHostTime: mach_absolute_time()) + session.outputLatency
                + session.ioBufferDuration
            playing { $0 = Playing(frames: samples.count, started: started, done: done) }
            node.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [self] _ in
                finish(Played(started: started, frames: samples.count, cut: false))
            }
            node.play()
        }
    }

    /// Silence now: the frames played so far and a cut sign. The buffer in flight is taken before the node stops, so
    /// the completion a stop fires answers nothing — exactly one answer per buffer.
    func stop() {
        let frames = node.lastRenderTime.flatMap { node.playerTime(forNodeTime: $0) }.map { Int($0.sampleTime) }
        let current = take()
        node.stop()
        guard let current else { return }
        let played = min(max(frames ?? 0, 0), current.frames)
        current.done.resume(returning: Played(started: played > 0 ? current.started : nil, frames: played, cut: true))
    }

    private func finish(_ result: Played) { take()?.done.resume(returning: result) }

    private func take() -> Playing? {
        playing { (now: inout Playing?) -> Playing? in
            defer { now = nil }
            return now
        }
    }
}
