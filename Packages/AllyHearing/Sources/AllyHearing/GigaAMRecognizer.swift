import AllyCore
import AllySherpa
import Foundation

/// GigaAM-v3 CTC through sherpa-onnx's C API (D7.3): NeMo CTC int8 on the app's one ONNX Runtime, two threads, the
/// weights as external data next to the graph (footprint 0.4 GB on the Mac instead of 0.65); one utterance at a time.
public final class GigaAMRecognizer: @unchecked Sendable {
    private let recognizer: OpaquePointer, lock = NSLock()

    public init?(model: URL, tokens: URL, threads: Int = 2) {
        var settings = SherpaOnnxOfflineRecognizerConfig()
        (settings.feat_config.sample_rate, settings.feat_config.feature_dim) = (16_000, 64)
        settings.model_config.num_threads = Int32(threads)
        let made = model.path.withCString { graph in
            tokens.path.withCString { list in
                "cpu".withCString { cpu in
                    "greedy_search".withCString { greedy in
                        (settings.model_config.nemo_ctc.model, settings.model_config.tokens) = (graph, list)
                        (settings.model_config.provider, settings.decoding_method) = (cpu, greedy)
                        return SherpaOnnxCreateOfflineRecognizer(&settings)
                    }
                }
            }
        }
        guard let made else { return nil }
        recognizer = made
    }

    deinit { SherpaOnnxDestroyOfflineRecognizer(recognizer) }

    /// Her utterance, 16 kHz mono in [−1; 1] — the text.
    public func decode(_ samples: [Float]) -> String {
        lock.lock()
        defer { lock.unlock() }
        guard let stream = SherpaOnnxCreateOfflineStream(recognizer) else { return "" }
        defer { SherpaOnnxDestroyOfflineStream(stream) }
        samples.withUnsafeBufferPointer {
            SherpaOnnxAcceptWaveformOffline(stream, 16_000, $0.baseAddress, Int32($0.count))
        }
        SherpaOnnxDecodeOfflineStream(recognizer, stream)
        guard let result = SherpaOnnxGetOfflineStreamResult(stream) else { return "" }
        defer { SherpaOnnxDestroyOfflineRecognizerResult(result) }
        return result.pointee.text.map { String(cString: $0) } ?? ""
    }

    /// What listens: GigaAM's decoder (nil — dictation), the record's `versions.asr`, the console line of a refusal.
    public struct Choice: Sendable {
        public let decode: (@Sendable ([Float]) -> String)?, label: String, line: String?
    }

    /// The recognizer the registry asks for (U22): GigaAM when its files are there with their sizes and the pair
    /// serves; else dictation and the console line.
    public static func choose(_ hearing: Hearing, models: URL) -> Choice {
        guard let asr = hearing.asr else { return Choice(decode: nil, label: "dictation", line: nil) }
        let sizes = Dictionary(uniqueKeysWithValues: asr.gigaam.compactMap { file -> (String, Int64)? in
            let path = models.appendingPathComponent(file.file).path
            let size = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? NSNumber
            return size.map { (file.file, $0.int64Value) }
        })
        let pick = asr.choose(sizes: sizes, pairServes: Sherpa.paired)
        let dictation = asr.label("dictation")
        guard pick.engine == "gigaam" else { return Choice(decode: nil, label: dictation, line: pick.line) }
        let graph = asr.gigaam.first { $0.file.hasSuffix(".onnx") }
        let list = asr.gigaam.first { $0.file.hasSuffix(".txt") }
        guard let graph, let list,
              let recognizer = GigaAMRecognizer(model: models.appendingPathComponent(graph.file),
                                                tokens: models.appendingPathComponent(list.file)) else {
            return Choice(decode: nil, label: dictation, line: asr.unopened)
        }
        return Choice(decode: { recognizer.decode($0) }, label: asr.label("gigaam"), line: nil)
    }
}
