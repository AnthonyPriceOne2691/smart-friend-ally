import Foundation

/// How long a silence ends a turn: by its kind (speech-in: a 0.8 s tail cut 86% of paused phrases, 1.8 s — 1.3%).
public enum TurnKind: String, CaseIterable, Sendable { case open, closed, counting }

/// End-of-speech timing from the registry: the tail by turn kind, the tentative end, the pre-roll, the longest turn.
public struct TurnTiming: Decodable, Equatable, Sendable {
    public let tails: [String: Double], tentative: Double, preRoll: Double, maxTurn: Double

    public init(tails: [String: Double], tentative: Double, preRoll: Double, maxTurn: Double) {
        (self.tails, self.tentative, self.preRoll, self.maxTurn) = (tails, tentative, preRoll, maxTurn)
    }

    /// The tail of a kind; a kind the registry does not name gets the longest tail it names.
    public func tail(_ kind: TurnKind) -> Double { tails[kind.rawValue] ?? tails.values.max() ?? 0 }
}

/// Speech started; a tentative end after a short silence; speech resumed before the tail; the turn ended.
public enum TurnEvent: Equatable, Sendable {
    case started(at: Double), tentativeEnd(lastVoiced: Double), resumed(at: Double)
    case ended(lastVoiced: Double, byLimit: Bool)
}

/// One listening's end between the ear and the detector: her «я всё» asked from outside the audio thread — taken on the
/// next frame —, why the detector ended the turn, for the ear's record, and her pauses as they come (D7.1).
public final class TurnEnding: Sendable {
    public enum Reason: String, Sendable { case tail, limit, done }
    private let state = Locked<(asked: Bool, reason: Reason?)>((false, nil))
    private let pauses: @Sendable (TurnEvent) -> Void

    /// - Parameter pauses: the tentative end and the resumed speech, on the audio thread.
    public init(pauses: @escaping @Sendable (TurnEvent) -> Void = { _ in }) { self.pauses = pauses }

    func saw(_ event: TurnEvent) { pauses(event) }

    public func ask() { state { $0.asked = true } }

    /// Why the turn ended; nil until it has.
    public var reason: Reason? { state { $0.reason } }

    func take() -> Bool {
        state { (now: inout (asked: Bool, reason: Reason?)) -> Bool in
            defer { now.asked = false }
            return now.asked
        }
    }

    func ended(_ reason: Reason) { state { $0.reason = reason } }
}

/// End of speech by voice activity — energy (the probe's thresholds) or a model's flag (D7.2) — speech after 3 loud
/// frames, silence counted from the speech behind the flag. A tentative end lets a later delivery start recognition
/// silently; `preRoll` seconds before the start go with it; `maxTurn` ends a turn noise would never let end; her «я
/// всё» (`ending`) ends it on the next frame, as the tail would.
public struct TurnDetector {
    public private(set) var preRoll: [[Float]] = []
    private var ringTimes: [Double] = [], loud = 0, activity: VoiceActivity
    private var start: Double?, lastVoiced: Double?, tentativeSent = false
    private let tail: Double, timing: TurnTiming, ending: TurnEnding?

    /// - Parameter activity: what tells speech from silence; nil — energy (D7.2).
    public init(kind: TurnKind, timing: TurnTiming, ending: TurnEnding? = nil, activity: VoiceActivity? = nil) {
        (tail, self.timing, self.ending) = (timing.tail(kind), timing, ending)
        self.activity = activity ?? EnergyActivity()
        self.activity.reset()
    }

    /// One frame of samples heard at `time` seconds; at most one event.
    public mutating func process(_ samples: [Float], at time: Double) -> TurnEvent? {
        guard !samples.isEmpty else { return nil }
        if ending?.take() == true { return end(.done, at: time) }
        if start == nil { remember(samples, at: time) }
        guard let loudNow = activity.loud(samples) else { return nil }
        if let begun = start, time - begun >= timing.maxTurn { return end(.limit, at: time) }
        return loudNow ? loudFrame(at: time) : quietFrame(at: time)
    }

    private mutating func loudFrame(at time: Double) -> TurnEvent? {
        loud += 1
        guard loud >= 3 else { return nil }
        lastVoiced = time - activity.lag
        if start == nil {
            start = time
            return .started(at: time)
        }
        guard tentativeSent else { return nil }
        tentativeSent = false
        ending?.saw(.resumed(at: time))
        return .resumed(at: time)
    }

    private mutating func quietFrame(at time: Double) -> TurnEvent? {
        loud = 0
        guard start != nil, let last = lastVoiced else { return nil }
        if time - last >= tail { return end(.tail, at: time) }
        guard !tentativeSent, time - last >= timing.tentative else { return nil }
        tentativeSent = true
        ending?.saw(.tentativeEnd(lastVoiced: last))
        return .tentativeEnd(lastVoiced: last)
    }

    private mutating func end(_ reason: TurnEnding.Reason, at time: Double) -> TurnEvent {
        defer { (start, lastVoiced, tentativeSent, loud) = (nil, nil, false, 0) }
        ending?.ended(reason)
        return .ended(lastVoiced: lastVoiced ?? time, byLimit: reason == .limit)
    }

    /// The ring before the start: back to the newest frame at least `preRoll` seconds older than this one.
    private mutating func remember(_ samples: [Float], at time: Double) {
        preRoll.append(samples)
        ringTimes.append(time)
        while ringTimes.count > 1, time - ringTimes[1] >= timing.preRoll {
            preRoll.removeFirst()
            ringTimes.removeFirst()
        }
    }
}
