import AllySQLite
import Foundation

/// What went wrong with the memory database itself.
public enum MemoryError: Error, Equatable {
    /// A pragma did not read back as set (WAL, secure delete, foreign keys).
    case pragma(String)
}

/// The memory database in its own folder (`memory.sqlite` with its WAL). One transaction per session; entities found by
/// relation and name; a single-valued trait replaced by date; a confirmation counted once per session; «стереть всё»
/// deletes the files. The owner serializes the calls.
public final class MemoryStore {
    public static let fileName = "memory.sqlite"
    public let directory: URL
    private let flags: Int32
    private var db: SQLiteConnection

    /// - Parameter flags: added to SQLite's open flags (on the phone — the file protection class, memory-app).
    public init(directory: URL, flags: Int32 = 0) throws {
        (self.directory, self.flags) = (directory, flags)
        db = try Self.open(directory, flags: flags)
    }

    /// Writes a session's candidates as one transaction; a session begun before the last erase writes nothing; a value
    /// under the never-stored list or tainted by her lines is not written and counts by its rule.
    @discardableResult
    public func write(_ session: MemorySession) throws -> WriteReport {
        var report = WriteReport()
        if let epoch = try wipeEpoch(), session.started < epoch {
            report.olderThanWipe = true
            return report
        }
        let taint = Taint(heard: session.heard)
        try db.transaction {
            for candidate in session.candidates {
                if let rule = Forbidden.shared.rule(candidate.value) ?? taint.rule(candidate.value) {
                    report.refused[rule, default: 0] += 1
                } else {
                    try apply(candidate, session, &report)
                }
            }
            for value in session.unlike { report.withdrawn += try withdraw(value, session) }
        }
        return report
    }

    /// «Больше не люблю X»: her active likes that X covers go to the history, unless confirmed after this session
    /// began.
    private func withdraw(_ value: String, _ session: MemorySession) throws -> Int {
        let likes = try db.rows("SELECT f.id, f.value, f.last_seen FROM fact f JOIN entity e ON e.id = f.entity_id "
                                + "WHERE e.kind = 'child' AND f.trait = 'likes' AND f.status = 'active'")
        let gone = likes.filter { row in
            (row[2].real ?? 0) <= session.started.timeIntervalSince1970 && Reading.covers(value, row[1].text ?? "")
        }
        for row in gone { try db.run("UPDATE fact SET status = 'superseded' WHERE id = ?", [row[0]]) }
        return gone.count
    }

    /// «Стереть всё»: the files go and an empty database starts with the wipe epoch.
    @discardableResult
    public func eraseAll(now: Date) throws -> EraseReport {
        let report = EraseReport(entities: try count("entity"), facts: try count("fact"))
        db.close()
        for suffix in ["", "-wal", "-shm", "-journal"] {
            let file = directory.appendingPathComponent(Self.fileName + suffix)
            if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        }
        db = try Self.open(directory, flags: flags)
        try db.run("INSERT OR REPLACE INTO meta (key, value) VALUES ('wipe_epoch', ?)",
                   [.real(now.timeIntervalSince1970)])
        return report
    }

    /// The moment of the last «стереть всё»; nil — never erased.
    public func wipeEpoch() throws -> Date? {
        try db.rows("SELECT value FROM meta WHERE key = 'wipe_epoch'").first?.first?.real
            .map(Date.init(timeIntervalSince1970:))
    }

    /// Facts with their entities: the active ones; with `history` — the values they replaced too.
    public func facts(history: Bool = false) throws -> [StoredFact] {
        try db.rows(Schema.selectFacts + (history ? "" : " WHERE f.status = 'active'") + " ORDER BY f.id")
            .compactMap(StoredFact.init(row:))
    }

    /// The prompt block of the active facts.
    public func block(budget: Int = MemoryBlock.budget, count: (String) -> Int = MemoryBlock.estimate) throws
        -> MemoryBlock {
        MemoryBlock.render(try facts(), budget: budget, count: count)
    }

    /// The value without case, «ё» and extra spaces: one key for «Тёма» and «тема».
    static func key(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "ё", with: "е").split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// An entity as identity sees it: the keys of its active name and species.
    struct Known { let id: Int64, name: String?, species: String? }

    /// The entity a subject names: by name, else the only unnamed one (of the species); without a name — the only one
    /// of the species or relation, else the only unnamed one. Nil — a new entity.
    static func match(_ known: [Known], name: String?, species: String?) -> Int64? {
        if let name {
            if let hit = known.first(where: { $0.name == name }) { return hit.id }
            let unnamed = known.filter { $0.name == nil && (species == nil || [nil, species].contains($0.species)) }
            return unnamed.count == 1 ? unnamed.first?.id : nil
        }
        let same = species.map { kind in known.filter { $0.species == kind } } ?? known
        if same.count == 1 { return same.first?.id }
        let unnamed = same.filter { $0.name == nil }
        return unnamed.count == 1 ? unnamed.first?.id : nil
    }

