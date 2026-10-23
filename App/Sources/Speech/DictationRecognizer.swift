import AllyCore
import AVFoundation
import Speech

/// Russian recognition on the phone: `DictationTranscriber` ru-RU (SpeechTranscriber has no Russian, L23); nothing is
/// downloaded — a missing Russian dictation model is a console line, not a request (A11).
final class DictationRecognizer: @unchecked Sendable {
    private var locale: Locale?, format: AVAudioFormat?

    /// The console line: ready, or what is missing; asked on the device at start, not taken from a vendor list.
    func prepare() async -> (ready: Bool, line: String) {
        guard let russian = await DictationTranscriber.supportedLocale(equivalentTo: Locale(identifier: "ru-RU")),
              await DictationTranscriber.installedLocales.map({ $0.identifier(.bcp47) })
                .contains(russian.identifier(.bcp47))
        else { return (false, "нет русской модели диктовки") }
        locale = russian
        format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [Self.module(russian)])
        let ready = "диктовка \(russian.identifier(.bcp47)): " + (format == nil ? "нет формата" : "готова")
        return (format != nil, ready + (format.map { " · " + Self.kind($0) } ?? ""))
    }

    /// One phrase: opened before the speech starts, so setup overlaps the speaking; `onText` gets the running text,
    /// `onFed` — the samples of every buffer that went into the analyzer, when it takes PCM16 mono (black box, D3.2).
    func phrase(onText: @escaping @Sendable (String) -> Void,
                onFed: @escaping @Sendable ([Int16], Int) -> Void = { _, _ in }) async throws -> Phrase {
        guard let locale, let format else { throw CocoaError(.featureUnsupported) }
        return try await Phrase(module: Self.module(locale), format: format, onText: onText, onFed: onFed)
    }

    /// The analyzer's format for the console (B14): her sound is kept only as PCM16 mono, bit for bit (L23).
    private static func kind(_ format: AVAudioFormat) -> String {
        let pcm16 = format.commonFormat == .pcmFormatInt16 && format.channelCount == 1
        return "\(Int(format.sampleRate)) Гц, " + (pcm16 ? "Int16, моно" : "не PCM16 моно — её звук не пишется")
    }

    private static func module(_ locale: Locale) -> DictationTranscriber {
        DictationTranscriber(locale: locale, contentHints: [.shortForm], transcriptionOptions: [.punctuation],
                             reportingOptions: [.volatileResults, .frequentFinalization], attributeOptions: [])
    }
}

/// The analyzer of one phrase: buffers in (converted to its format), the text out at the end.
final class Phrase: @unchecked Sendable {
    private let analyzer: SpeechAnalyzer, input: AsyncStream<AnalyzerInput>.Continuation, text: Task<String, Error>
    private let format: AVAudioFormat, onFed: @Sendable ([Int16], Int) -> Void
    private var converter: AVAudioConverter?  // the tap's thread only

    fileprivate init(module: DictationTranscriber, format: AVAudioFormat, onText: @escaping @Sendable (String) -> Void,
                     onFed: @escaping @Sendable ([Int16], Int) -> Void) async throws {
        let options = SpeechAnalyzer.Options(priority: .userInitiated, modelRetention: .processLifetime)
        analyzer = SpeechAnalyzer(modules: [module], options: options)
        // Bounded by the longest turn: 20 s is ~940 tap buffers of 1024 frames at 48 kHz.
        let (stream, input) = AsyncStream<AnalyzerInput>.makeStream(bufferingPolicy: .bufferingOldest(2_048))
        (self.input, self.format, self.onFed) = (input, format, onFed)
        text = Task {
            var collector = TranscriptCollector()
            for try await result in module.results {
                onText(collector.add(String(result.text.characters), isFinal: result.isFinal))
            }
            return collector.text
        }
        try await analyzer.prepareToAnalyze(in: format)
        try await analyzer.start(inputSequence: stream)
    }

    func feed(_ buffer: AVAudioPCMBuffer) {
        guard let converted = convert(buffer) else { return }
        input.yield(AnalyzerInput(buffer: converted))
        // The very buffer the analyzer got, as samples — only PCM16 mono is kept bit for bit (B14).
        guard format.commonFormat == .pcmFormatInt16, format.channelCount == 1,
              let channel = converted.int16ChannelData?[0] else { return }
        onFed(Array(UnsafeBufferPointer(start: channel, count: Int(converted.frameLength))), Int(format.sampleRate))
    }

    /// End of input: everything fed so far is finalized; the phrase's text.
    func finish() async throws -> String {
        input.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        return try await text.value
    }

    func cancel() async {
        input.finish()
        await analyzer.cancelAndFinishNow()
    }

    private func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard buffer.format != format else { return buffer }
        if converter?.inputFormat != buffer.format { converter = AVAudioConverter(from: buffer.format, to: format) }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate + 32)
        guard let converter, let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var fed = false
        let status = converter.convert(to: out, error: nil) { _, state in
            defer { fed = true }
            state.pointee = fed ? .noDataNow : .haveData
            return fed ? nil : buffer
        }
        return status == .error || out.frameLength == 0 ? nil : out
    }
}
