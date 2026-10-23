import Foundation

/// The initial latent noise of flow matching: SplitMix64 and Box–Muller — reproducible in Swift and N(0, 1) like
/// numpy's randn (the stand's noise; parity tests feed the Python reference's own noise instead).
struct SplitMix64 {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in (0, 1].
    mutating func unit() -> Double { (Double(next() >> 11) + 1) / 9_007_199_254_740_992 }
}

func gaussianNoise(count: Int, seed: UInt64) -> [Float] {
    var rng = SplitMix64(state: seed)
    var out = [Float](repeating: 0, count: count)
    var index = 0
    while index < count {
        let radius = (-2 * log(rng.unit())).squareRoot(), angle = 2 * Double.pi * rng.unit()
        out[index] = Float(radius * cos(angle))
        if index + 1 < count { out[index + 1] = Float(radius * sin(angle)) }
        index += 2
    }
    return out
}
