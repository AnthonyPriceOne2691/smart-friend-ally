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
        return (format != nil, "диктовка \(russian.identifier(.bcp47)): " + (format == nil ? "нет формата" : "готова"))
    }

    /// One phrase: opened before the speech starts, so setup overlaps the speaking; `onText` gets the running text.
    func phrase(onText: @escaping @Sendable (String) -> Void) async throws -> Phrase {
        guard let locale, let format else { throw CocoaError(.featureUnsupported) }
        return try await Phrase(module: Self.module(locale), format: format, onText: onText)
    }

    private static func module(_ locale: Locale) -> DictationTranscriber {
        DictationTranscriber(locale: locale, contentHints: [.shortForm], transcriptionOptions: [.punctuation],
                             reportingOptions: [.volatileResults, .frequentFinalization], attributeOptions: [])
    }
}

/// The analyzer of one phrase: buffers in (converted to its format), the text out at the end.
final class Phrase: @unchecked Sendable {
    private let analyzer: SpeechAnalyzer, input: AsyncStream<AnalyzerInput>.Continuation, text: Task<String, Error>
    private let format: AVAudioFormat, collected = Locked(TranscriptCollector())
    private var converter: AVAudioConverter?  // the tap's thread only

    fileprivate init(module: DictationTranscriber, format: AVAudioFormat,
                     onText: @escaping @Sendable (String) -> Void) async throws {
        let options = SpeechAnalyzer.Options(priority: .userInitiated, modelRetention: .processLifetime)
        analyzer = SpeechAnalyzer(modules: [module], options: options)
        // Bounded by the longest turn: 20 s is ~940 tap buffers of 1024 frames at 48 kHz.
        let (stream, input) = AsyncStream<AnalyzerInput>.makeStream(bufferingPolicy: .bufferingOldest(2_048))
        (self.input, self.format) = (input, format)
        text = Task { [collected] in
            for try await result in module.results {
                onText(collected { $0.add(String(result.text.characters), isFinal: result.isFinal) })
            }
            return collected { $0.text }
        }
        try await analyzer.prepareToAnalyze(in: format)
        try await analyzer.start(inputSequence: stream)
    }

    func feed(_ buffer: AVAudioPCMBuffer) {
        if let converted = convert(buffer) { input.yield(AnalyzerInput(buffer: converted)) }
    }

    /// Her tentative end (D7.1): everything fed so far is finalized and the input stays open; the text so far
    /// (Mac probe 2026-10-23: 0.02 s, the text ready on return).
    func tentative() async throws -> String {
        try await analyzer.finalize(through: nil)
        return collected { $0.text }
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
