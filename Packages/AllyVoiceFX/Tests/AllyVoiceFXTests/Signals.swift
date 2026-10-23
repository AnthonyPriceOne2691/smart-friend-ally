import Foundation

/// Synthetic signals and the tests' own measures — independent of the package's pitch tracker.
enum Signals {
    static let rate = 44100

    /// Harmonics of f0 below 5 kHz under one Gaussian envelope peak; peak amplitude 0.5.
    static func vowel(f0: Double = 200, peak: Double = 1000, width: Double = 300, seconds: Double = 1) -> [Float] {
        let count = Int(seconds * Double(rate))
        var x = [Double](repeating: 0, count: count)
        for k in 1..<Int(5000 / f0) {
            let amp = exp(-pow((Double(k) * f0 - peak) / width, 2))
            let step = 2 * Double.pi * Double(k) * f0 / Double(rate)
            for i in 0..<count { x[i] += amp * sin(step * Double(i)) }
        }
        let top = x.map(abs).max() ?? 1
        return x.map { Float(0.5 * $0 / top) }
    }

    /// F0 of the middle 50 ms by normalized autocorrelation: the first local maximum within 0.9 of the best lag in
    /// 70–700 Hz, refined by a parabola.
    static func f0(_ x: [Float]) -> Double {
        let len = rate / 20, start = x.count / 2 - len / 2
        let lags = (rate / 700)...(rate / 70)
        var r = [Double](repeating: 0, count: lags.upperBound + 2)
        for lag in (lags.lowerBound - 1)...(lags.upperBound + 1) {
            var xy = 0.0, xx = 0.0, yy = 0.0
            for i in start..<(start + len) {
                let a = Double(x[i]), b = Double(x[i + lag])
                xy += a * b
                xx += a * a
                yy += b * b
            }
            r[lag] = xy / max(sqrt(xx * yy), 1e-12)
        }
        let best = lags.map { r[$0] }.max() ?? 0
        let first = lags.first { r[$0] >= 0.9 * best && r[$0] >= r[$0 - 1] && r[$0] >= r[$0 + 1] }
        guard let lag = first else { return 0 }
        let den = r[lag - 1] - 2 * r[lag] + r[lag + 1]
        let shift = den != 0 ? 0.5 * (r[lag - 1] - r[lag + 1]) / den : 0
        return Double(rate) / (Double(lag) + shift)
    }

    /// Strongest spectral peak in 300–3000 Hz on the middle quarter second (Hann window, Goertzel on a 5 Hz grid).
    static func strongest(_ x: [Float]) -> Double {
        let len = rate / 4, start = x.count / 2 - len / 2
        let seg = (0..<len).map { Double(x[start + $0]) * (0.5 - 0.5 * cos(2 * .pi * Double($0) / Double(len - 1))) }
        var best = (freq: 0.0, power: -1.0)
        for freq in stride(from: 300.0, through: 3000.0, by: 5.0) {
            let c = 2 * cos(2 * .pi * freq / Double(rate))
            var s1 = 0.0, s2 = 0.0
            for v in seg { (s1, s2) = (v + c * s1 - s2, s1) }
            let power = s1 * s1 + s2 * s2 - c * s1 * s2
            best = power > best.power ? (freq, power) : best
        }
        return best.freq
    }

    /// Seconds from the start to the last sample above 1% of the peak.
    static func activeSeconds(_ x: [Float]) -> Double {
        let top = x.map(abs).max() ?? 0
        let last = x.lastIndex { abs($0) > 0.01 * top } ?? -1
        return Double(last + 1) / Double(rate)
    }
}

/// Seeded generator for the relational tests (SplitMix64).
struct SplitMix {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return range.lowerBound + Double(z >> 11) / Double(UInt64(1) << 53) * (range.upperBound - range.lowerBound)
    }
}
