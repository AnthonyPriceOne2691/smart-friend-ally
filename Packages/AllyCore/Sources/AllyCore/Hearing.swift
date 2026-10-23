import Foundation

/// The hearing's registry (П10), `hearing.json` of the app: the silence tail by turn kind, the tentative end, the
/// pre-roll, the longest turn and how long the microphone waits for speech; the model's registry keeps the model.
public struct Hearing: Decodable, Equatable, Sendable {
    public let turn: TurnTiming, listenTimeout: Double

    public init(turn: TurnTiming, listenTimeout: Double) { (self.turn, self.listenTimeout) = (turn, listenTimeout) }

    public static func decode(_ data: Data) throws -> Hearing {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Hearing.self, from: data)
    }
}