    private static func open(_ directory: URL, flags: Int32) throws -> SQLiteConnection {
        let db = try SQLiteConnection(path: directory.appendingPathComponent(fileName).path, flags: flags)
        try Forbidden.install(on: db)
        for pragma in Schema.pragmas {
            try db.exec(pragma.set)
            guard try db.rows("PRAGMA \(pragma.name)").first?.first == pragma.value else {
                throw MemoryError.pragma(pragma.name)
            }
        }
        try db.exec(Schema.tables)
        try db.run("INSERT OR IGNORE INTO meta (key, value) VALUES ('schema', ?)", [.int(Schema.version)])
        return db
    }

    private func apply(_ candidate: Candidate, _ session: MemorySession, _ report: inout WriteReport) throws {
        let entity = try resolve(candidate.subject)
        let key = Self.key(candidate.value)
        let existing = try active(entity, candidate.trait, candidate.slot)
        if let same = existing.first(where: { $0.key == key }) {
            if try see(same.id, candidate, session) { report.confirmed += 1 }
        } else if candidate.trait.single, let current = existing.first {
            guard session.started.timeIntervalSince1970 >= current.lastSeen else {
                report.skippedOlder += 1
                return
            }
            let id = try insert(entity, candidate, session)
            try db.run("UPDATE fact SET status = 'superseded', superseded_by = ? WHERE id = ?",
                       [.int(id), .int(current.id)])
            report.replaced += 1
        } else {
            _ = try insert(entity, candidate, session)
            report.added += 1
        }
    }

    private func resolve(_ subject: Subject) throws -> Int64 {
        let kind: Kind, relation: Relation?, name: String?, species: String?
        switch subject {
        case .child: (kind, relation, name, species) = (.child, nil, nil, nil)
        case .person(let who, let called): (kind, relation, name, species) = (.person, who, called, nil)
        case .pet(let what, let called): (kind, relation, name, species) = (.pet, nil, called, what)
        case .creation(let what, let called): (kind, relation, name, species) = (.creation, nil, called, what)
        }
        let bound: [SQLiteValue] = [.text(kind.rawValue), relation.map { .text($0.rawValue) } ?? .null]
        let known = try db.rows(Schema.selectEntities, bound).map {
            Known(id: $0[0].int ?? 0, name: $0[1].text, species: $0[2].text)
        }
        if let id = Self.match(known, name: name.map(Self.key), species: species.map(Self.key)) { return id }
        try db.run("INSERT INTO entity (kind, relation) VALUES (?, ?)", bound)
        return db.lastInsertID
    }

    /// An active fact as a write sees it.
    private struct Current { let id: Int64, key: String, lastSeen: Double }

    private func active(_ entity: Int64, _ trait: Trait, _ slot: Slot?) throws -> [Current] {
        let bound: [SQLiteValue] = [.int(entity), .text(trait.rawValue), slot.map { .text($0.rawValue) } ?? .null]
        return try db.rows("SELECT id, value_key, last_seen FROM fact WHERE entity_id = ? AND trait = ? "
                           + "AND slot IS ? AND status = 'active'", bound)
            .map { Current(id: $0[0].int ?? 0, key: $0[1].text ?? "", lastSeen: $0[2].real ?? 0) }
    }

    private func insert(_ entity: Int64, _ candidate: Candidate, _ session: MemorySession) throws -> Int64 {
        let started = session.started.timeIntervalSince1970
        try db.run(Schema.insertFact, [
            .int(entity), .text(candidate.trait.rawValue), candidate.slot.map { .text($0.rawValue) } ?? .null,
            .text(candidate.value), .text(Self.key(candidate.value)), .text(session.id), .int(Int64(candidate.turn)),
            .real(candidate.anchor.confidence), .real(started), .real(started)
        ])
        let id = db.lastInsertID
        _ = try see(id, candidate, session)
        return id
    }

    /// Counts the session for the fact once and recounts the fact from its sessions; false — counted before.
    private func see(_ fact: Int64, _ candidate: Candidate, _ session: MemorySession) throws -> Bool {
        let counted = try db.run("INSERT OR IGNORE INTO seen (fact_id, session, started, turn, value, anchor) "
                                 + "VALUES (?, ?, ?, ?, ?, ?)", [
            .int(fact), .text(session.id), .real(session.started.timeIntervalSince1970), .int(Int64(candidate.turn)),
            .text(candidate.value), .real(candidate.anchor.confidence)
        ])
        guard counted > 0 else { return false }
        try db.run(Schema.recount, [.int(fact)])
        return true
    }

    private func count(_ table: String) throws -> Int {
        Int(try db.rows("SELECT count(*) FROM \(table)").first?.first?.int ?? 0)
    }
}
