import Foundation

/// The registry of the model and its parameters (П10), `model.json`: the core reads the weights file and size, the
/// persona, the voice, timing and timeouts; runtime and sampling are the model package's; pins — `model_surface.txt`.
public struct ModelRegistry: Decodable, Sendable {
    public struct Model: Decodable, Sendable { public let file: String, bytes: Int64 }

    public let model: Model, persona: String, voice: String
    public let turn: TurnTiming, listenTimeout: Double, firstSentenceTimeout: Double

    public static func decode(_ data: Data) throws -> ModelRegistry {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ModelRegistry.self, from: data)
    }
}

/// Are the weights there and the right ones — in words for the console; nothing is ever downloaded.
public enum ModelCheck: Equatable, Sendable {
    case ready(URL), missing(String), wrongSize(found: Int64, expected: Int64), unreadable(String)

    public static func check(registry data: Data, in directory: URL) -> ModelCheck {
        let registry: ModelRegistry
        do {
            registry = try ModelRegistry.decode(data)
        } catch {
            return .unreadable(String(String(describing: error).prefix(80)))
        }
        let url = directory.appendingPathComponent(registry.model.file)
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber else {
            return .missing(registry.model.file)
        }
        let found = size.int64Value, expected = registry.model.bytes
        return found == expected ? .ready(url) : .wrongSize(found: found, expected: expected)
    }

    /// The console line; nil when ready.
    public var message: String? {
        switch self {
        case .ready: return nil
        case .missing: return "модели нет: скопируй с Mac"
        case let .wrongSize(n, m): return "модель не та: \(n) байт вместо \(m)"
        case .unreadable(let why): return "реестр не читается: \(why)"
        }
    }
}
