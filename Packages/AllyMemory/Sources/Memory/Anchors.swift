import Foundation

/// Reads an answer into candidates anchored in her words: the value in her turn the model cited — she said it; in
/// another turn of hers — the code found it; only in Elly's line before her «да» — she agreed; nowhere — dropped.
struct Reading {
    let turns: [MemoryTurn]
    private let texts: ExtractTexts
    private(set) var candidates: [Candidate] = [], dropped: [Extraction.Drop] = []

    init(turns: [MemoryTurn], texts: ExtractTexts = .shared) { (self.turns, self.texts) = (turns, texts) }

    /// Her, the family, the pets, the creations — in the template's order.
    mutating func read(_ answer: ModelAnswer) {
        if let she = answer.she {
            put(.child, .name, she.name, "she.name")
            age(.child, she.age, "she.age")
            put(.child, .birthday, she.birthday, "she.birthday")
            for item in she.favorites ?? [] { favorite(item) }
            for item in she.likes ?? [] { put(.child, .likes, item, "she.likes") }
            for item in she.can ?? [] { put(.child, .can, item, "she.can") }
        }
        for person in answer.people ?? [] { family(person) }
        for pet in answer.pets ?? [] { thing(pet, "pets") { .pet(species: $0, name: $1) } }
        for creation in answer.creations ?? [] { thing(creation, "creations") { .creation(kind: $0, name: $1) } }
    }

    /// A value with the turn of hers it stands on and the kind of anchor.
    struct Hit { let value: String, turn: Int, anchor: Anchor }

    /// The value of «N: …» with its turn and anchor; nil — none, and the drop is recorded.
    mutating func take(_ item: String?, _ field: String) -> Hit? {
        guard let item else { return nil }
        let (cited, value) = Self.split(item)
        if let turn = turns.first(where: { $0.number == cited }), grounded(value, in: turn.her) {
            return Hit(value: value, turn: turn.number, anchor: .said)
        }
        if let turn = turns.first(where: { grounded(value, in: $0.her) }) {
            return Hit(value: value, turn: turn.number, anchor: .found)
        }
        for (index, turn) in turns.enumerated().dropFirst() where yes(turn.her) {
            if let elly = turns[index - 1].elly, grounded(value, in: elly) {
                return Hit(value: value, turn: turn.number, anchor: .agreed)
            }
        }
        dropped.append(Extraction.Drop(field: field, reason: .ungrounded))
        return nil
    }

    /// Her line begins with «да», «давай» and the like.
    func yes(_ line: String) -> Bool { Forbidden.tokens(line).first.map(texts.yes.contains) ?? false }

    /// At least half of the value's words are in the line, and at least one: numbers by value, words by their start.
    func grounded(_ value: String, in line: String) -> Bool {
        let number = { (token: String) in Forbidden.shared.numbers([token]).first }
        let wanted = Forbidden.tokens(value).filter { $0.count >= 3 && !texts.stop.contains($0) || number($0) != nil }
        let words = Forbidden.tokens(line)
        let hits = wanted.filter { want in
            number(want).map { value in words.contains { number($0) == value } }
                ?? words.contains { Taint.alike($0, want, least: 3) }
        }
        return !hits.isEmpty && hits.count * 2 >= wanted.count
    }

    /// «12: любит спать» → (12, «любит спать»); without a number — (nil, the text).
    static func split(_ item: String) -> (Int?, String) {
        let text = item.trimmingCharacters(in: .whitespaces), digits = text.prefix { $0.isNumber }
        let rest = text.dropFirst(digits.count).drop { $0 == " " }
        guard !digits.isEmpty, let mark = rest.first, ":.)-–—".contains(mark) else { return (nil, text) }
        return (Int(digits), rest.dropFirst().trimmingCharacters(in: .whitespaces))
    }

    private mutating func put(_ subject: Subject, _ trait: Trait, _ item: String?, _ field: String, slot: Slot? = nil) {
        guard let hit = take(item, field) else { return }
        candidates.append(Candidate(subject, trait, hit.value, slot: slot, turn: hit.turn, anchor: hit.anchor))
    }

    /// An age in words or digits, 1–20 as the base keeps it.
    private mutating func age(_ subject: Subject, _ item: String?, _ field: String) {
        guard let hit = take(item, field) else { return }
        guard let years = Forbidden.shared.numbers(Forbidden.tokens(hit.value)).first, (1...20).contains(years) else {
            return dropped.append(Extraction.Drop(field: field, reason: .age))
        }
        candidates.append(Candidate(subject, .age, String(years), turn: hit.turn, anchor: hit.anchor))
    }

    /// «цвет — фиолетовый»: the slot by its word, else «другое».
    private mutating func favorite(_ item: String) {
        guard let hit = take(item, "she.favorite") else { return }
        let dash = hit.value.range(of: "—") ?? hit.value.range(of: "–") ?? hit.value.range(of: " - ")
        let word = dash.map { MemoryStore.key(String(hit.value[..<$0.lowerBound])) } ?? ""
        let value = dash.map { hit.value[$0.upperBound...].trimmingCharacters(in: .whitespaces) } ?? hit.value
        let slot = Words.shared.slots.first { $0.last == word && !word.isEmpty }?.first.flatMap(Slot.init) ?? .other
        candidates.append(Candidate(.child, .favorite, value, slot: slot, turn: hit.turn, anchor: hit.anchor))
    }

    private mutating func family(_ person: ModelAnswer.Person) {
        let who = person.who.map(MemoryStore.key)
        guard let relation = (Words.shared.siblings + Words.shared.family).first(where: { $0.last == who })?.first
            .flatMap(Relation.init) else {
            return dropped.append(Extraction.Drop(field: "people.who", reason: .relation))
        }
        let name = take(person.name, "people.name"), subject = Subject.person(relation, name: name?.value)
        if let name { candidates.append(Candidate(subject, .name, name.value, turn: name.turn, anchor: name.anchor)) }
        age(subject, person.age, "people.age")
        for item in person.details ?? [] { put(subject, .detail, item, "people.detail") }
    }

    /// A pet or a creation: its kind and name anchor it; without both its colour and details belong to no one.
    private mutating func thing(_ thing: ModelAnswer.Thing, _ field: String, _ make: (String?, String?) -> Subject) {
        let kind = take(thing.kind, field + ".species"), name = take(thing.name, field + ".name")
        guard kind != nil || name != nil else {
            let orphans = (thing.color.map { _ in [field + ".color"] } ?? [])
                + (thing.details ?? []).map { _ in field + ".detail" }
            return dropped += orphans.map { Extraction.Drop(field: $0, reason: .ungrounded) }
        }
        let subject = make(kind?.value, name?.value)
        for (trait, hit) in [(Trait.species, kind), (.name, name)] {
            if let hit { candidates.append(Candidate(subject, trait, hit.value, turn: hit.turn, anchor: hit.anchor)) }
        }
        put(subject, .color, thing.color, field + ".color")
        for item in thing.details ?? [] { put(subject, .detail, item, field + ".detail") }
    }
}
