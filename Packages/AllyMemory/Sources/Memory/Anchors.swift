import Foundation

/// Reads an answer into candidates anchored in her words: the value in her turn the model cited — she said it; in
/// another turn of hers — the code found it; only in Elly's line before her «да» — she agreed; nowhere — dropped.
/// Inside pretend play only the creations stay; a negated value, a pet of someone else and a favourite without its word
/// are the code's to judge, not the model's.
struct Reading {
    let turns: [MemoryTurn]
    private let texts: ExtractTexts, sense: SenseWords, fiction: Set<Int>, names: [String]
    private(set) var candidates: [Candidate] = [], dropped: [Extraction.Drop] = []

    /// - Parameter names: the keys of the names memory already has — a creation is not named after one of them.
    init(turns: [MemoryTurn], names: [String] = [], texts: ExtractTexts = .shared, sense: SenseWords = .shared) {
        (self.turns, self.texts, self.sense, fiction, self.names) = (turns, texts, sense, sense.fiction(turns), names)
    }

    /// What she no longer likes in this conversation («больше не люблю танцы» → «танцы»).
    var unlikes: [String] { sense.unlikes(turns, stop: texts.stop) }

    /// Her, the family, the pets, the creations — in the template's order.
    mutating func read(_ answer: ModelAnswer) {
        if let she = answer.she {
            put(.child, .name, she.name, "she.name")
            age(.child, she.age, "she.age")
            put(.child, .birthday, she.birthday, "she.birthday")
            for item in she.favorites ?? [] { favorite(item) }
            for item in she.likes ?? [] { put(.child, .likes, item, "she.likes") }
            for item in she.can ?? [] where !past(item) { put(.child, .can, item, "she.can") }
        }
        for person in answer.people ?? [] { family(person) }
        for pet in answer.pets ?? [] { thing(pet, "pets") { .pet(species: $0, name: $1) } }
        for creation in answer.creations ?? [] { thing(creation, "creations") { .creation(kind: $0, name: $1) } }
    }

    /// A value with the turn of hers it stands on and the kind of anchor.
    struct Hit { let value: String, turn: Int, anchor: Anchor }

    /// The value of «N: …» with its turn and anchor; nil — none, inside pretend play (but a creation) or negated, and
    /// the drop is recorded.
    mutating func take(_ item: String?, _ field: String) -> Hit? {
        guard let item else { return nil }
        guard let hit = anchor(Self.split(item)) else {
            dropped.append(Extraction.Drop(field: field, reason: .ungrounded))
            return nil
        }
        let reason: Extraction.Drop.Reason? = fiction.contains(hit.turn) && !field.hasPrefix("creations") ? .fiction
            : sense.negated(words(hit.value), in: her(hit.turn)) ? .negated : nil
        guard let reason else { return hit }
        dropped.append(Extraction.Drop(field: field, reason: reason))
        return nil
    }

