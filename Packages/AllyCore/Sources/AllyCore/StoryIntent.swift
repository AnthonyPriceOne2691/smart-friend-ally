import Discipline
import Foundation

/// What she asks for by her words: a tale or making something up together — code, not the model (story-mode).
public enum StoryKind: String, Sendable { case story, invent }

/// The bridge of a turn: its kind, its signed words and its number in the circle, from 1.
public struct StoryBridge: Equatable, Sendable {
    public let kind: StoryKind, text: String, number: Int
}

/// `story.json`, one copy.
struct StoryData: Decodable, Sendable {
    struct Probe: Decodable, Sendable { let text, want: String }
    struct Off: Decodable, Sendable { let line, bridge, rule: String }

    let ask, object, notStory, inventGame: String
    var story: [String], invent: [String], bridges: [String: [String]]
    let exchanges: Int, selftest: [Probe], off: Off

    static let shared: StoryData = {
        guard let url = Bundle.module.url(forResource: "story", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: story.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(StoryData.self, from: bytes)
        } catch {
            fatalError("AllyCore: story.json does not decode: \(error)")
        }
    }()
}

/// The rule of her words and the bridges (the story and invent branches of `intent.py` of bake-off 2), asked only on a
/// clean «pass» of the router. Her words go normalized, so `\w` and `\b` of the patterns mean what they mean there.
/// A probe of the rule or a bridge that does not pass the contract of `story` word for word turns the mode off.
public struct StoryIntent: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    public static let shared = StoryIntent(.shared)

    let data: StoryData
    private let story, invent, notStory, inventGame: [NSRegularExpression]

    /// Why the mode is off, as the console writes it; nil — it may run.
    public let off: String?

    public var healthy: Bool { off == nil }

    /// How many last exchanges of the session the model of tales reads.
    public var exchanges: Int { data.exchanges }

    init(_ data: StoryData) {
        self.data = data
        let fill = { (pattern: String) in
            pattern.replacingOccurrences(of: "{ask}", with: data.ask)
                .replacingOccurrences(of: "{object}", with: data.object)
        }
        let compile = { (patterns: [String]) in patterns.compactMap { try? NSRegularExpression(pattern: fill($0)) } }
        (story, invent) = (compile(data.story), compile(data.invent))
        (notStory, inventGame) = (compile([data.notStory]), compile([data.inventGame]))
        let compiled = story.count == data.story.count && invent.count == data.invent.count
            && notStory.count == 1 && inventGame.count == 1
        let (story, invent, notStory, inventGame) = (story, invent, notStory, inventGame)
        let kind = { (text: String) in Self.kind(of: text, story, invent, notStory, inventGame) }
        let rule = compiled && data.selftest.allSatisfy { (kind($0.text)?.rawValue ?? "none") == $0.want }
        let reason = !rule ? data.off.rule : Self.pass(data.bridges) ? nil : data.off.bridge
        off = reason.map { data.off.line.replacingOccurrences(of: "{reason}", with: $0) }
    }

    /// Her words as the rule reads them; nil — neither a tale nor making up.
    public func kind(of utterance: String) -> StoryKind? {
        Self.kind(of: utterance, story, invent, notStory, inventGame)
    }

    /// The bridge of the turn of this kind counted from 0, in a circle.
    public func bridge(_ kind: StoryKind, turn: Int) -> StoryBridge? {
        guard let words = data.bridges[kind.rawValue], !words.isEmpty else { return nil }
        let index = turn % words.count
        return StoryBridge(kind: kind, text: words[index], number: index + 1)
    }

    private static func kind(of utterance: String, _ story: [NSRegularExpression], _ invent: [NSRegularExpression],
                             _ notStory: [NSRegularExpression], _ inventGame: [NSRegularExpression]) -> StoryKind? {
        let text = normalized(utterance)
        if invent.contains(where: { found($0, in: text) }) {
            return inventGame.contains { found($0, in: text) } ? nil : .invent
        }
        guard story.contains(where: { found($0, in: text) }), !notStory.contains(where: { found($0, in: text) }) else {
            return nil
        }
        return .story
    }

    /// Lower case, «ё» as «е», no ъ and ь, what is not a letter of the alphabets or a digit — a space.
    static func normalized(_ text: String) -> String {
        let plain = text.lowercased().replacingOccurrences(of: "ё", with: "е").unicodeScalars
            .filter { $0 != "ъ" && $0 != "ь" }
            .map { (0x0430...0x044F).contains($0.value) || (0x61...0x7A).contains($0.value)
                || (0x30...0x39).contains($0.value) ? Character($0) : " " }
        return String(plain).split(separator: " ").joined(separator: " ")
    }

    private static func found(_ pattern: NSRegularExpression, in text: String) -> Bool {
        pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func pass(_ bridges: [String: [String]]) -> Bool {
        let kinds = [StoryKind.story, .invent].map { bridges[$0.rawValue] ?? [] }
        return kinds.allSatisfy { !$0.isEmpty } && kinds.joined().allSatisfy { bridge in
            let turn = TurnContract(mode: .story).finish(bridge)
            return turn.source == .model && turn.record.rules.isEmpty && turn.sentences.joined(separator: " ") == bridge
        }
    }
}
