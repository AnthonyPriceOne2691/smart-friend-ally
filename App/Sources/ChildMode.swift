import AllyCore
import Foundation

/// The child mode on the phone (R): the parent's key from the bundle (`allowed_signers`), his exception and its
/// signature from the container (`Application Support/Ally/child-mode.json` and `.sig`, copied by
/// `scripts/child_mode.sh`), the build's surface — and who may talk on the child screen.
struct ChildMode {
    static let namespace = "ally-child-mode"
    let build: ReleaseGate.Build
    private let signer: String?, folder: URL

    init(personaSHA256: String, model: String) {
        let lines = Bundle.main.url(forResource: "allowed_signers", withExtension: nil)
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }?.split(whereSeparator: \.isNewline) ?? []
        signer = lines.map(String.init).first { !$0.hasPrefix("#") && $0.contains("ecdsa-sha2-nistp256") }
        folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ally")
        build = .current(personaSHA256: personaSHA256, model: model, key: signer != nil)
    }

    private var file: URL { folder.appendingPathComponent("child-mode.json") }
    private var signature: URL { folder.appendingPathComponent("child-mode.json.sig") }

    /// An exception lies in the container, valid or not.
    var present: Bool { FileManager.default.fileExists(atPath: file.path) }

    func access(now: Date = Date()) -> ChildAccess {
        let bytes = try? Data(contentsOf: file), armored = try? String(contentsOf: signature, encoding: .utf8)
        let signed = bytes.flatMap { bytes in
            armored.flatMap { armored in
                signer.map { SSHSignature.verify(bytes, armored: armored, signer: $0, namespace: Self.namespace) }
            }
        } ?? false
        return ReleaseGate.access(exception: bytes.map { SignedFile(bytes: $0, signed: signed) }, build: build,
                                  now: now, zone: .current)
    }

    /// «Закрыть детский режим»: both files go; a new exception needs a new signature.
    func close() {
        for url in [file, signature] where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
