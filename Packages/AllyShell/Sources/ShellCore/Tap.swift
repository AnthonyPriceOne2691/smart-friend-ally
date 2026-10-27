import AllyCore
import Foundation

/// What a tap on the child screen does (screen rules 2–4; signed in D2.2 and R, «я всё» — D7, barge-in — D6.2): the
/// bubble is the only target; asleep she stirs and the app may wake her, listening the tap ends her utterance, while
/// she greets or answers it cuts her (X14); thinking, saying goodbye or paused for a call — nothing.
public enum Tap: Equatable, Sendable {
    case wake, done, bargeIn, ignore

    public static func action(_ phase: SessionState) -> Tap {
        switch phase {
        case .asleep: .wake
        case .listening, .windingDown: .done
        case .greeting, .speaking: .bargeIn
        case .thinking, .goodbye, .paused: .ignore
        }
    }

    /// The adult's label (R): the term of the exception in the console's own words, none without a term.
    public static func label(until: Date?, zone: TimeZone) -> String? {
        until.map { "при родителе · до " + ReleaseGate.when($0, zone: zone) }
    }
}

extension Layout {
    /// A touch on Ellie: a point inside the bubble's circle; the sky, the bottom strip and the adult's corner are not.
    public func hits(x: Double, y: Double) -> Bool {
        let (dx, dy) = (x - centre.x, y - centre.y)
        return dx * dx + dy * dy <= diameter * diameter / 4
    }
}
