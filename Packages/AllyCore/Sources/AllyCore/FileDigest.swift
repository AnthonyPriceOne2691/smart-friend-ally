#if canImport(CryptoKit)
import CryptoKit
import Foundation

/// sha256 of a file read in 8 MiB pieces: the copy from the Mac checks each copied file this way (sim-app, N6); the
/// weights are 4.6 GB, so the file is never read whole.
public enum FileDigest {
    public static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let piece = try handle.read(upToCount: 8 << 20), !piece.isEmpty {
            hasher.update(data: piece)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
#endif
