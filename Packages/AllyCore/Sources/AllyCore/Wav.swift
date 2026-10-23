import Foundation

/// Her utterance as a WAV file: PCM16 mono at the recognizer's rate, the samples bit for bit — 44 header bytes and
/// little-endian samples; no codec, so the recognizers compared on step 3 hear what the live one heard.
enum Wav {
    static func file(_ samples: [Int16], rate: Int) -> Data {
        let bytes = UInt32(samples.count * 2)
        var data = Data(capacity: 44 + samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(le: 36 + bytes)
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        data.append(le: UInt32(16))
        data.append(le: UInt16(1))
        data.append(le: UInt16(1))
        data.append(le: UInt32(rate))
        data.append(le: UInt32(rate * 2))
        data.append(le: UInt16(2))
        data.append(le: UInt16(16))
        data.append(contentsOf: Array("data".utf8))
        data.append(le: bytes)
        samples.forEach { data.append(le: UInt16(bitPattern: $0)) }
        return data
    }
}

/// FNV-1a 64 of a file as `fnv1a:` and 16 hex digits — the router's data hash format: a bare hex is a false find of
/// the secrets gate (L38). The Mac checks a pulled copy against it.
enum FNV1a {
    static func tag(_ data: Data) -> String {
        let hash = data.reduce(UInt64(0xcbf2_9ce4_8422_2325)) { ($0 ^ UInt64($1)) &* 0x100_0000_01b3 }
        let hex = String(hash, radix: 16)
        return "fnv1a:" + String(repeating: "0", count: 16 - hex.count) + hex
    }
}

extension Data {
    mutating func append<Value: FixedWidthInteger>(le value: Value) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
