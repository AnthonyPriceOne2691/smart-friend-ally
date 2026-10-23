import Foundation

/// The hearing's registry (П10), `hearing.json` of the app: the silence tail by turn kind, the tentative end, the
/// pre-roll, the longest turn and how long the microphone waits for speech; the recognizer (D7.3); the model's
/// registry keeps the model.
public struct Hearing: Decodable, Equatable, Sendable {
    public let turn: TurnTiming, listenTimeout: Double, asr: Recognition?

    public init(turn: TurnTiming, listenTimeout: Double, asr: Recognition? = nil) {
        (self.turn, self.listenTimeout, self.asr) = (turn, listenTimeout, asr)
    }

    public static func decode(_ data: Data) throws -> Hearing {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Hearing.self, from: data)
    }
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

    /// The record's `versions.asr`: `dictation`, or GigaAM by its files' bytes.
    public func label(_ engine: String) -> String {
        engine == "gigaam" ? "gigaam-v3-ctc:\(gigaam.reduce(0) { $0 + $1.bytes })" : "dictation"
    }
}

/// `recognizers.json`: the console's words when GigaAM is asked and dictation listens.
struct RecognizerTexts: Decodable, Sendable {
    let fallback, missing, size, pair: String

    static let shared: RecognizerTexts = {
        guard let url = Bundle.module.url(forResource: "recognizers", withExtension: "json"),
              let bytes = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode(RecognizerTexts.self, from: bytes)
        else { fatalError("AllyCore: recognizers.json is unreadable") }
        return texts
    }()
}
