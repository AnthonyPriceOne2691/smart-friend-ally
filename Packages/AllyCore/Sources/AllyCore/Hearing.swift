import Foundation

/// The hearing's registry (П10), `hearing.json` of the app: the silence tail by turn kind, the tentative end, the
/// pre-roll, the longest turn, how long the microphone waits for speech, which activity tells speech from silence
/// (D7.2) and which recognizer listens (D7.3); the model's registry keeps the model.
public struct Hearing: Decodable, Equatable, Sendable {
    /// The activity the registry asks for: energy, or Silero from the models folder — its file, its size and its
    /// parameters (threshold, the shortest speech and silence, how long its flag trails the speech).
    public struct VAD: Decodable, Equatable, Sendable {
        public enum Engine: String, Decodable, Sendable { case energy, silero }

        public let engine: Engine, file: String, bytes: Int
        public let threshold: Double, minSpeech: Double, minSilence: Double, lag: Double
    }

    public let turn: TurnTiming, listenTimeout: Double, vad: VAD?, asr: Recognition?

    public init(turn: TurnTiming, listenTimeout: Double, vad: VAD? = nil, asr: Recognition? = nil) {
        (self.turn, self.listenTimeout, self.vad, self.asr) = (turn, listenTimeout, vad, asr)
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

/// Which recognizer listens (D7.3): `dictation` until step 3 decides; `gigaam` with its files (name and bytes) in the
/// models folder — external data next to the graph.
public struct Recognition: Decodable, Equatable, Sendable {
    public struct File: Decodable, Equatable, Sendable {
        public let file: String, bytes: Int64
        public init(file: String, bytes: Int64) { (self.file, self.bytes) = (file, bytes) }
    }
    public let engine: String, gigaam: [File]

    public init(engine: String, gigaam: [File]) { (self.engine, self.gigaam) = (engine, gigaam) }

    /// GigaAM when it is asked, every file is there with its size and the ONNX pair serves; else dictation and the
    /// console line that says why — nothing is downloaded.
    public func choose(sizes: [String: Int64], pairServes: Bool) -> (engine: String, line: String?) {
        guard engine == "gigaam" else { return ("dictation", nil) }
        let texts = RecognizerTexts.shared
        let reason = gigaam.lazy.compactMap { file -> String? in
            guard let found = sizes[file.file] else {
                return texts.missing.replacingOccurrences(of: "{file}", with: file.file)
            }
            guard found == file.bytes else {
                return texts.size.replacingOccurrences(of: "{file}", with: file.file)
                    .replacingOccurrences(of: "{found}", with: "\(found)")
                    .replacingOccurrences(of: "{bytes}", with: "\(file.bytes)")
            }
            return nil
        }.first ?? (pairServes ? nil : texts.pair)
        guard let reason else { return ("gigaam", nil) }
        return ("dictation", texts.fallback.replacingOccurrences(of: "{reason}", with: reason))
    }

    /// The console line when the files were there but sherpa did not open the model: dictation listens.
    public var unopened: String {
        RecognizerTexts.shared.fallback.replacingOccurrences(of: "{reason}", with: RecognizerTexts.shared.load)
    }

    /// The record's `versions.asr`: `dictation`, or GigaAM by its files' bytes.
    public func label(_ engine: String) -> String {
        engine == "gigaam" ? "gigaam-v3-ctc:\(gigaam.reduce(0) { $0 + $1.bytes })" : "dictation"
    }
}

/// `recognizers.json`: the console's words when GigaAM is asked and dictation listens.
struct RecognizerTexts: Decodable, Sendable {
    let fallback, missing, size, pair, load: String

    static let shared: RecognizerTexts = {
        guard let url = Bundle.module.url(forResource: "recognizers", withExtension: "json"),
              let bytes = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode(RecognizerTexts.self, from: bytes)
        else { fatalError("AllyCore: recognizers.json is unreadable") }
        return texts
    }()
}
