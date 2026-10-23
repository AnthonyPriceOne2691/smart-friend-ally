import Foundation

/// The hearing's registry (П10), `hearing.json` of the app: the silence tail by turn kind, the tentative end, the
/// pre-roll, the longest turn, how long the microphone waits for speech and which activity tells speech from silence
/// (D7.2); the model's registry keeps the model.
public struct Hearing: Decodable, Equatable, Sendable {
    /// The activity the registry asks for: energy, or Silero from the models folder — its file, its size and its
    /// parameters (threshold, the shortest speech and silence, how long its flag trails the speech).
    public struct VAD: Decodable, Equatable, Sendable {
        public enum Engine: String, Decodable, Sendable { case energy, silero }

        public let engine: Engine, file: String, bytes: Int
        public let threshold: Double, minSpeech: Double, minSilence: Double, lag: Double
    }

    public let turn: TurnTiming, listenTimeout: Double, vad: VAD?

    public init(turn: TurnTiming, listenTimeout: Double, vad: VAD? = nil) {
        (self.turn, self.listenTimeout, self.vad) = (turn, listenTimeout, vad)
    }

    public static func decode(_ data: Data) throws -> Hearing {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Hearing.self, from: data)
    }

    /// Who tells speech from silence on the phone (D7.2): Silero when the registry asks for it, the runtime serves the
    /// API sherpa was built with and the model lies in the models folder with its size; else energy, and why.
    public func listening(pair: () -> OnnxPair, fileBytes: (String) -> Int?) -> Listening {
        guard let vad, vad.engine == .silero else { return .energy }
        let found = pair()
        guard found.served else { return .noApi(found.api) }
        guard fileBytes(vad.file) == vad.bytes else { return .noFile(vad.file) }
        return .silero(found)
    }
}

/// The runtime pair as the app found it (D7.2): ORT's version, the C API sherpa-onnx was built with and whether ORT
/// serves it, sherpa's version.
public struct OnnxPair: Equatable, Sendable {
    public let ort: String, api: Int, served: Bool, sherpa: String

    public init(ort: String, api: Int, served: Bool, sherpa: String) {
        (self.ort, self.api, self.served, self.sherpa) = (ort, api, served, sherpa)
    }
}

/// Which activity listens, and the console's line about it (U16, U19).
public enum Listening: Equatable, Sendable {
    case energy, silero(OnnxPair), noApi(Int), noFile(String), failed

    public var line: String {
        let texts = ListeningTexts.shared
        return switch self {
        case .energy: texts.energy
        case .silero(let pair): ReleaseGate.fill(ReleaseGate.fill(texts.silero, "sherpa", pair.sherpa), "ort", pair.ort)
        case .noApi(let api): ReleaseGate.fill(texts.noApi, "api", "\(api)")
        case .noFile(let file): ReleaseGate.fill(texts.noFile, "file", file)
        case .failed: texts.failed
        }
    }
}

/// `listening.json`: the console's lines about the hearing, one copy.
struct ListeningTexts: Decodable, Sendable {
    let silero, noApi, noFile, energy, failed: String

    static let shared: ListeningTexts = {
        guard let url = Bundle.module.url(forResource: "listening", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: listening.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(ListeningTexts.self, from: bytes)
        } catch {
            fatalError("AllyCore: listening.json does not decode: \(error)")
        }
    }()
}
