import AllySQLite
import Foundation

/// What the parent's console shows to forget one thing (memory-forget, M41): an entity with its active facts in the
/// block's words, both in their order of appearance.
public struct Remembered: Equatable, Sendable {
    public struct Item: Equatable, Sendable { public let fact: Int64, text: String }
    public let entity: Int64, title: String, items: [Item]
}

/// «Забыть» one fact or one entity (M41): the rows go — a single-valued trait with its history, a value with its
/// repeats — `secure_delete` overwrites them and the WAL is truncated, so no byte of it is left in the base, its WAL or
/// SHM. A tombstone holds who, what and when, never the value: a session begun before the forgetting — parsed again or
/// waiting in the queue — does not bring it back; one begun after it learns again, as after «стереть всё».
extension MemoryStore {
    /// The active facts by entity.
    public func remembered() throws -> [Remembered] {
        let facts = try facts().sorted { ($0.firstSeen, $0.turn, $0.id) < ($1.firstSeen, $1.turn, $1.id) }
        var order: [Int64] = [], groups: [Int64: [StoredFact]] = [:]
        for fact in facts {
            if groups[fact.entity] == nil { order.append(fact.entity) }
            groups[fact.entity, default: []].append(fact)
        }
        return order.compactMap { entity in
            groups[entity].map { facts in
                Remembered(entity: entity, title: Self.title(facts),
                           items: facts.map { Remembered.Item(fact: $0.id, text: Self.text($0)) })
            }
        }
    }

    /// Forgets a fact: a single-valued trait with its history, else the value with its repeats; the rows gone.
    @discardableResult
    public func forget(fact id: Int64, now: Date) throws -> Int {
        guard let fact = try facts().first(where: { $0.id == id }) else { return 0 }
        var bound: [SQLiteValue] = [.int(fact.entity), .text(fact.trait.rawValue), fact.slot.map { .text($0.rawValue) }
                                    ?? .null]
        if !fact.trait.single { bound.append(.text(fact.key)) }
        var gone = 0
        try db.transaction {
            gone = try db.run("DELETE FROM fact WHERE entity_id = ? AND trait = ? AND slot IS ?"
                              + (fact.trait.single ? "" : " AND value_key = ?"), bound)
            try bury((fact.kind, fact.relation), [.int(fact.entity), bound[1], bound[2]], now: now)
        }
        try checkpoint()
        return gone
    }

    /// Forgets an entity with all its facts, the replaced ones too; the facts gone.
    @discardableResult
    public func forget(entity id: Int64, now: Date) throws -> Int {
        guard let row = try db.rows("SELECT kind, relation FROM entity WHERE id = ?", [.int(id)]).first,
              let kind = row[0].text.flatMap(Kind.init) else { return 0 }
        let gone = try facts(history: true).filter { $0.entity == id }.count
        try db.transaction {
            try db.run("DELETE FROM entity WHERE id = ?", [.int(id)])
            try bury((kind, row[1].text.flatMap(Relation.init)), [.null, .null, .null], now: now)
        }
        try checkpoint()
        return gone
    }

    /// The rule id `forgotten` when a candidate of a session begun before a forgetting names what was forgotten: any
    /// fact of a forgotten entity's kind and relation, or the forgotten trait of an entity still there.
    func forgotten(_ candidate: Candidate, before started: Date) throws -> String? {
        let who = Who(candidate.subject), entity = try find(who).map { SQLiteValue.int($0) } ?? .null
        let hit = try db.rows("SELECT 1 FROM forgotten WHERE moment > ? AND kind = ? AND relation IS ? "
                              + "AND (entity_id IS NULL OR (entity_id = ? AND trait = ? AND slot IS ?)) LIMIT 1", [
            .real(started.timeIntervalSince1970), who.bound[0], who.bound[1], entity, .text(candidate.trait.rawValue),
            candidate.slot.map { .text($0.rawValue) } ?? .null
        ])
        return hit.isEmpty ? nil : "forgotten"
    }

    /// A tombstone: who (kind and relation) and what (entity, trait, slot) was forgotten, and when — never the value.
    private func bury(_ who: (kind: Kind, relation: Relation?), _ what: [SQLiteValue], now: Date) throws {
        try db.run("INSERT INTO forgotten (kind, relation, entity_id, trait, slot, moment) VALUES (?, ?, ?, ?, ?, ?)",
                   [.text(who.kind.rawValue), who.relation.map { .text($0.rawValue) } ?? .null] + what
                    + [.real(now.timeIntervalSince1970)])
    }

    /// «Она», «Брат Тёма», «Кошка Мурка», «Придумала: единорог Звёздочка».
    static func title(_ facts: [StoredFact]) -> String {
        let words = Words.shared, name = facts.first { $0.trait == .name }?.value
        let species = facts.first { $0.trait == .species }?.value
        let head: String
        switch facts.first?.kind {
        case .child?, nil: return words.labels.she
        case .creation?: return words.labels.creations + ": " + [species, name].compactMap { $0 }.joined(separator: " ")
        case .person?: head = (words.siblings + words.family).label(facts.first?.relation?.rawValue) ?? ""
        case .pet?: head = species ?? words.labels.pet
        }
        return ([head.prefix(1).uppercased() + head.dropFirst()] + [name].compactMap { $0 }).joined(separator: " ")
    }

    /// A fact in the block's words: «восемь лет», «Любимое: цвет фиолетовый», «Умеет: считать до десяти».
    static func text(_ fact: StoredFact) -> String {
        let words = Words.shared
        switch fact.trait {
        case .age: return words.age(fact.value)
        case .birthday: return words.labels.birthday + " " + fact.value
        case .favorite: return words.labels.favorite + ": " + [words.slots.label(fact.slot?.rawValue) ?? "", fact.value]
            .filter { !$0.isEmpty }.joined(separator: " ")
        case .likes: return words.labels.likes + ": " + fact.value
        case .can: return words.labels.can + ": " + fact.value
        case .name, .species, .color, .detail: return fact.value
        }
    }
}
