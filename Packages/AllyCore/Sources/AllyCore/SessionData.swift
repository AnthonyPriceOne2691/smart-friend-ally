import Discipline
import Foundation

/// `session.json`, one copy: the session's phrases with the turn mode whose contract each passes (an empty text is
/// the mode's own canned reply), her goodbyes as whole utterances, misses in a row before rest, the limit key's range.
struct SessionData: Decodable, Sendable {
    struct Phrase: Decodable, Sendable { let mode: String, text: String }
    struct Minutes: Decodable, Sendable { let `default`, min, max: Int }

    let phrases: [String: Phrase], goodbyeWords: [String], friendName: String, missesBeforeRest: Int
    let limitMinutes: Minutes, limitNote: String

    static let shared: SessionData = {
        guard let url = Bundle.module.url(forResource: "session", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: session.json is unreadable") }
        do {
            return try decode(bytes)
        } catch {
            fatalError("AllyCore: session.json does not decode: \(error)")
        }
    }()

    static func decode(_ bytes: Data) throws -> SessionData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SessionData.self, from: bytes)
    }

    /// The phrase's mode and what the voice gets: its text through that mode's contract.
    func turn(_ key: String) -> (mode: TurnMode, turn: Turn) {
        let phrase = phrases[key]
        let mode = phrase.flatMap { TurnMode(rawValue: $0.mode) } ?? .talk
        return (mode, TurnContract(mode: mode).finish(phrase?.text ?? ""))
    }

    /// Her goodbye: the whole utterance, lowercased, «ё» as «е», marks as spaces, the friend's name dropped.
    func isGoodbye(_ utterance: String) -> Bool {
        let words = utterance.lowercased().replacingOccurrences(of: "ё", with: "е")
            .split { !$0.isLetter }.map(String.init).filter { $0 != friendName }
        return goodbyeWords.contains(words.joined(separator: " "))
    }
}

/// The parent's key `session_limit_minutes`: minutes within the range of `session.json`; out of it or not a number —
/// the default and a console line; no key — the default, silently. Its reader is the session (П29).
public struct SessionSettings: Equatable, Sendable {
    public static let key = "session_limit_minutes"
    /// The soft limit, seconds; the console line when the parent's value was refused.
    public let limit: Double, note: String?

    public init(limitMinutes raw: String? = nil) {
        let data = SessionData.shared, range = data.limitMinutes
        let minutes = raw.flatMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if let minutes, minutes >= Double(range.min), minutes <= Double(range.max) {
            (limit, note) = (minutes * 60, nil)
            return
        }
        limit = Double(range.default) * 60
        note = raw.map { _ in
            data.limitNote.replacingOccurrences(of: "{min}", with: "\(range.min)")
                .replacingOccurrences(of: "{max}", with: "\(range.max)")
                .replacingOccurrences(of: "{default}", with: "\(range.default)")
        }
    }
}
