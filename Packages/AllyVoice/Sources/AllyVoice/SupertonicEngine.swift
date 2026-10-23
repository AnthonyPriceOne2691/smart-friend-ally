import AllyOnnx
import Foundation

/// Supertonic 3 on the one ONNX Runtime of the app: one sentence per call, four sessions — duration, text encoder,
/// vector estimator (the denoising loop) and vocoder — as `Supertonic.__call__` of supertonic-py with batch size 1.
/// The weights are in external-data format, so ORT maps them from the files (≈ 48 MB footprint instead of 471 on the
/// Mac); every session runs on `options` — 2 threads without spin-wait by default.
public final class SupertonicEngine: SpeechEngine, @unchecked Sendable {
    public let sampleRate: Int, options: OnnxOptions
    let text: SupertonicText
    private let chunkSize: Int, channels: Int, styleFolder: URL
    private let duration: OnnxSession, encoder: OnnxSession, estimator: OnnxSession, vocoder: OnnxSession
    private let lock = NSLock()
    private var styles: [String: VoiceStyle] = [:]

    private struct Config: Decodable {
        struct Autoencoder: Decodable {
            let sampleRate: Int, baseChunkSize: Int
        }

        struct Latent: Decodable {
            let chunkCompressFactor: Int, latentDim: Int
        }

        let ae: Autoencoder, ttl: Latent
    }

    /// `folder` holds `onnx/` (tts.json, unicode_indexer.json, the four graphs and their weights) and `voice_styles/`.
    public init(folder: URL, options: OnnxOptions = OnnxOptions()) throws {
        let onnx = folder.appendingPathComponent("onnx")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let config = try decoder.decode(Config.self, from: Data(contentsOf: onnx.appendingPathComponent("tts.json")))
        sampleRate = config.ae.sampleRate
        chunkSize = config.ae.baseChunkSize * config.ttl.chunkCompressFactor  // 3072 samples a latent frame
        channels = config.ttl.latentDim * config.ttl.chunkCompressFactor  // 144
        text = try SupertonicText(indexerURL: onnx.appendingPathComponent("unicode_indexer.json"))
        let session = { (name: String) in
            try OnnxSession(path: onnx.appendingPathComponent("\(name).onnx"), options: options)
        }
        (duration, encoder) = (try session("duration_predictor"), try session("text_encoder"))
        (estimator, vocoder) = (try session("vector_estimator"), try session("vocoder"))
        (self.options, styleFolder) = (options, folder.appendingPathComponent("voice_styles"))
    }

    public func synthesize(_ text: String, voice: VoicePreset) throws -> SpeechAudio {
        try synthesize(text, voice: voice, noise: nil)
    }

    /// `noise` — the initial latent, 144 × frames values; nil draws it from `voice.seed` (parity tests pass Python's).
    public func synthesize(_ sentence: String, voice: VoicePreset, noise: [Float]?) throws -> SpeechAudio {
        guard voice.speed >= VoicePreset.minSpeed else { throw SpeechError.speedBelowFloor(voice.speed) }
        guard sentence.contains(where: { !$0.isWhitespace }) else { throw SpeechError.emptyText }
        var stages: [String: Double] = [:], clock = Date()
        func lap(_ stage: String) { stages[stage] = Date().timeIntervalSince(clock); clock = Date() }
        let ids = text.encode(sentence), style = try style(voice.style)
        let mask = OnnxTensor.float(.init(repeating: 1, count: ids.count), shape: [1, 1, ids.count])
        let tokens: [String: OnnxTensor] = ["text_ids": .int64(ids, shape: [1, ids.count]), "text_mask": mask]
        lap("text")
        let predicted = try duration.run(tokens.merging(["style_dp": .float(style.dp, shape: style.dpShape)]) { $1 },
                                         outputs: ["duration"])["duration"]?.floats.first ?? 0
        let seconds = predicted / Float(voice.speed)
        lap("duration")
        let embedding = try encoder.run(tokens.merging(["style_ttl": .float(style.ttl, shape: style.ttlShape)]) { $1 },
                                        outputs: ["text_emb"])["text_emb"] ?? .float([], shape: [0])
        lap("encoder")
        let frames = (Int(seconds * Float(sampleRate)) + chunkSize - 1) / chunkSize
        let conditions: [String: OnnxTensor] = ["text_emb": embedding, "text_mask": mask,
                                                "style_ttl": .float(style.ttl, shape: style.ttlShape)]
        let latent = try denoise(noise ?? gaussianNoise(count: channels * frames, seed: voice.seed), frames: frames,
                                 inputs: conditions, steps: voice.steps)
        lap("denoise")
        let wav = try vocoder.run(["latent": latent], outputs: ["wav_tts"])["wav_tts"]?.floats ?? []
        lap("vocoder")
        return SpeechAudio(samples: wav, rate: sampleRate, duration: Double(seconds), stages: stages)
    }

    /// The flow-matching loop: the estimator's output is the next step's input, `steps` times.
    private func denoise(_ start: [Float], frames: Int, inputs: [String: OnnxTensor], steps: Int) throws -> OnnxTensor {
        guard start.count == channels * frames else {
            throw SpeechError.badModel("noise: \(start.count) values for \(channels) × \(frames)")
        }
        var latent = OnnxTensor.float(start, shape: [1, channels, frames])
        let fixed = inputs.merging(["latent_mask": .float(.init(repeating: 1, count: frames), shape: [1, 1, frames]),
                                    "total_step": .float([Float(steps)], shape: [1])]) { $1 }
        for step in 0..<steps {
            let feed = fixed.merging(["noisy_latent": latent, "current_step": .float([Float(step)], shape: [1])]) { $1 }
            latent = try estimator.run(feed, outputs: ["denoised_latent"])["denoised_latent"] ?? latent
        }
        return latent
    }

    /// The voice of `spec`, loaded once.
    public func style(_ spec: String) throws -> VoiceStyle {
        lock.lock()
        defer { lock.unlock() }
        if let known = styles[spec] { return known }
        let made = try VoiceStyle.resolve(spec, in: styleFolder)
        styles[spec] = made
        return made
    }
}
