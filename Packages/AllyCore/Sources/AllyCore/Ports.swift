import Foundation

/// The model of a turn: the reply's accumulated text as it grows; `cancel` stops it at the next token and ends it.
public protocol LanguageModel: AnyObject, Sendable {
    func reply(to utterance: String) -> AsyncThrowingStream<String, Error>
    func cancel()
}

/// The voice: `speak` returns when the sentence has sounded or was stopped; `stop` silences it at once.
public protocol VoiceOutput: AnyObject, Sendable {
    func speak(_ sentence: String) async throws
    func stop()
}

/// Time of a turn — seconds for the stage times and the first-sentence watchdog; tests drive a virtual one.
public protocol TurnClock: Sendable {
    func now() -> Double
    func sleep(seconds: Double) async throws
}

/// Wall time: the process uptime and `Task.sleep`.
public struct SystemClock: TurnClock {
    public init() {}
    public func now() -> Double { ProcessInfo.processInfo.systemUptime }
    public func sleep(seconds: Double) async throws { try await Task.sleep(nanoseconds: UInt64(max(seconds, 0) * 1e9)) }
}
