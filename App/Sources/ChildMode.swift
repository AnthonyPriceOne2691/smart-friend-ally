import AllyCore
import Foundation

/// The child mode on the phone (R, R2): the parent's key from the bundle (`allowed_signers`), his acceptance from the
/// bundle (`release-gate.json` and `.sig`, R2 — none until the goals are met), his exception and its signature from
/// the container (`Application Support/Ally/child-mode.json` and `.sig`, copied by `scripts/child_mode.sh`), the
/// build's surface — and who may talk on the child screen.
struct ChildMode {
    let build: ReleaseGate.Build
    private let signer: String?, folder: URL, release: SignedFile?

    init(personaSHA256: String, model: String) {
        let bundled = { (name: String) in Bundle.main.url(forResource: name, withExtension: nil) }
        let lines = bundled("allowed_signers").flatMap { try? String(contentsOf: $0, encoding: .utf8) }?
            .split(whereSeparator: \.isNewline) ?? []
        signer = lines.map(String.init).first { !$0.hasPrefix("#") && $0.contains("ecdsa-sha2-nistp256") }
        folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ally")
        build = .current(personaSHA256: personaSHA256, model: model, key: signer != nil)
        release = SignedFile.read(bundled("release-gate.json").flatMap { try? Data(contentsOf: $0) },
                                  armored: bundled("release-gate.json.sig")
                                      .flatMap { try? String(contentsOf: $0, encoding: .utf8) },
                                  signer: signer, for: .acceptance)
    }

    private var file: URL { folder.appendingPathComponent("child-mode.json") }
    private var signature: URL { folder.appendingPathComponent("child-mode.json.sig") }

    /// An exception lies in the container, valid or not.
    var present: Bool { FileManager.default.fileExists(atPath: file.path) }

    /// The console's line of the acceptance (R2): why it does not open the mode without the parent, or that it does.
    var acceptance: String { ReleaseGate.acceptanceLine(ReleaseGate.accept(release: release, build: build)) }

    func access(now: Date = Date()) -> ChildAccess {
        let bytes = try? Data(contentsOf: file), armored = try? String(contentsOf: signature, encoding: .utf8)
        return ReleaseGate.access(release: release,
                                  exception: SignedFile.read(bytes, armored: armored, signer: signer, for: .exception),
                                  build: build, now: now, zone: .current)
    }

    /// «Закрыть детский режим»: both files go; a new exception needs a new signature.
    func close() {
        for url in [file, signature] where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
