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

/// End of speech by energy, the probe's thresholds: the floor of the first 8 frames clamped to [−75; −35] dB, the
/// threshold max(floor + 12, −48), speech after 3 loud frames. A tentative end lets a later delivery start recognition
/// silently; `preRoll` seconds before the start go with it; `maxTurn` ends a turn noise would never let end.
public struct TurnDetector {
    public private(set) var preRoll: [[Float]] = []
    private var ringTimes: [Double] = [], calibration: [Float] = [], floorDb: Float = -50, loud = 0
    private var start: Double?, lastVoiced: Double?, tentativeSent = false
    private let tail: Double, timing: TurnTiming

    public init(kind: TurnKind, timing: TurnTiming) { (tail, self.timing) = (timing.tail(kind), timing) }
    /// One frame of samples heard at `time` seconds; at most one event.
    public mutating func process(_ samples: [Float], at time: Double) -> TurnEvent? {
        guard !samples.isEmpty else { return nil }
        let db = 10 * log10(max(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count), 1e-10))
        if start == nil { remember(samples, at: time) }
        guard calibration.count >= 8 else {
            calibration.append(db)
            floorDb = min(max(calibration.min() ?? -50, -75), -35)
            return nil
        }
        if let begun = start, time - begun >= timing.maxTurn { return end(byLimit: true, at: time) }
        return db > max(floorDb + 12, -48) ? loudFrame(at: time) : quietFrame(at: time)
    }

    private mutating func loudFrame(at time: Double) -> TurnEvent? {
        loud += 1
        guard loud >= 3 else { return nil }
        lastVoiced = time
        if start == nil {
            start = time
            return .started(at: time)
        }
        guard tentativeSent else { return nil }
        tentativeSent = false
        return .resumed(at: time)
    }

    private mutating func quietFrame(at time: Double) -> TurnEvent? {
        loud = 0
        guard start != nil, let last = lastVoiced else { return nil }
        if time - last >= tail { return end(byLimit: false, at: time) }
        guard !tentativeSent, time - last >= timing.tentative else { return nil }
        tentativeSent = true
        return .tentativeEnd(lastVoiced: last)
    }

    private mutating func end(byLimit: Bool, at time: Double) -> TurnEvent {
        defer { (start, lastVoiced, tentativeSent, loud) = (nil, nil, false, 0) }
        return .ended(lastVoiced: lastVoiced ?? time, byLimit: byLimit)
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
