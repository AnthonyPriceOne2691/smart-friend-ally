import AllyCore
import AVFoundation

/// One utterance of a recognizer (D7.3): the tap's buffers in, her start and pauses, the text at the tentative end and
/// at the tail. Dictation streams; GigaAM decodes the utterance in one go.
protocol RecognitionPhrase: AnyObject, Sendable {
    func feed(_ buffer: AVAudioPCMBuffer)
    func started()
    func tentative() async throws -> String
    func resumed()
    func finish() async throws -> String
    func cancel() async
}

/// Dictation finalizes as it goes: her start and her speech coming back change nothing for it.
extension Phrase: RecognitionPhrase {
    func started() {}
    func resumed() {}
}

/// GigaAM's utterance: the tap's buffers as 16 kHz Int16 mono — the black box's format — into `BatchPhrase`; decoding
/// runs off the audio thread, the text goes to the screen as dictation's does.
final class GigaAMPhrase: RecognitionPhrase, @unchecked Sendable {
    private let batch: BatchPhrase, onText: @Sendable (String) -> Void
    private let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1,
                                       interleaved: false)
    private var converter: AVAudioConverter?  // the tap's thread only

    init(preRoll: Double, decode: @escaping @Sendable ([Float]) -> String,
         onText: @escaping @Sendable (String) -> Void) {
        batch = BatchPhrase(preRoll: preRoll) { decode(BatchPhrase.floats($0)) }
        self.onText = onText
    }

    func feed(_ buffer: AVAudioPCMBuffer) {
        guard let format else { return }
        if converter?.inputFormat != buffer.format { converter = AVAudioConverter(from: buffer.format, to: format) }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate + 32)
        guard let converter, let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }
        var fed = false
        let status = converter.convert(to: out, error: nil) { _, state in
            defer { fed = true }
            state.pointee = fed ? .noDataNow : .haveData
            return fed ? nil : buffer
        }
        guard status != .error, let samples = out.int16ChannelData?[0] else { return }
        batch.feed(Array(UnsafeBufferPointer(start: samples, count: Int(out.frameLength))))
    }

    func started() { batch.started() }
    func resumed() { batch.resumed() }

    func tentative() async throws -> String { await decoded(batch.tentative) }
    func finish() async throws -> String { await decoded(batch.finish) }
    func cancel() async {}

    private func decoded(_ work: @escaping @Sendable () -> String) async -> String {
        let text = await Task.detached(priority: .userInitiated, operation: work).value
        onText(text)
        return text
    }
}
