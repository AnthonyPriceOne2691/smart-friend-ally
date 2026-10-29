import ShellCore
import XCTest

final class MusicBoxTests: XCTestCase {
    /// The loop, rendered once for all the tests.
    private static let loop = MusicBox.render()

    func testTheLoopIsThePagesWaveByteForByteOnEveryPlatform() {
        // Y10 1 924 364 stereo frames; sha256 of the 16-bit samples = the data of the WAV the parent chose
        XCTAssertEqual([MusicBox.frames, Self.loop.count], [1_924_364, 2 * 1_924_364])
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
}

/// SHA-256 (FIPS 180-4) for the test: Foundation on Linux has none, and the bytes must be judged there too. Loops are
/// `while` over raw pointers — the test build is unoptimized.
private func sha256(_ bytes: [UInt8]) -> String {
    let primes = (2...311).filter { number in (2..<number).allSatisfy { number % $0 != 0 } }
    func fraction(_ value: Double) -> UInt32 { UInt32((value - value.rounded(.down)) * 4_294_967_296) }
    let rounds = primes.prefix(64).map { fraction(cbrt(Double($0))) }  // FIPS 180-4 §4.2.2: cube roots of primes
    var hash = primes.prefix(8).map { fraction(Double($0).squareRoot()) }  // §5.3.3: square roots
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
