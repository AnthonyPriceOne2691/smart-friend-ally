import Foundation

/// Data of `contract.json`, one copy with the Python stand (make_fixtures.py checks it); dictionary keys stay as is.
struct ContractData: Decodable, Sendable {
    struct Limits: Decodable, Sendable {
        static let closed = Limits(maxSentences: 0, maxQuestions: 0, maxWords: 0, maxSentenceWords: 0,
                                   canned: "generic")
        let maxSentences, maxQuestions, maxWords, maxSentenceWords: Int, canned: String

        /// What is left to the statements before a closing question of `words` words: its question and words go.
        func reserving(words: Int) -> Limits {
            Limits(maxSentences: maxSentences, maxQuestions: maxQuestions - 1, maxWords: maxWords - words,
                   maxSentenceWords: maxSentenceWords, canned: canned)
        }
    }

    struct Probe: Decodable, Sendable { let rule, mode, reply: String, heard: String? }

    var modes: [String: Limits], attachment: [String: [String]]
    /// `content` — content rules ported in router-people by rule id; `pointers` — topic → [adult pointer, fallback].
    var content: [String: [String]], pointers: [String: [String]]
    let negatable, negation, clauseSplits: [String]
    let pleaSafety, hazard, encourage, dangerSafe, pointer, safety, prohibition, connective, pointerScript: String
    let action, filler, fillerQ: String
    let canned, fallbackOf, scripts: [String: String], hazardScripts: [[String]], selftest: [Probe]

    static let bytes: Data = {
        guard let url = Bundle.module.url(forResource: "contract", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("Discipline: contract.json is unreadable") }
        return bytes
    }()

    static func decode(_ bytes: Data) -> ContractData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(ContractData.self, from: bytes)
        } catch {
            fatalError("Discipline: contract.json does not decode: \(error)")
        }
    }
}

/// `contract.json` compiled once (`\b`, `\w` as in Python); an uncaught `selftest` probe leaves only canned replies.
struct Contract: Sendable {
    static let shared = Contract(ContractData.decode(ContractData.bytes), hash: fnv1a(ContractData.bytes))

    let data: ContractData, hash: String
    let attachment: [(group: String, patterns: [Pattern])], clauses: [Pattern]
    let negationInside, negationBefore, pleaSafety, hazard, encourage, dangerSafe, pointer, safety: Pattern
    let prohibition, action, filler, fillerQ, connective: Pattern, hazardScripts: [(word: Pattern, script: String)]
    let content: [String: [Pattern]]
    let phoneMark = Rules.shared.strip(Rules.shared.phoneMark)
    let sentence = Pattern("[^.!?…]+(?:[.!?…]+|$)"), comma = Pattern(",\\s+"), endMark = Pattern("[.!?…]$")
    let words = Pattern("[0-9a-z\\x{0430}-\\x{044F}\\x{0451}]+(?:[-'][0-9a-z\\x{0430}-\\x{044F}\\x{0451}]+)*")
    private(set) var healthy = true

    init(_ data: ContractData, hash: String) {
        let compile = { Contract.compile($0) }
        (self.data, self.hash, content) = (data, hash, data.content.mapValues { $0.map(compile) })
        attachment = data.attachment.sorted { $0.key < $1.key }.map { ($0.key, $0.value.map(compile)) }
        (negationInside, negationBefore) = (compile(data.negation.first ?? ""), compile(data.negation.last ?? ""))
        (pleaSafety, hazard) = (compile(data.pleaSafety), compile(data.hazard))
        (encourage, dangerSafe) = (compile(data.encourage), compile(data.dangerSafe))
        (pointer, safety) = (compile(data.pointer), compile(data.safety))
        (prohibition, action) = (compile(data.prohibition), compile(data.action))
        (filler, fillerQ) = (compile(data.filler), compile(data.fillerQ))
        connective = Contract.compile(data.connective, .caseInsensitive)
        clauses = data.clauseSplits.map { Pattern(NSRegularExpression.escapedPattern(for: $0)) }
        hazardScripts = data.hazardScripts.map { (compile("^(?:\($0.first ?? ""))"), $0.last ?? "") }
        healthy = data.selftest.allSatisfy(catches)
    }

    func limits(_ mode: TurnMode) -> ContractData.Limits { data.modes[mode.rawValue] ?? .closed }

    /// A pattern of the content rule matches.
    func found(_ rule: String, in text: String) -> Bool { content[rule, default: []].contains { $0.found(in: text) } }

    /// Group 1 of every match of the rule's patterns, left to right (`finditer` of the reference).
    func groups(_ rule: String, in text: String) -> [String] {
        var out: [String] = []
        for pattern in content[rule, default: []] {
            _ = pattern.replacing(in: text) { groups in
                out.append(groups.count > 1 ? groups[1] : groups[0])
                return ""
            }
        }
        return out
    }

    static func compile(_ pattern: String, _ options: NSRegularExpression.Options = []) -> Pattern {
        Pattern(pattern.replacingOccurrences(of: "\\w", with: Rules.word)
            .replacingOccurrences(of: "\\b", with: Rules.boundary), options)
    }

    private func catches(_ probe: ContractData.Probe) -> Bool {
        let contract = TurnContract(mode: TurnMode(rawValue: probe.mode) ?? .talk, contract: self,
                                    heard: probe.heard ?? "")
        return contract.finish(probe.reply).record.rules.contains(probe.rule)
    }
}

/// FNV-1a 64 of the bytes as 16 hex digits: the contract data hash in every turn record.
func fnv1a(_ bytes: Data) -> String {
    let hash = bytes.reduce(UInt64(0xcbf2_9ce4_8422_2325)) { ($0 ^ UInt64($1)) &* 0x100_0000_01b3 }
    let hex = String(hash, radix: 16)
    return String(repeating: "0", count: 16 - hex.count) + hex
}