    /// Where the value stands in her words: the cited turn, another turn of hers, her «да» after Elly's line.
    func anchor(_ item: (cited: Int?, value: String)) -> Hit? {
        let value = item.value
        if let turn = turns.first(where: { $0.number == item.cited }), grounded(value, in: turn.her) {
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
        return nil
    }

    /// Her line of a turn, and Elly's line before it.
    func her(_ turn: Int) -> String { turns.first { $0.number == turn }?.her ?? "" }
    func ellyBefore(_ turn: Int) -> String {
        guard let index = turns.firstIndex(where: { $0.number == turn }), index > 0 else { return "" }
        return turns[index - 1].elly ?? ""
    }

    /// Her line begins with «да», «давай» and the like.
    func yes(_ line: String) -> Bool { Forbidden.tokens(line).first.map(texts.yes.contains) ?? false }

    /// The value's words that count: three letters and more, not a word of the form, or a number.
    func words(_ value: String) -> [String] { Self.words(value, stop: texts.stop) }

    static func words(_ value: String, stop: Set<String>) -> [String] {
        Forbidden.tokens(value).filter {
            $0.count >= 3 && !stop.contains($0) || !Forbidden.shared.numbers([$0]).isEmpty
        }
    }

    /// At least half of the value's words are in the line, and at least one: numbers by value, words by their start.
    func grounded(_ value: String, in line: String) -> Bool { Self.covers(value, line, stop: texts.stop) }

    static func covers(_ value: String, _ line: String, stop: Set<String> = ExtractTexts.shared.stop) -> Bool {
        let number = { (token: String) in Forbidden.shared.numbers([token]).first }
        let wanted = words(value, stop: stop)
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
        if trait == .detail, restates(hit.value, subject) {
            return dropped.append(Extraction.Drop(field: field, reason: .restates))
        }
        candidates.append(Candidate(subject, trait, hit.value, slot: slot, turn: hit.turn, anchor: hit.anchor))
    }

    /// A detail that only repeats who it is about: «для Тёмы» of the brother Тёма.
    private func restates(_ detail: String, _ subject: Subject) -> Bool {
        let who: [String?] = switch subject {
        case .child: []
        case .person(let relation, let name):
            [(Words.shared.siblings + Words.shared.family).label(relation.rawValue), name]
        case .pet(let species, let name), .creation(let species, let name): [species, name]
        }
        let identity = words(who.compactMap { $0 }.joined(separator: " ")), said = words(detail)
        let making = subject.made ? sense.making : []
        return !said.isEmpty && said.allSatisfy { word in
            identity.contains { Taint.alike(word, $0, least: 3) } || making.contains(where: word.hasPrefix)
        }
    }

    /// «Умеет: рисовала» is what she did, not what she can: a skill is not in the past tense.
    private mutating func past(_ item: String) -> Bool {
        guard let first = words(Self.split(item).1).first, first.count >= 5,
              sense.past.contains(where: first.hasSuffix) else { return false }
        dropped.append(Extraction.Drop(field: "she.can", reason: .restates))
        return true
    }

    /// A creation named after someone memory knows: «домик для мурки» is not a house named Мурка.
    private func namesake(_ value: String) -> Bool {
        let key = MemoryStore.key(value)
        let known = names
            + candidates.filter { $0.trait == .name && !$0.subject.made }.map { MemoryStore.key($0.value) }
        return known.contains { Taint.alike($0, key, least: 3) }
    }

    /// An age in words or digits, 1–20 as the base keeps it.
    private mutating func age(_ subject: Subject, _ item: String?, _ field: String) {
        guard let hit = take(item, field) else { return }
        guard let years = Forbidden.shared.numbers(Forbidden.tokens(hit.value)).first, (1...20).contains(years) else {
            return dropped.append(Extraction.Drop(field: field, reason: .age))
        }
        candidates.append(Candidate(subject, .age, String(years), turn: hit.turn, anchor: hit.anchor))
    }

    /// «цвет — фиолетовый»: the slot by its word, else «другое»; without «любимый», «самый», «больше всего» in her
    /// line or in Elly's line before it — what she likes, not a favourite.
    private mutating func favorite(_ item: String) {
        guard let hit = take(item, "she.favorite") else { return }
        let dash = hit.value.range(of: "—") ?? hit.value.range(of: "–") ?? hit.value.range(of: " - ")
        let word = dash.map { MemoryStore.key(String(hit.value[..<$0.lowerBound])) } ?? ""
        let after = dash.map { hit.value[$0.upperBound...].trimmingCharacters(in: .whitespaces) } ?? hit.value
        let before = dash.map { String(hit.value[..<$0.lowerBound]).trimmingCharacters(in: .whitespaces) } ?? ""
        let value = words(after).isEmpty && !words(before).isEmpty ? before : after  // «качели — больше всего»
        let said = SenseWords.phrase(her(hit.turn) + " " + ellyBefore(hit.turn))
        guard sense.favorite.contains(where: { said.contains(" " + $0) }) else {
            return candidates.append(Candidate(.child, .likes, value, turn: hit.turn, anchor: hit.anchor))
        }
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
        let kind = take(thing.kind, field + ".species")
        var name = take(thing.name, field + ".name")
        if field == "creations", let hit = name, namesake(hit.value) {
            (name, _) = (nil, dropped.append(Extraction.Drop(field: field + ".name", reason: .namesake)))
        }
        if field == "pets", let hit = kind, !sense.homely(words(hit.value)) {
            return dropped.append(Extraction.Drop(field: field + ".species", reason: .notPet))
        }
        guard kind != nil || name != nil else {
            let orphans = (thing.color.map { _ in [field + ".color"] } ?? [])
                + (thing.details ?? []).map { _ in field + ".detail" }
            return dropped += orphans.map { Extraction.Drop(field: $0, reason: .ungrounded) }
        }
        if field == "pets", let hit = kind ?? name,
           let owner = sense.owner(of: words([kind?.value, name?.value].compactMap { $0 }.joined(separator: " ")),
                                   in: her(hit.turn)) {
            return foreign(thing, owner, kind: kind, name: name)
        }
        let subject = make(kind?.value, name?.value)
        for (trait, hit) in [(Trait.species, kind), (.name, name)] {
            if let hit { candidates.append(Candidate(subject, trait, hit.value, turn: hit.turn, anchor: hit.anchor)) }
        }
        put(subject, .color, thing.color, field + ".color")
        for item in thing.details ?? [] { put(subject, .detail, item, field + ".detail") }
    }

    /// A pet of someone else: of the family — a detail of that relative in her words («у бабушки собака Бим»); of
    /// anyone else — nothing; the pet's own facts are not hers either way.
    private mutating func foreign(_ thing: ModelAnswer.Thing, _ owner: (relation: Relation?, word: String),
                                  kind: Hit?, name: Hit?) {
        if let relation = owner.relation, let hit = kind ?? name {
            let detail = (["у", owner.word] + [kind?.value, name?.value].compactMap { $0 }).joined(separator: " ")
            candidates.append(Candidate(.person(relation, name: nil), .detail, detail, turn: hit.turn,
                                        anchor: hit.anchor))
        }
        let own = ["pets"] + (thing.color.map { _ in ["pets.color"] } ?? [])
            + (thing.details ?? []).map { _ in "pets.detail" }
        dropped += own.map { Extraction.Drop(field: $0, reason: .foreign) }
    }
}

extension Subject {
    /// Something she made up — its name may repeat a real one.
    var made: Bool { if case .creation = self { true } else { false } }
}
