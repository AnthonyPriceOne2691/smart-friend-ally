import AllySQLite

/// The memory database, schema 1. The closed lists are CHECKs: neither the model nor a bug adds a category. A fact
/// keeps the sessions that said it (`seen`), so a confirmation counts once per session in any order of writing. A value
/// under the never-stored list is refused by the triggers on any path of writing (`forbidden`, `Forbidden.install`).
enum Schema {
    static let version: Int64 = 1

    /// A pragma and what it reads back as.
    struct Pragma { let name: String, value: SQLiteValue, set: String }

    /// WAL, deleted content overwritten, foreign keys — each read back after it is set.
    static let pragmas = [
        Pragma(name: "journal_mode", value: .text("wal"), set: "PRAGMA journal_mode = WAL"),
        Pragma(name: "secure_delete", value: .int(1), set: "PRAGMA secure_delete = ON"),
        Pragma(name: "foreign_keys", value: .int(1), set: "PRAGMA foreign_keys = ON")
    ]

    static let tables = """
        CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value);
        CREATE TABLE IF NOT EXISTS entity (
          id INTEGER PRIMARY KEY,
          kind TEXT NOT NULL CHECK (kind IN ('child', 'person', 'pet', 'creation')),
          relation TEXT CHECK (relation IN ('brother', 'sister', 'mom', 'dad', 'grandma', 'grandpa')),
          CHECK ((kind = 'person') = (relation IS NOT NULL)));
        CREATE TABLE IF NOT EXISTS fact (
          id INTEGER PRIMARY KEY,
          entity_id INTEGER NOT NULL REFERENCES entity (id) ON DELETE CASCADE,
          trait TEXT NOT NULL CHECK (trait IN ('name', 'age', 'birthday', 'species', 'color', 'favorite', 'likes',
                                              'can', 'detail')),
          slot TEXT CHECK (slot IN ('color', 'food', 'animal', 'game', 'toy', 'cartoon', 'song', 'book', 'other')),
          value TEXT NOT NULL, value_key TEXT NOT NULL, session TEXT NOT NULL, turn INTEGER NOT NULL,
          confidence REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1),
          first_seen REAL NOT NULL, last_seen REAL NOT NULL, sessions INTEGER NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('active', 'superseded')),
          superseded_by INTEGER REFERENCES fact (id),
          CHECK ((trait = 'favorite') = (slot IS NOT NULL)),
          CHECK (trait <> 'age' OR CAST(value AS INTEGER) BETWEEN 1 AND 20));
        CREATE TABLE IF NOT EXISTS seen (
          fact_id INTEGER NOT NULL REFERENCES fact (id) ON DELETE CASCADE,
          session TEXT NOT NULL, started REAL NOT NULL, turn INTEGER NOT NULL, value TEXT NOT NULL,
          anchor REAL NOT NULL, PRIMARY KEY (fact_id, session));
        CREATE INDEX IF NOT EXISTS fact_entity ON fact (entity_id, trait, status);
        CREATE TABLE IF NOT EXISTS queue (session TEXT PRIMARY KEY, started REAL NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE IF NOT EXISTS pending (
          session TEXT NOT NULL REFERENCES queue (session) ON DELETE CASCADE, turn INTEGER NOT NULL,
          her TEXT NOT NULL, elly TEXT NOT NULL, PRIMARY KEY (session, turn));
        CREATE TRIGGER IF NOT EXISTS fact_insert_forbidden BEFORE INSERT ON fact
          WHEN forbidden(NEW.value) OR forbidden(NEW.value_key) BEGIN SELECT RAISE(ABORT, 'forbidden value'); END;
        CREATE TRIGGER IF NOT EXISTS fact_update_forbidden BEFORE UPDATE OF value, value_key ON fact
          WHEN forbidden(NEW.value) OR forbidden(NEW.value_key) BEGIN SELECT RAISE(ABORT, 'forbidden value'); END;
        CREATE TRIGGER IF NOT EXISTS seen_insert_forbidden BEFORE INSERT ON seen
          WHEN forbidden(NEW.value) BEGIN SELECT RAISE(ABORT, 'forbidden value'); END;
        CREATE TRIGGER IF NOT EXISTS seen_update_forbidden BEFORE UPDATE OF value ON seen
          WHEN forbidden(NEW.value) BEGIN SELECT RAISE(ABORT, 'forbidden value'); END;
        """

    /// A fact from its sessions: value, session and turn of the earliest; the confidence — the best anchor plus 0.05
    /// for each further session, at most 1.0.
    static let recount = """
        UPDATE fact SET
          (value, session, turn, first_seen) = (SELECT value, session, turn, started FROM seen WHERE fact_id = ?1
                                                ORDER BY started, session LIMIT 1),
          last_seen = (SELECT MAX(started) FROM seen WHERE fact_id = ?1),
          sessions = (SELECT COUNT(*) FROM seen WHERE fact_id = ?1),
          confidence = MIN(1.0, ROUND((SELECT MAX(anchor) + 0.05 * (COUNT(*) - 1) FROM seen WHERE fact_id = ?1), 2))
        WHERE id = ?1
        """

    static let insertFact = """
        INSERT INTO fact (entity_id, trait, slot, value, value_key, session, turn, confidence, first_seen, last_seen,
                          sessions, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'active')
        """

    static let selectFacts = """
        SELECT f.id, f.entity_id, e.kind, e.relation, f.trait, f.slot, f.value, f.value_key, f.session, f.turn,
               f.confidence, f.first_seen, f.last_seen, f.sessions, f.status, f.superseded_by
        FROM fact f JOIN entity e ON e.id = f.entity_id
        """

    static let selectEntities = """
        SELECT e.id,
          (SELECT value_key FROM fact WHERE entity_id = e.id AND trait = 'name' AND status = 'active'),
          (SELECT value_key FROM fact WHERE entity_id = e.id AND trait = 'species' AND status = 'active')
        FROM entity e WHERE e.kind = ? AND e.relation IS ? ORDER BY e.id
        """
}
