import AllySQLite
import Foundation

/// Who of her family a person is — the closed list of the schema.
public enum Relation: String, Sendable, CaseIterable {
    case brother, sister, mom, dad, grandma, grandpa
}

/// What kind of entity a fact hangs on.
public enum Kind: String, Sendable {
    case child, person, pet, creation
}

/// Whom a fact is about, with what identifies them: her; a family member; her pet; something she made up.
public enum Subject: Equatable, Sendable {
    case child
    case person(Relation, name: String?)
    case pet(species: String?, name: String?)
    case creation(kind: String?, name: String?)
}

/// What a fact says. One active value at a time, except what she likes, what she can do and the details.
public enum Trait: String, Sendable {
    case name, age, birthday, species, color, favorite, likes, can, detail

    var single: Bool { self != .likes && self != .can && self != .detail }
}

/// The slot of a favorite, in the block's order.
public enum Slot: String, Sendable, CaseIterable {
    case color, food, animal, game, toy, cartoon, song, book, other
}

/// Where the value is in her words: said in the cited turn, found by the code in another turn of hers, or agreed to
/// Elly's suggestion. The confidence is the code's, never the model's.
public enum Anchor: Sendable {
    case said, found, agreed

    var confidence: Double {
        switch self {
        case .said: 0.9
        case .found: 0.8
        case .agreed: 0.6
        }
    }
}

/// One checked fact of a session: about whom, what, the value, her turn and the kind of anchor — no confidence field.
public struct Candidate: Equatable, Sendable {
    public let subject: Subject, trait: Trait, slot: Slot?, value: String, turn: Int, anchor: Anchor

    public init(_ subject: Subject, _ trait: Trait, _ value: String, slot: Slot? = nil, turn: Int,
                anchor: Anchor = .said) {
        (self.subject, self.trait, self.slot, self.value) = (subject, trait, slot, value)
        (self.turn, self.anchor) = (turn, anchor)
    }
}

/// A session's checked facts: its id and its start — the moment that decides which value is newer; her lines of the
/// session — what they taint is not stored (`Taint`), and they are not stored either.
public struct MemorySession: Sendable {
    public let id: String, started: Date, candidates: [Candidate], heard: [String]

    public init(id: String, started: Date, candidates: [Candidate], heard: [String] = []) {
        (self.id, self.started, self.candidates, self.heard) = (id, started, candidates, heard)
    }
}

/// What a write did; `olderThanWipe` — the session began before «стереть всё», and nothing of it was written;
/// `refused` — candidates not written, by the id of the rule (`forbidden.json`), without their values.
public struct WriteReport: Equatable, Sendable {
    public var added = 0, confirmed = 0, replaced = 0, skippedOlder = 0, olderThanWipe = false
    public var refused: [String: Int] = [:]
}

/// What «стереть всё» erased.
public struct EraseReport: Equatable, Sendable {
    public let entities: Int, facts: Int
}

/// A fact as the store keeps it: its entity, the earliest session's value and turn, the code's confidence.
public struct StoredFact: Equatable, Sendable {
    public let id: Int64, entity: Int64, kind: Kind, relation: Relation?, trait: Trait, slot: Slot?
    public let value: String, key: String, session: String, turn: Int, confidence: Double
    public let firstSeen: Double, lastSeen: Double, sessions: Int, active: Bool, supersededBy: Int64?

    init?(row: [SQLiteValue]) {
        guard row.count == 16, let id = row[0].int, let entity = row[1].int, let kind = row[2].text.flatMap(Kind.init),
              let trait = row[4].text.flatMap(Trait.init), let value = row[6].text, let key = row[7].text,
              let session = row[8].text else { return nil }
        (self.id, self.entity, self.kind, self.trait, self.value, self.key) = (id, entity, kind, trait, value, key)
        (relation, slot, self.session) = (row[3].text.flatMap(Relation.init), row[5].text.flatMap(Slot.init), session)
        (turn, confidence) = (Int(row[9].int ?? 0), row[10].real ?? 0)
        (firstSeen, lastSeen, sessions) = (row[11].real ?? 0, row[12].real ?? 0, Int(row[13].int ?? 0))
        (active, supersededBy) = (row[14].text == "active", row[15].int)
    }
}
