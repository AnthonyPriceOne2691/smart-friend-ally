import AllyVoiceFX
import Foundation
import XCTest

final class VoiceFXTests: XCTestCase {
    func testPitchAndFormantShiftMoveF0AndEnvelope() throws {
        // Z27: vowel F0 200 Hz, envelope peak 1000 Hz; PSOLA +9 / +5 → 336 Hz ± 2%, 1 s ± 1%, harmonic 1335 Hz ± 5%
        let x = Signals.vowel()
        let y = try VoiceFX(pitch: 9, formant: 5).process(x, rate: Signals.rate)
        XCTAssertEqual(y.count, x.count)
        XCTAssertEqual(Signals.f0(y), 336.4, accuracy: 336.4 * 0.02)
        XCTAssertEqual(Signals.activeSeconds(y), 1.0, accuracy: 0.01)
        XCTAssertEqual(Signals.strongest(y), 1334.8, accuracy: 1334.8 * 0.05)
    }

    func testZeroShiftKeepsTheVowel() throws {
        // Z28: PSOLA 0 / 0 → F0, duration and the strongest harmonic in place ± 1%
        let x = Signals.vowel()
        let y = try VoiceFX(pitch: 0, formant: 0).process(x, rate: Signals.rate)
        XCTAssertEqual(Signals.f0(y), Signals.f0(x), accuracy: Signals.f0(x) * 0.01)
        XCTAssertEqual(Signals.activeSeconds(y), Signals.activeSeconds(x), accuracy: 0.01)
        XCTAssertEqual(Signals.strongest(y), Signals.strongest(x), accuracy: Signals.strongest(x) * 0.01)
    }

    func testF0RatioFollowsThePitchShiftAtAnyFormant() throws {
        // Z27 as a relation: F0 out / F0 in = 2^(pitch / 12) ± 2% for seeded shifts, the formant shift aside
        var rng = SplitMix(seed: 27)
        let x = Signals.vowel(f0: 180, seconds: 0.5)
        let before = Signals.f0(x)
        for _ in 0..<3 {
            let pitch = rng.next(in: -6...10), formant = rng.next(in: 0...6)
            let y = try VoiceFX(pitch: pitch, formant: formant).process(x, rate: Signals.rate)
            let ratio = pow(2, pitch / 12)
            XCTAssertEqual(Signals.f0(y) / before, ratio, accuracy: ratio * 0.02, "pitch \(pitch) formant \(formant)")
        }
    }

    func testTrackerFollowsAGlideWithAWeakFundamental() throws {
        // Z31: second harmonic twice the fundamental, F0 180 → 260 Hz over 1 s, then 0.3 s of silence
        let rate = Signals.rate, amps: [Double] = [0.5, 1.0, 0.6, 0.3, 0.2, 0.1]
        var signal = [Float](repeating: 0, count: rate + rate * 3 / 10), phase = 0.0
        for i in 0..<rate {
            phase += 2 * Double.pi * (180 + 80 * Double(i) / Double(rate)) / Double(rate)
            let sum = amps.enumerated().reduce(0.0) { $0 + $1.element * sin(Double($1.offset + 1) * phase) }
            signal[i] = Float(0.2 * sum)
        }
        let track = try PitchTrack(signal, rate: rate)
        let half = 1.5 / 70
        var worst = 0.0, voicedInSilence = 0, checked = 0
        for (i, f0) in track.f0.enumerated() {
            let t = track.start + Double(i) * PitchTrack.step
            if t - half >= 0, t + half <= 1 {
                worst = max(worst, abs(Double(f0) / (180 + 80 * t) - 1))
                checked += 1
            } else if t - half >= 1 {
                voicedInSilence += f0 > 0 ? 1 : 0
            }
        }
        XCTAssertGreaterThan(checked, 150)
        XCTAssertLessThanOrEqual(worst, 0.02)
        XCTAssertEqual(voicedInSilence, 0)
    }
}
