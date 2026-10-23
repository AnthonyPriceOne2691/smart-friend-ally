import Foundation

/// Whether a frame of her turn is speech, for the end-of-speech detector (D7.2): energy against the room's floor, or a
/// model's flag (Silero in AllyHearing). The policy of the turn is one for any activity (U18).
public protocol VoiceActivity {
    /// How long the flag trails the speech it marks: the turn's silence counts from the speech, not from the flag
    /// (Silero through sherpa: 0.128 s — the minimum silence on 32 ms windows); energy has none.
    var lag: Double { get }

    /// One frame: loud or quiet; nil while the activity has no say yet (energy calibrates on its first 8 frames).
    mutating func loud(_ samples: [Float]) -> Bool?

    /// A new listening: the activity forgets the last one.
    mutating func reset()
}

/// Energy, the probe's thresholds (voice-core): the floor of the first 8 frames clamped to [−75; −35] dB, a frame is
/// loud above max(floor + 12, −48).
public struct EnergyActivity: VoiceActivity {
    private var calibration: [Float] = [], floorDb: Float = -50
    public let lag = 0.0

    public init() {}

    public mutating func loud(_ samples: [Float]) -> Bool? {
        let db = 10 * log10(max(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count), 1e-10))
        guard calibration.count >= 8 else {
            calibration.append(db)
            floorDb = min(max(calibration.min() ?? -50, -75), -35)
            return nil
        }
        return db > max(floorDb + 12, -48)
    }

    public mutating func reset() {}
}
