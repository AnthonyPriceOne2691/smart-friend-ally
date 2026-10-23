import AllyVoiceFX
import Foundation
import XCTest

final class EQTests: XCTestCase {
    private let light = [EQBand(.lowShelf, frequency: 250, gainDB: -3, q: 0.7),
                         EQBand(.peak, frequency: 4000, gainDB: 2.5, q: 0.9)]
    private let ref = [EQBand(.peak, frequency: 2500, gainDB: 3.5, q: 0.8),
                       EQBand(.peak, frequency: 4000, gainDB: 1.5, q: 0.9)]
    private let freqs: [Double] = [100, 1000, 2500, 4000, 8000]

    /// Steady-state gain of the cascade on a sine, dB: RMS of the last half second against the input's.
    private func gain(_ bands: [EQBand], at freq: Double) throws -> Double {
        let rate = 44100
        let x = (0..<rate).map { Float(0.5 * sin(2 * Double.pi * freq * Double($0) / Double(rate))) }
        let y = try VoiceFX.equalize(x, rate: rate, bands: bands)
        func rms(_ v: [Float]) -> Double {
            sqrt(v[(rate / 2)...].reduce(0) { $0 + Double($1 * $1) } / Double(rate / 2))
        }
        return 20 * log10(rms(y) / rms(x))
    }

    func testLightAndRefGainsMatchTheStand() throws {
        // Z29: scipy sosfreqz of the stand's cascade at 44.1 kHz, ± 0.1 dB
        let expected = [(light, [-2.91, 0.18, 1.36, 2.50, 0.73]), (ref, [0.01, 1.02, 4.32, 3.61, 0.89])]
        for (bands, gains) in expected {
            for (freq, want) in zip(freqs, gains) {
                XCTAssertEqual(try gain(bands, at: freq), want, accuracy: 0.1, "\(freq) Hz")
            }
        }
    }

    func testPeakThenItsMirrorGivesTheInputBack() throws {
        // Z29 as a relation: an RBJ peak of +g dB followed by the same peak of −g dB is the identity
        var rng = SplitMix(seed: 29)
        let x = (0..<4410).map { _ in Float(rng.next(in: -0.5...0.5)) }
        for _ in 0..<3 {
            let freq = rng.next(in: 200...8000), gain = rng.next(in: 1...9), q = rng.next(in: 0.5...2)
            let bands = [EQBand(.peak, frequency: freq, gainDB: gain, q: q),
                         EQBand(.peak, frequency: freq, gainDB: -gain, q: q)]
            let y = try VoiceFX.equalize(x, rate: 44100, bands: bands)
            XCTAssertLessThan(zip(x, y).map { abs($0 - $1) }.max() ?? 1, 1e-4, "\(freq) Hz \(gain) dB")
        }
    }
}
