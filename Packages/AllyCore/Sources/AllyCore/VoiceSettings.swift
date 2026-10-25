import Foundation

/// The voice's settings (voice series V4b1), `voice.json`: the preset line the parent tunes — one line, no code — and
/// the files of the voice folder. Where a file comes from on the Mac and its sha256 are the copy command's
/// (`scripts/copy_voice.py`); the app reads the rest.
public struct VoiceSettings: Sendable, Equatable {
    public let preset: VoicePresetLine
    public let folder: String
    public let files: [VoiceFile]
    /// The console line when the preset asked for what the engine refuses; nil otherwise.
    public let note: String?

    public static func decode(_ data: Data) throws -> VoiceSettings {
        let raw = try JSONDecoder().decode(Raw.self, from: data)
        let floor = VoicePresetLine.minSpeed, asked = raw.preset.speed
        let note = asked < floor
            ? "скорость " + decimal(asked) + " ниже " + decimal(floor) + " — взято " + decimal(floor) : nil
        let preset = VoicePresetLine(style: raw.preset.style, speed: max(asked, floor), steps: raw.preset.steps,
                                     pitch: raw.preset.pitch, formant: raw.preset.formant, eq: raw.preset.eq)
        return VoiceSettings(preset: preset, folder: raw.folder, files: raw.files, note: note)
    }

    private struct Raw: Decodable {
        let preset: VoicePresetLine, folder: String, files: [VoiceFile]
    }

    private static func decimal(_ value: Double) -> String {
        String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }
}

/// The preset line: style or mix of the synthesis («F2», «F2+F5:0.3»), its speed and denoising steps, then the
/// processing — pitch and formant shifts in semitones and the EQ bands.
public struct VoicePresetLine: Decodable, Sendable, Equatable {
    /// Below it Supertonic repeats words (voice-engine): the line may ask, the voice takes the floor.
    public static let minSpeed = 0.85

    public let style: String, speed: Double, steps: Int, pitch: Double, formant: Double, eq: [Band]

    /// One band as the line writes it: `["lowshelf" | "peak" | "highshelf", Hz, dB, Q]`.
    public struct Band: Decodable, Sendable, Equatable {
        public static let kinds = ["lowshelf", "peak", "highshelf"]
        public let kind: String, frequency: Double, gainDB: Double, q: Double

        public init(from decoder: Decoder) throws {
            var row = try decoder.unkeyedContainer()
            kind = try row.decode(String.self)
            frequency = try row.decode(Double.self)
            gainDB = try row.decode(Double.self)
            q = try row.decode(Double.self)
            guard Self.kinds.contains(kind) else {
                throw DecodingError.dataCorruptedError(in: row, debugDescription: "полоса \(kind)")
            }
        }
    }
}

/// A file of the voice folder: its path there, its size, its group — `voice` (Supertonic, checked by the app) or
/// `accent` (RUAccent: copied now, checked once the placer uses it).
public struct VoiceFile: Decodable, Sendable, Equatable {
    public let path: String, bytes: Int64, group: String

    private enum CodingKeys: String, CodingKey {
        case path = "to", bytes, group
    }
}

/// Are the voice's files there and the right ones — in words for the console; nothing is ever downloaded.
public enum VoiceCheck: Equatable, Sendable {
    case ready, missing(String), wrongSize(String, found: Int64, expected: Int64)

    /// The `voice` group in `folder`.
    public static func check(_ settings: VoiceSettings, in folder: URL) -> VoiceCheck {
        for file in settings.files where file.group == "voice" {
            let path = folder.appendingPathComponent(file.path).path
            guard let size = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? NSNumber else {
                return .missing(file.path)
            }
            let found = size.int64Value
            if found != file.bytes { return .wrongSize(file.path, found: found, expected: file.bytes) }
        }
        return .ready
    }

    /// The console line; nil when ready.
    public var message: String? {
        switch self {
        case .ready: return nil
        case .missing: return "голоса нет: скопируй с Mac"
        case let .wrongSize(_, n, m): return "голос не тот: \(n) байт вместо \(m)"
        }
    }
}
