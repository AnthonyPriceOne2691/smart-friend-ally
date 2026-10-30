import Foundation

/// Elly on the Mac (sim-app): the iPhone app runs there from Xcode, and macOS lets no other process into its container,
/// so the files of the model, the hearing and the voice come in through the app itself — the parent picks the folder
/// `scripts/mac_files.py` laid out (`Models/`, `Voice/`, `manifest.json`). The plan admits only the paths of the
/// bundle's registries with their sizes — the voice's sha256 is `voice.json`'s, the weights' and Silero's the list's,
/// which the script checked against the pin — and anything else refuses the whole folder; the copy puts a file in place
/// only after its copy matched.
public enum MacImport {
    /// A file to copy: its path in the folder and under `Application Support`, its size and sha256.
    public struct Item: Equatable, Sendable {
        public let path: String, bytes: Int64, sha256: String
    }

    /// Why nothing (more) was copied — the console's line.
    public struct Refusal: Error, Equatable, Sendable {
        public let line: String
    }

    /// The lines, from `mac_import.json`: texts live in resources, not in code.
    public static let texts: Texts = {
        guard let url = Bundle.module.url(forResource: "mac_import", withExtension: "json"),
              let bytes = try? Data(contentsOf: url), let texts = try? JSONDecoder().decode(Texts.self, from: bytes)
        else { fatalError("AllyCore: mac_import.json is unreadable") }
        return texts
    }()

    /// The button is the iPhone app's on a Mac only — never on the phone — and only while Elly sleeps (N7).
    public static func offered(onMac: Bool, asleep: Bool) -> Bool { onMac && asleep }

    /// The copy's plan from the folder's `manifest.json` and the bundle's registries (N4, N5).
    public static func plan(manifest: Data, model: Data, hearing: Data, voice: Data) throws -> [Item] {
        guard let listed = try? JSONDecoder().decode(Manifest.self, from: manifest).files else {
            throw Refusal(line: texts.unreadable)
        }
        let allowed = try registered(model: model, hearing: hearing, voice: voice)
        return try listed.map { entry in
            guard let known = allowed[entry.path] else {
                throw Refusal(line: fill(texts.stranger, ["path": entry.path]))
            }
            guard entry.bytes == known.bytes else {
                throw Refusal(line: fill(texts.size, ["name": known.name, "found": "\(entry.bytes)",
                                                      "bytes": "\(known.bytes)"]))
            }
            let sha256 = known.sha256 ?? entry.sha256
            guard entry.sha256 == sha256 else { throw Refusal(line: fill(texts.hash, ["name": known.name])) }
            return Item(path: entry.path, bytes: entry.bytes, sha256: sha256)
        }
    }

    /// Copies the plan from `folder` into `support`: each file beside its place under a temporary name, its size and
    /// `sha256` checked, then put in place. The first that does not match stops the copy — its old file stays, the
    /// temporary one goes (N6); nothing outside the plan is touched. The console's line of what came.
    public static func copy(_ items: [Item], from folder: URL, into support: URL,
                            sha256: (URL) throws -> String) throws -> String {
        let files = FileManager.default
        for item in items {
            let target = support.appendingPathComponent(item.path), place = target.deletingLastPathComponent()
            let temporary = place.appendingPathComponent("." + target.lastPathComponent + ".copy")
            defer { try? files.removeItem(at: temporary) }
            do {
                try files.createDirectory(at: place, withIntermediateDirectories: true)
                try? files.removeItem(at: temporary)
                try files.copyItem(at: folder.appendingPathComponent(item.path), to: temporary)
            } catch {
                throw Refusal(line: fill(texts.copy, ["path": item.path]))
            }
            guard size(of: temporary) == item.bytes, (try? sha256(temporary)) == item.sha256 else {
                throw Refusal(line: fill(texts.after, ["path": item.path]))
            }
            do {
                if files.fileExists(atPath: target.path) { try files.removeItem(at: target) }
                try files.moveItem(at: temporary, to: target)
            } catch {
                throw Refusal(line: fill(texts.place, ["path": item.path]))
            }
        }
        let total = Double(items.reduce(Int64(0)) { $0 + $1.bytes }) / 1e9
        let gigabytes = String(format: "%.2f", total).replacingOccurrences(of: ".", with: ",")
        return fill(texts.done, ["count": "\(items.count)", "gb": gigabytes])
    }

    /// What the registries let in: the folder's path → the name the registry writes, the size, the sha256 it has.
    private static func registered(model: Data, hearing: Data, voice: Data) throws -> [String: Known] {
        guard let weights = try? ModelRegistry.decode(model), let ears = try? Hearing.decode(hearing),
              let voice = try? VoiceSettings.decode(voice) else {
            throw Refusal(line: texts.registries)
        }
        var known = ["Models/" + weights.model.file: Known(weights.model.file, weights.model.bytes)]
        if let vad = ears.vad { known["Models/" + vad.file] = Known(vad.file, Int64(vad.bytes)) }
        for file in ears.asr?.gigaam ?? [] { known["Models/" + file.file] = Known(file.file, file.bytes) }
        for file in voice.files { known[voice.folder + "/" + file.path] = Known(file.path, file.bytes, file.sha256) }
        return known
    }

    private static func fill(_ text: String, _ values: [String: String]) -> String {
        values.reduce(text) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
    }

    private static func size(of url: URL) -> Int64? {
        ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber)?.int64Value
    }

    /// The lines of the button and the copy (`mac_import.json`).
    public struct Texts: Decodable, Sendable {
        public let unreadable, registries, stranger, size, hash, copy, after, place, done, nolist, later: String
    }

    private struct Manifest: Decodable {
        let files: [Listed]
    }

    private struct Listed: Decodable {
        let path: String, bytes: Int64, sha256: String
    }

    private struct Known {
        let name: String, bytes: Int64, sha256: String?

        init(_ name: String, _ bytes: Int64, _ sha256: String? = nil) {
            (self.name, self.bytes, self.sha256) = (name, bytes, sha256)
        }
    }
}
