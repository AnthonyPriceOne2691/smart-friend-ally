import Foundation

/// The trace's line for the system log (sim-app): the same wordless line as `Caches/turns.jsonl`, handed to `emit` —
/// the app's `Logger` (`com.anthonypriceone.ally`, category `turn`) — so a turn on the Mac is read with `log show` and
/// the app's container stays unread. The words of a record never reach it: this sink has no `write(_:words:)` of its
/// own, and `TraceSink`'s drops them (K9, N8).
public struct TraceLine: TraceSink {
    private let emit: @Sendable (String) -> Void

    public init(_ emit: @escaping @Sendable (String) -> Void) { self.emit = emit }

    public func write(_ trace: TurnTrace) {
        if let line = trace.jsonLine() { emit(line) }
    }
}
