@testable import ShellCore
import XCTest

final class MusicBoxTests: XCTestCase {
    /// The loop, rendered once for all the tests.
    private static let loop = MusicBox.render()

    func testTheLoopIsThePagesWaveByteForByteOnEveryPlatform() {
        // Y10 1 924 364 stereo frames; sha256 of the 16-bit samples = the data of the WAV the parent chose
        XCTAssertEqual(MusicBox.frames, 1_924_364)
        XCTAssertEqual(Self.loop.count, 2 * 1_924_364)
        let bytes = Self.loop.withUnsafeBytes { Array($0) }  // little-endian on the Mac, the phone and the CI
        let wave = "d446a12617992cb845f78756a5466f4c1f9b527dabc5d5128781add06a354350"  // pragma: allowlist secret
        XCTAssertEqual(sha256(bytes), wave)
    }

    func testTheSeamIsNoJumpAndThePeakIsSeventyPercent() {
        // Y10 the step from the last frame to the first is within the loop's own largest step; the peak is 0,70
        var (inside, peak) = ([0, 0], 0)
        Self.loop.withUnsafeBufferPointer { loop in
            var index = 0
            while index < loop.count {
                if index >= 2 {
                    inside[index % 2] = max(inside[index % 2], abs(Int(loop[index]) - Int(loop[index - 2])))
                }
                peak = max(peak, abs(Int(loop[index])))
                index += 1
            }
        }
        for channel in 0..<2 {
            let seam = abs(Int(Self.loop[channel]) - Int(Self.loop[Self.loop.count - 2 + channel]))
            XCTAssertLessThanOrEqual(seam, inside[channel], "channel \(channel)")
            XCTAssertGreaterThan(seam, 0, "channel \(channel): a seam of silence would hide a gap")
        }
        XCTAssertEqual(peak, Int(0.70 * 32767), "the generator scales the loudest sample to 0,70")
    }

    func testTheNotesAreTheScoresAndTheSeriesAreExact() {
        // Y10 the score: 16 bars, the tune's beats fill each bar; the series agree with the platform to 1e-15
        XCTAssertEqual(MusicScore.midi("Bb5"), 82)
        XCTAssertEqual(MusicScore.midi("A2"), 45)
        let notes = MusicScore.notes()
        XCTAssertEqual(notes.count, 16 * 8 + 18 + 53, "arpeggios, roots, the tune")
        XCTAssertEqual(MusicBox.pow2(-2.5), 0.17677669529663687, accuracy: 1e-15)
        XCTAssertEqual(MusicBox.seriesExp(-0.5), Foundation.exp(-0.5), accuracy: 1e-15)
        let (sine, cosine) = MusicBox.sincos(2.5)
        XCTAssertEqual(sine, Foundation.sin(2.5), accuracy: 1e-15)
        XCTAssertEqual(cosine, Foundation.cos(2.5), accuracy: 1e-15)
    }
}

/// SHA-256 (FIPS 180-4) for the test: Foundation on Linux has none, and the bytes must be judged there too. Loops are
/// `while` over raw pointers — the test build is unoptimized.
private func sha256(_ bytes: [UInt8]) -> String {
    let rounds: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98,
        0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
        0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8,
        0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
        0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
        0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
        0xc67178f2
    ]
    var hash: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
                          0x5be0cd19]
    var message = bytes + [0x80] + [UInt8](repeating: 0, count: (119 - bytes.count % 64) % 64)
    message += (0..<8).map { UInt8(truncatingIfNeeded: (UInt64(bytes.count) * 8) >> (56 - 8 * $0)) }
    var words = [UInt32](repeating: 0, count: 64)
    message.withUnsafeBufferPointer { buffer in
        words.withUnsafeMutableBufferPointer { schedule in
            guard let m = buffer.baseAddress, let w = schedule.baseAddress else { return }
            var block = 0
            while block < buffer.count {
                var i = 0
                while i < 16 {
                    let at = block + 4 * i
                    w[i] = UInt32(m[at]) << 24 | UInt32(m[at + 1]) << 16 | UInt32(m[at + 2]) << 8 | UInt32(m[at + 3])
                    i += 1
                }
                while i < 64 {
                    let (x, y) = (w[i - 15], w[i - 2])
                    let low = (x >> 7 | x << 25) ^ (x >> 18 | x << 14) ^ x >> 3
                    let high = (y >> 17 | y << 15) ^ (y >> 19 | y << 13) ^ y >> 10
                    w[i] = w[i - 16] &+ low &+ w[i - 7] &+ high
                    i += 1
                }
                var (a, b, c, d, e, f, g, h) = (hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7])
                i = 0
                while i < 64 {
                    let sigma1 = (e >> 6 | e << 26) ^ (e >> 11 | e << 21) ^ (e >> 25 | e << 7)
                    let first = h &+ sigma1 &+ (e & f ^ ~e & g) &+ rounds[i] &+ w[i]
                    let sigma0 = (a >> 2 | a << 30) ^ (a >> 13 | a << 19) ^ (a >> 22 | a << 10)
                    let second = sigma0 &+ (a & b ^ a & c ^ b & c)
                    (h, g, f, e, d, c, b, a) = (g, f, e, d &+ first, c, b, a, first &+ second)
                    i += 1
                }
                hash = [hash[0] &+ a, hash[1] &+ b, hash[2] &+ c, hash[3] &+ d, hash[4] &+ e, hash[5] &+ f,
                        hash[6] &+ g, hash[7] &+ h]
                block += 64
            }
        }
    }
    return hash.map { String(format: "%08x", $0) }.joined()
}
