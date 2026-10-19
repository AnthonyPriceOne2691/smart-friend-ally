import Foundation

/// Data of `router.json`, one copy with the Python reference (local/spike/router-proto/router_core.py).
struct RouterData: Decodable, Sendable {
    /// A topic by priority: the object, her action verbs; `strong` — the object with intent or a question is enough;
    /// `source` — [concept, prefixes]: with that concept every object word of these prefixes is not hers (a stove's
    /// fire); `verbAlone` — her verb of this concept is enough without the object.
    struct Hazard: Decodable, Sendable {
        let topic, object: String, verbs: [String], strong: Bool?, source: [String]?, verbAlone: String?
    }

    struct Noise: Decodable, Sendable {
        let vowels, soft: String, reduce, child, voice, classes: [String], cost: [String: Double], budget: [Double]
    }

    struct Probe: Decodable, Sendable { let text, want: String, game: Bool? }

    var lexicon: [String: [[String]]], exactHash: String
    let hazards: [Hazard], gameGuards: [String], sets: [String: [String]], noise: Noise
    let exactOnly: [String: [String]], selftest: [Probe]

    static let bytes: Data = {
        guard let url = Bundle.module.url(forResource: "router", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("Discipline: router.json is unreadable") }
        return bytes
    }()

    static func decode(_ bytes: Data) -> RouterData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(RouterData.self, from: bytes)
        } catch {
            fatalError("Discipline: router.json does not decode: \(error)")
        }
    }

    /// FNV-1a of the lexicon and the noise model the doubles belong to (`lexicon_hash` of the reference).
    var lexiconHash: String {
        let entries = lexicon.keys.sorted().flatMap { concept in
            lexicon[concept, default: []].map { ([concept] + $0).joined(separator: "\t") }
        }
        let pairs = [noise.reduce, noise.child, noise.voice, noise.classes].map { $0.joined(separator: " ") }
        let costs = noise.cost.keys.sorted().map { "\($0)=" + Self.fixed(noise.cost[$0] ?? 0) }
        let lines = entries + [noise.vowels, noise.soft] + pairs
            + [costs.joined(separator: " "), noise.budget.map(Self.fixed).joined(separator: " ")]
        return fnv1a(Data(lines.joined(separator: "\n").utf8))
    }

    static func fixed(_ value: Double) -> String { String(format: "%.2f", value) }
}

/// The noise model of a five-year-old and the recognizer over а…я as tables (`sub_cost`, `indel_cost`, `first_ok`
/// of the reference); `child: false` is the ablation of the child costs.
struct NoiseTable: Sendable {
    let sub: [[Double]], gap: [Double], first, child: [[Bool]], repeated: Double, budget: [Double]

    init(_ noise: RouterData.Noise, child on: Bool) {
        let letters = (0x430...0x44F).compactMap(Unicode.Scalar.init(_:))
        let vowels = Set(noise.vowels.unicodeScalars), soft = Set(noise.soft.unicodeScalars)
        let pairs = { (list: [String]) in Set(list.map { Set($0.unicodeScalars) }) }
        let (reduce, kid, voice) = (pairs(noise.reduce), on ? pairs(noise.child) : [], pairs(noise.voice))
        let classOf = Dictionary(noise.classes.enumerated().flatMap { index, group in
            group.unicodeScalars.map { ($0, index) }
        }, uniquingKeysWith: { _, last in last })
        let cost = { (name: String) in noise.cost[name] ?? 1 }
        func substitution(_ a: Unicode.Scalar, _ b: Unicode.Scalar) -> Double {
            if a == b { return 0 }
            if vowels.contains(a), vowels.contains(b) { return cost(reduce.contains([a, b]) ? "reduce" : "vowel") }
            if kid.contains([a, b]) { return cost("child") }
            if voice.contains([a, b]) { return cost("voice") }
            if let group = classOf[a], group == classOf[b] { return cost("class") }
            return cost("other")
        }
        sub = letters.map { a in letters.map { b in substitution(a, b) } }
        gap = letters.map { on && soft.contains($0) ? cost("soft") : cost(vowels.contains($0) ? "vowel_gap" : "gap") }
        let pair = letters.map { a in letters.map { b in kid.contains([a, b]) } }
        first = letters.map { a in letters.map { b in a == b || vowels.contains(a) && vowels.contains(b) } }
            .enumerated().map { row, cells in zip(cells, pair[row]).map { $0 || $1 } }
        (child, repeated, budget) = (pair, cost("repeat"), noise.budget)
    }

    /// The cost of a letter with nothing against it: a repeated letter is cheap.
    func indel(_ letters: [Int], _ index: Int) -> Double {
        index > 0 && letters[index] == letters[index - 1] ? repeated : gap[letters[index]]
    }
}
