#if canImport(CryptoKit)
import CryptoKit
import Foundation

/// The parent's signature over a file (R): `ssh-keygen -Y sign` of OpenSSH (PROTOCOL.sshsig) with an ECDSA P-256
/// key — the kind the Secure Enclave of Secretive holds. True only for exactly these bytes, this key and this
/// namespace; anything else, garbage included, is false and never a crash.
public enum SSHSignature {
    static let keyType = "ecdsa-sha2-nistp256"

    /// - Parameters:
    ///   - signer: the parent's line of `allowed_signers` (or a public key line): its `ecdsa-sha2-nistp256` key
    ///     counts.
    ///   - namespace: what the signature is for (`ally-child-mode`): one made for another purpose does not open this.
    public static func verify(_ message: Data, armored: String, signer: String, namespace: String) -> Bool {
        guard let key = publicKey(in: signer), let blob = unarmor(armored) else { return false }
        var wire = Wire(blob)
        guard wire.take(6) == Array("SSHSIG".utf8), wire.number() == 1, let publicBlob = wire.string(),
              publicBlob == key,
              let space = wire.string(), space == Array(namespace.utf8), let reserved = wire.string(),
              let hash = wire.string(), let signature = wire.string(), let digest = digest(message, hash: hash),
              let point = point(in: publicBlob), let ecdsa = ecdsa(signature),
              let publicKey = try? P256.Signing.PublicKey(x963Representation: point) else { return false }
        let signed = Array("SSHSIG".utf8) + [space, reserved, hash, digest].flatMap(Wire.encode)
        return publicKey.isValidSignature(ecdsa, for: Data(signed))
    }

    /// The key blob after `ecdsa-sha2-nistp256` in the line.
    static func publicKey(in signer: String) -> [UInt8]? {
        let words = signer.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let at = words.firstIndex(of: keyType), at + 1 < words.count,
              let blob = Data(base64Encoded: words[at + 1]) else { return nil }
        return Array(blob)
    }

    /// The signature's bytes between the armor lines.
    static func unarmor(_ armored: String) -> [UInt8]? {
        let body = armored.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-----") }.joined()
        return Data(base64Encoded: body).map(Array.init)
    }

    /// The message's hash as `ssh-keygen` takes it: SHA-512 by default, SHA-256 allowed.
    static func digest(_ message: Data, hash: [UInt8]) -> [UInt8]? {
        switch String(bytes: hash, encoding: .utf8) {
        case "sha512": Array(SHA512.hash(data: message))
        case "sha256": Array(SHA256.hash(data: message))
        default: nil
        }
    }

    /// The curve point of an `ecdsa-sha2-nistp256` key blob: 65 bytes, uncompressed.
    static func point(in blob: [UInt8]) -> Data? {
        var wire = Wire(blob)
        guard wire.string() == Array(keyType.utf8), wire.string() == Array("nistp256".utf8), let point = wire.string(),
              point.count == 65, wire.done else { return nil }
        return Data(point)
    }

    /// The signature blob as CryptoKit takes it: r and s, each as 32 bytes.
    static func ecdsa(_ blob: [UInt8]) -> P256.Signing.ECDSASignature? {
        var outer = Wire(blob)
        guard outer.string() == Array(keyType.utf8), let inner = outer.string(), outer.done else { return nil }
        var numbers = Wire(inner)
        guard let r = numbers.string().flatMap(fixed), let s = numbers.string().flatMap(fixed), numbers.done else {
            return nil
        }
        return try? P256.Signing.ECDSASignature(rawRepresentation: Data(r + s))
    }

    /// An SSH `mpint` as exactly 32 bytes: its leading zeros dropped, then padded on the left.
    static func fixed(_ mpint: [UInt8]) -> [UInt8]? {
        let digits = Array(mpint.drop { $0 == 0 })
        return digits.count <= 32 ? [UInt8](repeating: 0, count: 32 - digits.count) + digits : nil
    }
}

/// The SSH wire format: a big-endian `uint32` length before each string.
struct Wire {
    private let bytes: [UInt8]
    private var at = 0

    init(_ bytes: [UInt8]) { self.bytes = bytes }

    var done: Bool { at == bytes.count }

    mutating func take(_ count: Int) -> [UInt8]? {
        guard count >= 0, count <= bytes.count - at else { return nil }
        defer { at += count }
        return Array(bytes[at..<at + count])
    }

    mutating func number() -> UInt32? {
        take(4).map { $0.reduce(UInt32(0)) { $0 << 8 | UInt32($1) } }
    }

    mutating func string() -> [UInt8]? {
        guard let count = number(), count <= UInt32(Int32.max) else { return nil }
        return take(Int(count))
    }

    static func encode(_ field: [UInt8]) -> [UInt8] {
        let count = UInt32(field.count)
        return [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: count >> $0) } + field
    }
}
#endif
