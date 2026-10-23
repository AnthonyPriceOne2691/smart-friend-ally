import AllyCore
import Foundation

/// The break after a goodbye by the limit (answer 6 to the series; its length is the parent's key, and 2026-10-23 he
/// chose «Без перерыва» — none by default). With a break set, a tap on the sleeping Ellie does not wake her until it
/// ends, and the console says until when. It lives in the app's memory: a relaunch opens the console, not her screen.
public struct Nap: Equatable, Sendable {
    public static let key = "rest_after_limit_minutes", range = 0...180, standard = 0

    /// Minutes of the break (0 — none) and the console's line when the parent's value was refused.
    public let minutes: Int, note: String?
    public private(set) var until: Date?

    public init(raw: String? = nil) {
        let value = raw.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if let value, Nap.range.contains(value) {
            (minutes, note) = (value, nil)
        } else {
            minutes = Nap.standard
            note = raw.map { _ in "перерыв вне 0–180 мин — взято " + String(Nap.standard) }
        }
    }

    /// A state of the child session: one that ended by the limit starts the break from `now`; nothing else does.
    public mutating func ended(_ talk: TalkState, at now: Date) {
        guard talk.phase == .asleep, talk.ended == "limit", minutes > 0 else { return }
        until = now.addingTimeInterval(Double(minutes) * 60)
    }

    /// The break holds: a tap on the sleeping Ellie does not wake her.
    public func holds(at now: Date) -> Bool { until.map { now < $0 } ?? false }

    /// The console's line while the break holds: «перерыв до 18:40».
    public func line(at now: Date, zone: TimeZone) -> String? {
        guard let until, holds(at: now) else { return nil }
        let formatter = DateFormatter()
        (formatter.locale, formatter.timeZone) = (Locale(identifier: "en_US_POSIX"), zone)
        formatter.dateFormat = "HH:mm"
        return "перерыв до " + formatter.string(from: until)
    }
}
