import AllySQLite
import Foundation

/// The talk waiting for its parse in the memory's own base (`memory-app`, M34, вопрос 5): her turns with Elly's
/// answers, until the parse succeeds or fails twice — then the transcript goes, WAL included.
extension MemoryStore {
    /// One turn of a talk into the queue; the first turn's moment is the talk's start.
    public func enqueue(session: String, started: Date, turn: Int, her: String, elly: String) throws {
        try db.transaction {
            try db.run("INSERT OR IGNORE INTO queue (session, started) VALUES (?, ?)",
                       [.text(session), .real(started.timeIntervalSince1970)])
            try db.run("INSERT OR REPLACE INTO pending (session, turn, her, elly) VALUES (?, ?, ?, ?)",
                       [.text(session), .int(Int64(turn)), .text(her), .text(elly)])
        }
    }

    /// How many talks wait, but the one still running.
    public func waiting(except running: String? = nil) throws -> Int {
        Int(try db.rows("SELECT count(*) FROM queue WHERE session IS NOT ?", [running.map { .text($0) } ?? .null])
            .first?.first?.int ?? 0)
    }

    /// Parses the waiting talks oldest first, but the one still running: a talk begun before the last erase goes
    /// unparsed; parsed or not parsed the second time — its transcript goes; a cancelled parse leaves it as it was.
    @discardableResult
    public func drain(model: MemoryModel, except running: String? = nil) async throws -> [Extraction] {
        let epoch = try wipeEpoch()?.timeIntervalSince1970 ?? -Double.infinity
        var parsed: [Extraction] = []
        let talks = try db.rows("SELECT session, started, attempts FROM queue WHERE session IS NOT ? "
                                + "ORDER BY started, session", [running.map { .text($0) } ?? .null])
        for talk in talks {
            guard let session = talk[0].text, let started = talk[1].real else { continue }
            guard started >= epoch else {
                try release(session)
                continue
            }
            let turns = try db.rows("SELECT turn, her, elly FROM pending WHERE session = ? ORDER BY turn",
                                    [.text(session)]).map {
                MemoryTurn(number: Int($0[0].int ?? 0), her: $0[1].text ?? "", elly: $0[2].text)
            }
            let conversation = MemoryConversation(id: session, started: Date(timeIntervalSince1970: started),
                                                  turns: turns)
            let parse = try await remember(conversation, model: model)
            parsed.append(parse)
            if parse.status == .parsed || (talk[2].int ?? 0) >= 1 {
                try release(session)
            } else {
                try db.run("UPDATE queue SET attempts = attempts + 1 WHERE session = ?", [.text(session)])
            }
        }
        return parsed
    }

    /// The talk leaves the queue with its transcript, and the WAL is truncated after it.
    private func release(_ session: String) throws {
        try db.run("DELETE FROM queue WHERE session = ?", [.text(session)])
        _ = try db.rows("PRAGMA wal_checkpoint(TRUNCATE)")
    }
}

/// The memory's folder on the phone (M38, вопрос 7): `Application Support/Memory`, out of the backup as read back; the
/// base opens with the complete protection (`flags`). A refusal says why, and then the memory is not written.
public enum MemoryFiles {
    public enum Folder: Equatable {
        case ready(URL)
        /// The folder could not be made, or the backup mark did not read back.
        case refused(Reason)
    }

    public enum Reason: Equatable { case folder, backup }

    /// SQLite's open flags of the base: the complete file protection on Apple.
    public static var flags: Int32 { SQLiteConnection.protectionComplete }

    public static func prepare(under root: URL) -> Folder {
        var folder = root.appendingPathComponent("Memory", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
        } catch {
            return .refused(.folder)
        }
        folder.removeAllCachedResourceValues()
        let read = try? folder.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        return read == true ? .ready(folder) : .refused(.backup)
    }
}
