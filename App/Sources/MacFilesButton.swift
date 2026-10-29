import AllyCore
import Metal
import os
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

    /// The picked folder's files into `support` by the bundle's registries (`MacImport`, N4–N6): the console's line and
    /// whether every file came.
    nonisolated static func copy(_ folder: URL, bundle: URL, support: URL) -> (String, Bool) {
        let opened = folder.startAccessingSecurityScopedResource()
        defer { if opened { folder.stopAccessingSecurityScopedResource() } }
        let read = { (name: String) in try Data(contentsOf: bundle.appendingPathComponent(name)) }
        do {
            let list = try Data(contentsOf: folder.appendingPathComponent("manifest.json"))
            let items = try MacImport.plan(manifest: list, model: read("model.json"), hearing: read("hearing.json"),
                                           voice: read("voice.json"))
            return (try MacImport.copy(items, from: folder, into: support, sha256: FileDigest.sha256(of:)), true)
        } catch let refused as MacImport.Refusal {
            return (refused.line, false)
        } catch {
            return (MacImport.texts.nolist, false)
        }
    }
}

// sim-app: the copy behind the button, the GPU line and the trace's line in the system log — the loop's, kept here.
extension VoiceLoop {
    /// The picked folder's files into the container on a queue of their own (5.5 GB copied and hashed — not the
    /// cooperative pool, L143); with every file in place the launch's warm-up runs again (`warmUpAgain`).
    func importMacFiles(_ folder: URL) {
        guard !importingMacFiles else { return }
        importingMacFiles = true
        let bundle = Bundle.main.bundleURL
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        Task {
            let copy = await withCheckedContinuation { (done: CheckedContinuation<(String, Bool), Never>) in
                DispatchQueue(label: "ally.macfiles", qos: .userInitiated).async {
                    done.resume(returning: MacFilesButton.copy(folder, bundle: bundle, support: support))
                }
            }
            (macFilesLine, importingMacFiles) = (copy.0, false)
            if copy.1, !(await warmUpAgain()) { macFilesLine = copy.0 + MacImport.texts.later }
        }
    }

    /// The GPU the model's 99 layers are sent to — the console's line and the record's `metal`.
    static let metal = MTLCreateSystemDefaultDevice()?.name
    static var metalLine: String { metal.map { "модель: Metal — " + $0 } ?? "модель: CPU — нет Metal" }

    /// The trace's line into the system log (N8): a turn on the Mac is read with `log show --predicate
    /// 'subsystem == "com.anthonypriceone.ally" AND category == "turn"'`, the container unread; wordless like the file.
    static let systemLog = TraceLine { line in
        Logger(subsystem: "com.anthonypriceone.ally", category: "turn").log("\(line, privacy: .public)")
    }
}
