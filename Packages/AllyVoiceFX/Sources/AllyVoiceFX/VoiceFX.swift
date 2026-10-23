import CVoiceFX

public enum VoiceFXError: Error, Equatable {
    case badRate(Int)
    case outOfMemory
}

/// Voice processing after synthesis (voice series V4a): TD-PSOLA pitch and formant shift in semitones and the 0.97 peak
/// guard of the round-3 stand chain the parent chose; the chain's EQ arrives with V4b. The output keeps the input's
/// length.
public struct VoiceFX: Equatable, Sendable {
    public let pitch: Double
    public let formant: Double

    public init(pitch: Double, formant: Double) {
        self.pitch = pitch
        self.formant = formant
    }

    public func process(_ samples: [Float], rate: Int) throws -> [Float] {
        guard rate > 0 else { throw VoiceFXError.badRate(rate) }
        var out = [Float](repeating: 0, count: samples.count)
        let status = samples.withUnsafeBufferPointer { inp in
            out.withUnsafeMutableBufferPointer { res in
                ally_fx_process(inp.baseAddress, Int32(inp.count), Int32(rate), pitch, formant, res.baseAddress)
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
