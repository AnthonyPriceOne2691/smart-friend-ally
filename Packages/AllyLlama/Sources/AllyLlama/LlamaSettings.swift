import AllyCore
import Foundation

/// The model's part of the registry `model.json` (П10): runtime and sampling; the rest of the file is the core's.
public struct LlamaSettings: Decodable, Sendable {
    public struct Runtime: Decodable, Sendable {
        public var build: String, nCtx: UInt32, nBatch: UInt32, nUbatch: UInt32, threads: Int32, gpuLayers: Int32
        public var nSeqMax: UInt32, kvUnified: Bool, swaFull: Bool, lazy: String, flashAttn: String
    }

    public struct Sampling: Decodable, Sendable {
        public let temperature: Float, topP: Float, topK: Int32, minP: Float, seed: UInt32, maxTokens: Int
    }

    public var runtime: Runtime
    public let sampling: Sampling

    public static func decode(_ data: Data) throws -> LlamaSettings {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LlamaSettings.self, from: data)
    }
}

/// What failed in llama.cpp; `stopped` is a cancelled reply, which ends quietly; `swaFullOff` — `swa_full: false` in
/// the registry: the memory of what sounded (D5) cuts tails longer than the sliding window exactly only with it.
public enum LlamaError: Error, Equatable {
    case load(String), context, tokenize, decode(Int32), stopped, swaFullOff
}

/// One reply's stop: `cancel` and the end of the stream raise it; the token loop and llama.cpp's abort hook read it.
final class StopFlag: Sendable {
    private let raised = Locked(false)
    var isRaised: Bool { raised { $0 } }
    func raise() { raised { $0 = true } }
}
