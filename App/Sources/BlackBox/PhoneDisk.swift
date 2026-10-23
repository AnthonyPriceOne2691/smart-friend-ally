import AllyCore
import Foundation

/// The black box's files on the phone (D3.2): `Library/Application Support/BlackBox`, out of the backup — the mark set
/// and read back on every start — with `NSFileProtectionComplete` on the folder, every session folder and every file:
/// the keys exist only on an unlocked phone. Each file is written whole (`.atomic`); nothing stays open between turns.
final class PhoneDisk: BlackBoxDisk, @unchecked Sendable {
    let root: URL, isPrivate: Bool
    private let manager = FileManager.default

    init() {
        root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BlackBox", isDirectory: true)
        isPrivate = Self.close(root)
    }

    /// What the console and the journal tell about the folder: its mark and class as read back.
    var note: String {
        let values = try? Self.fresh(root).resourceValues(forKeys: [.isExcludedFromBackupKey])
        let protection = (try? manager.attributesOfItem(atPath: root.path)[.protectionKey]) as? FileProtectionType
        let excluded = values?.isExcludedFromBackup == true, kind = protection?.rawValue ?? "?"
        return "вне бэкапа: \(excluded) · \(kind)"
    }

    func files() throws -> [String: Int] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        guard let walk = manager.enumerator(at: root, includingPropertiesForKeys: keys) else { return [:] }
        let base = root.resolvingSymlinksInPath().path  // /var and /private/var are one folder on the phone
        var sizes: [String: Int] = [:]
        for case let url as URL in walk {
            let values = try url.resourceValues(forKeys: Set(keys))
            guard values.isRegularFile == true else { continue }
            sizes[String(url.resolvingSymlinksInPath().path.dropFirst(base.count + 1))] = values.fileSize ?? 0
        }
        return sizes
    }

    func write(_ data: Data, to path: String) throws {
        let url = root.appendingPathComponent(path)
        try Self.folder(url.deletingLastPathComponent())
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    func remove(_ path: String) throws { try manager.removeItem(at: root.appendingPathComponent(path)) }

    /// Creates the folder (or keeps it) under the strongest class.
    private static func folder(_ url: URL) throws {
        let complete: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: complete)
        try FileManager.default.setAttributes(complete, ofItemAtPath: url.path)
    }

    /// Closes the root: the class and the backup mark set, then read back from a fresh URL — a cached value would say
    /// what was asked, not what is there. Either missing — the box does not write (closed refusal).
    private static func close(_ root: URL) -> Bool {
        do {
            try folder(root)
            var marked = root
            var mark = URLResourceValues()
            mark.isExcludedFromBackup = true
            try marked.setResourceValues(mark)
            let excluded = try fresh(root).resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
            let protection = try FileManager.default.attributesOfItem(atPath: root.path)[.protectionKey]
            return excluded == true && (protection as? FileProtectionType) == .complete
        } catch {
            return false
        }
    }

    private static func fresh(_ url: URL) -> URL { URL(fileURLWithPath: url.path, isDirectory: true) }
}
