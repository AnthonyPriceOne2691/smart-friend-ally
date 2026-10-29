import AllyCore
import ShellUI
import SwiftUI
import UniformTypeIdentifiers

/// «Файлы с Mac…» (sim-app): the iPhone app on a Mac takes the model, hearing and voice files from the folder the
/// parent picks — `scripts/mac_files.py` lays it out — because macOS lets nothing else write into its container. Never
/// on the phone; on the Mac only while Elly sleeps (N7). The line under it says what came or why not.
struct MacFilesButton: View {
    @ObservedObject var loop: VoiceLoop
    @State private var picking = false

    var body: some View {
        if MacImport.offered(onMac: ProcessInfo.processInfo.isiOSAppOnMac, asleep: loop.talk.phase == .asleep) {
            VStack(alignment: .leading, spacing: 4) {
                Button("Файлы с Mac…") { picking = true }.buttonStyle(GlassCapsule())
                    .disabled(loop.importingMacFiles).accessibilityIdentifier("console.macFiles")
                if let line = loop.macFilesLine { Text(line).font(.caption) }
            }
            .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { picked in
                if case .success(let folder) = picked { loop.importMacFiles(folder) }
            }
        }
    }

    /// The picked folder's files into `support` by the bundle's registries (`MacImport`, N4–N6): the console's line.
    nonisolated static func copy(_ folder: URL, bundle: URL, support: URL) -> String {
        let opened = folder.startAccessingSecurityScopedResource()
        defer { if opened { folder.stopAccessingSecurityScopedResource() } }
        let read = { (name: String) in try Data(contentsOf: bundle.appendingPathComponent(name)) }
        do {
            let list = try Data(contentsOf: folder.appendingPathComponent("manifest.json"))
            let items = try MacImport.plan(manifest: list, model: read("model.json"), hearing: read("hearing.json"),
                                           voice: read("voice.json"))
            return try MacImport.copy(items, from: folder, into: support, sha256: FileDigest.sha256(of:))
        } catch let refused as MacImport.Refusal {
            return refused.line
        } catch {
            return MacImport.texts.nolist
        }
    }
}
