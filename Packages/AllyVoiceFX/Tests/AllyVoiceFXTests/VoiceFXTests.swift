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
        let signal = Signals.glide() + [Float](repeating: 0, count: Signals.rate * 3 / 10)
        let track = try PitchTrack(signal, rate: Signals.rate)
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

    func testStretchLengthensTheSoundAndKeepsThePitchAndTheTimbre() throws {
        // S1: a 1 s vowel at 1.12 → 1.12 s ± 1%, F0 ± 2%, the strongest harmonic ± 5%
        let x = Signals.vowel()
        let y = try VoiceFX(pitch: 0, formant: 0, stretch: 1.12).process(x, rate: Signals.rate)
        XCTAssertEqual(y.count, Int((Double(x.count) * 1.12).rounded()))
        XCTAssertEqual(Signals.activeSeconds(y), 1.12, accuracy: 0.0112)
        XCTAssertEqual(Signals.f0(y), Signals.f0(x), accuracy: Signals.f0(x) * 0.02)
        XCTAssertEqual(Signals.strongest(y), Signals.strongest(x), accuracy: Signals.strongest(x) * 0.05)
    }

    func testStretchWorksOverTheShifts() throws {
        // S1 as a relation: the length follows the stretch and F0 the pitch for seeded settings, the formants aside
        var rng = SplitMix(seed: 12)
        let x = Signals.vowel(f0: 180, seconds: 0.5)
        let before = Signals.f0(x)
        for _ in 0..<3 {
            let pitch = rng.next(in: 0...10), formant = rng.next(in: 0...6), stretch = rng.next(in: 0.9...1.3)
            let y = try VoiceFX(pitch: pitch, formant: formant, stretch: stretch).process(x, rate: Signals.rate)
            XCTAssertEqual(y.count, Int((Double(x.count) * stretch).rounded()), "stretch \(stretch)")
            XCTAssertEqual(Signals.activeSeconds(y), 0.5 * stretch, accuracy: 0.5 * stretch * 0.02, "\(stretch)")
            let ratio = pow(2, pitch / 12)
            XCTAssertEqual(Signals.f0(y) / before, ratio, accuracy: ratio * 0.02, "pitch \(pitch) stretch \(stretch)")
        }
    }

    func testRangeWidensTheIntonationAroundTheMedian() throws {
        // S2: a glide 180 → 260 Hz at 1.3: the span in semitones × 1.3 ± 15%, the median in place ± 3%
        let x = Signals.glide()
        let before = try Contour(x), after = try Contour(VoiceFX(pitch: 0, formant: 0, range: 1.3)
            .process(x, rate: Signals.rate))
        XCTAssertEqual(after.span / before.span, 1.3, accuracy: 1.3 * 0.15)
        XCTAssertEqual(after.median, before.median, accuracy: before.median * 0.03)
    }

    func testPlainStretchAndRangeAreTheChainWithoutThem() throws {
        // S3: 1 and 1 change nothing, sample for sample
        let x = Signals.glide(), plain = VoiceFX(pitch: 9, formant: 4, eq: VoiceEQ())
        XCTAssertEqual(try plain.process(x, rate: Signals.rate),
                       try VoiceFX(pitch: 9, formant: 4, stretch: 1, range: 1).process(x, rate: Signals.rate))
    }

    func testAStretchOrARangeNotAboveZeroIsAnError() {
        // S4: the line refuses them; the chain does not crash on them either
        for fx in [VoiceFX(pitch: 0, formant: 0, stretch: 0), VoiceFX(pitch: 0, formant: 0, range: -1)] {
            XCTAssertThrowsError(try fx.process([0.5], rate: Signals.rate)) {
                XCTAssertEqual($0 as? VoiceFXError, .badShape)
            }
        }
    }
}

/// Voiced F0 of a sound by the package's tracker: its median and the p10–p90 span in semitones.
private struct Contour {
    let median: Double, span: Double

    init(_ samples: [Float]) throws {
        let voiced = try PitchTrack(samples, rate: Signals.rate).f0.filter { $0 > 0 }.map(Double.init).sorted()
        median = voiced[voiced.count / 2]
        span = 12 * log2(voiced[voiced.count * 9 / 10] / voiced[voiced.count / 10])
    }
}
