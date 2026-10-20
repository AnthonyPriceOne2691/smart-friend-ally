import Foundation

/// The recognizer's text of one phrase: final pieces in order and, if the stream ended before the last piece was
/// finalized, that volatile piece too — dictation marks finals only with frequent finalization (probe `Voice.swift`).
public struct TranscriptCollector: Sendable {
    private var finals: [String] = [], pending = ""

    public init() {}

    /// Adds a result; returns the running text to show.
    @discardableResult
    public mutating func add(_ piece: String, isFinal: Bool) -> String {
        if isFinal { finals.append(piece) }
        pending = isFinal ? "" : piece
        return text
    }

    public var text: String { (finals + [pending]).joined(separator: " ").trimmingCharacters(in: .whitespaces) }
}
