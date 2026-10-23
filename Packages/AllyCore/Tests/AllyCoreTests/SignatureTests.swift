import AllyCore
import XCTest

#if canImport(CryptoKit)
/// Fixtures made once with OpenSSH 10.3 — two throwaway ECDSA P-256 keys (`ssh-keygen -t ecdsa -b 256`) and
/// `ssh-keygen -Y sign`; the private keys were never kept. The message is an exception on one line, as the script
/// writes it.
final class SignatureTests: XCTestCase {
    private let message = Data("""
        {"from":"2026-10-23T09:00:00+03:00","note":"тест","surface":{"contract":"fnv1a:test-contract",\
        "model":"test.gguf:100","persona":"sha256:test-persona","router":"fnv1a:test-router"},\
        "until":"2026-10-29T21:00:00+03:00"}
        """.utf8)
    private let signer = """
        ally-test namespaces="ally-child-mode" ecdsa-sha2-nistp256 \
        AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC+PEclwExRPonmbZCxznUxYY23M\
        TuFKygEe/yhyeUN779ydZZAtNDI0wQ/vWkA0nUcwzTHvXNfRkPhlMhVRVAk=
        """
    private let signed = """
        -----BEGIN SSH SIGNATURE-----
        U1NIU0lHAAAAAQAAAGgAAAATZWNkc2Etc2hhMi1uaXN0cDI1NgAAAAhuaXN0cDI1NgAAAE
        EEL48RyXATFE+ieZtkLHOdTFhjbcxO4UrKAR7/KHJ5Q3vv3J1lkC00MjTBD+9aQDSdRzDN
        Me9c19GQ+GUyFVFUCQAAAA9hbGx5LWNoaWxkLW1vZGUAAAAAAAAABnNoYTUxMgAAAGQAAA
        ATZWNkc2Etc2hhMi1uaXN0cDI1NgAAAEkAAAAhAO7/P8GxvXXRMSefMtoRyx0poFq7Uh+6
        QvfboE+KMoq9AAAAIFabFWWvAePGzYpUoY6rfBqrSZUdJe13fMlggNgCaJzu
        -----END SSH SIGNATURE-----
        """
    private let forIrreversible = """
        -----BEGIN SSH SIGNATURE-----
        U1NIU0lHAAAAAQAAAGgAAAATZWNkc2Etc2hhMi1uaXN0cDI1NgAAAAhuaXN0cDI1NgAAAE
        EEL48RyXATFE+ieZtkLHOdTFhjbcxO4UrKAR7/KHJ5Q3vv3J1lkC00MjTBD+9aQDSdRzDN
        Me9c19GQ+GUyFVFUCQAAAAxpcnJldmVyc2libGUAAAAAAAAABnNoYTUxMgAAAGMAAAATZW
        Nkc2Etc2hhMi1uaXN0cDI1NgAAAEgAAAAgL5loAzAqEhq6GE3kwVhcfGURHv8DS94Qd6aH
        tVWQFSoAAAAgIJC5X+aYWvJ4jvt+HqQ6jBzwTBuOioFckobcY6teHGc=
        -----END SSH SIGNATURE-----
        """
    private let byAnotherKey = """
        -----BEGIN SSH SIGNATURE-----
        U1NIU0lHAAAAAQAAAGgAAAATZWNkc2Etc2hhMi1uaXN0cDI1NgAAAAhuaXN0cDI1NgAAAE
        EEURGq3pe7++yhJC5pSQVi1u+5OtArojB7CV3D4nQ/X21fibpuymhmIlF0D6XV+96hT0Jb
        yh48HLhpvytIERppngAAAA9hbGx5LWNoaWxkLW1vZGUAAAAAAAAABnNoYTUxMgAAAGQAAA
        ATZWNkc2Etc2hhMi1uaXN0cDI1NgAAAEkAAAAgWmEuDa2LaSEzWH3FbVQIuzYpqFI8MC5l
        aGzNHLGoDvEAAAAhALyI6yt/UhD4xGTjCClnqeiza4eNgUp5bYylmPLMks5u
        -----END SSH SIGNATURE-----
        """

    func testOnlyTheseBytesThisKeyAndThisNamespaceOpen() {  // G7
        XCTAssertTrue(SSHSignature.verify(message, armored: signed, signer: signer, namespace: "ally-child-mode"))
        var changed = message
        changed[changed.startIndex + 10] ^= 1
        XCTAssertFalse(SSHSignature.verify(changed, armored: signed, signer: signer, namespace: "ally-child-mode"))
        XCTAssertFalse(SSHSignature.verify(message, armored: forIrreversible, signer: signer,
                                           namespace: "ally-child-mode"))
        XCTAssertFalse(SSHSignature.verify(message, armored: signed, signer: signer, namespace: "irreversible"))
        XCTAssertFalse(SSHSignature.verify(message, armored: byAnotherKey, signer: signer,
                                           namespace: "ally-child-mode"))
        for garbage in ["", "-----BEGIN SSH SIGNATURE-----\nмусор\n-----END SSH SIGNATURE-----",
                        String(signed.dropLast(40)), String(repeating: "U1NIU0lH", count: 20)] {
            XCTAssertFalse(SSHSignature.verify(message, armored: garbage, signer: signer, namespace: "ally-child-mode"))
        }
        XCTAssertFalse(SSHSignature.verify(message, armored: signed, signer: "нет ключа", namespace: "ally-child-mode"))
    }
}
#else
final class SignatureTests: XCTestCase {
    func testTheSignatureIsCheckedOnMac() throws {  // G7
        throw XCTSkip("CryptoKit нет на Linux — подпись родителя (G7) проверяется на Mac")
    }
}
#endif
