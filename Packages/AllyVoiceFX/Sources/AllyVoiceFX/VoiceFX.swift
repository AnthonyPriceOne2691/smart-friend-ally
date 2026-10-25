import CVoiceFX

/// One EQ band of the voice preset (RBJ cookbook).
public struct EQBand: Equatable, Sendable {
    public enum Kind: Int32, Sendable {
        case lowShelf = 0, peak = 1, highShelf = 2
    }

    public let kind: Kind
    public let frequency: Double
    public let gainDB: Double
    public let q: Double

    public init(_ kind: Kind, frequency: Double, gainDB: Double, q: Double) {
        self.kind = kind
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
    }

    var raw: AllyEQBand { AllyEQBand(kind: kind.rawValue, freq: frequency, gain_db: gainDB, q: q) }
}

/// The EQ stage of the chain: the bands in cascade, the stand's biquads (V4b1).
public struct VoiceEQ: Equatable, Sendable {
    public let bands: [EQBand]

    public init(bands: [EQBand] = []) { self.bands = bands }

    public func apply(_ samples: [Float], rate: Int) throws -> [Float] {
        guard rate > 0 else { throw VoiceFXError.badRate(rate) }
        var out = samples
        let raw = bands.map(\.raw)
        raw.withUnsafeBufferPointer { eq in
            out.withUnsafeMutableBufferPointer { res in
                ally_eq(res.baseAddress, Int32(res.count), Int32(rate), eq.baseAddress, Int32(eq.count))
            }
        }
        return out
    }
}

public enum VoiceFXError: Error, Equatable {
    case badRate(Int)
    case outOfMemory
}

/// Voice processing after synthesis (voice series V4a, V4b1): TD-PSOLA pitch and formant shift in semitones, the EQ and
/// the 0.97 peak guard — the round-3 stand chain the parent chose. The output keeps the input's length.
public struct VoiceFX: Equatable, Sendable {
    public let pitch: Double
    public let formant: Double
    public let eq: VoiceEQ

    public init(pitch: Double, formant: Double, eq: VoiceEQ = VoiceEQ()) {
        self.pitch = pitch
        self.formant = formant
        self.eq = eq
    }

    public func process(_ samples: [Float], rate: Int) throws -> [Float] {
        guard rate > 0 else { throw VoiceFXError.badRate(rate) }
        var out = [Float](repeating: 0, count: samples.count)
        let raw = eq.bands.map(\.raw)
        let status = samples.withUnsafeBufferPointer { inp in
            raw.withUnsafeBufferPointer { bands in
                out.withUnsafeMutableBufferPointer { res in
                    ally_fx_process(inp.baseAddress, Int32(inp.count), Int32(rate), pitch, formant,
                                    bands.baseAddress, Int32(bands.count), res.baseAddress)
                }
            }
        }
        guard status == 0 else { throw VoiceFXError.outOfMemory }
        return out
    }
}

/// Own autocorrelation pitch track of the processing: F0 every 5 ms, 0 = unvoiced; frame i is centred at
/// `start + i * step` seconds.
public struct PitchTrack: Equatable, Sendable {
    public static let step = 0.005
    public let start: Double
    public let f0: [Float]

    public init(_ samples: [Float], rate: Int) throws {
        guard rate > 0 else { throw VoiceFXError.badRate(rate) }
        var f0 = [Float](repeating: 0, count: Int(ally_pitch_frames(Int32(samples.count), Int32(rate))))
        var start = 0.0
        let frames = samples.withUnsafeBufferPointer { inp in
            f0.withUnsafeMutableBufferPointer { res in
                ally_pitch_track(inp.baseAddress, Int32(inp.count), Int32(rate), res.baseAddress, &start)
            }
        }
        guard frames >= 0 else { throw VoiceFXError.outOfMemory }
        self.start = start
        self.f0 = f0
    }
}
