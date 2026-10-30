import Discipline
import Foundation

/// What she asks for by her words: a tale or making something up together — code, not the model (story-mode).
public enum StoryKind: String, Encodable, Sendable { case story, invent }

/// The bridge of a turn: its kind, its signed words and its number in the circle, from 1. Its record has no words.
public struct StoryBridge: Equatable, Encodable, Sendable {
    public let kind: StoryKind, text: String, number: Int

    private enum CodingKeys: String, CodingKey { case kind = "intent", number = "bridge" }
}

/// `story.json`, one copy.
struct StoryData: Decodable, Sendable {
    let ask, object, notStory, inventGame: String
    var story: [String], invent: [String], bridges: [String: [String]]
    let exchanges: Int, selftest: [String: [String]]

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
    private let rule: StoryRule

    /// The rule's probes and the bridges passed: the mode may run.
    public let healthy: Bool

    /// How many last exchanges of the session the model of tales reads.
    public var exchanges: Int { data.exchanges }

    init(_ data: StoryData) {
        let rule = StoryRule(data)
        (self.data, self.rule) = (data, rule)
        healthy = Self.pass(data.bridges) && data.selftest.allSatisfy { want, texts in
            texts.allSatisfy { (rule.kind(of: $0)?.rawValue ?? "none") == want }
        }
    }

    /// Her words as the rule reads them; nil — neither a tale nor making up.
    public func kind(of utterance: String) -> StoryKind? { rule.kind(of: utterance) }

    /// The bridge of the turn of this kind counted from 0, in a circle.
    public func bridge(_ kind: StoryKind, turn: Int) -> StoryBridge? {
        guard let words = data.bridges[kind.rawValue], !words.isEmpty else { return nil }
        let index = turn % words.count
        return StoryBridge(kind: kind, text: words[index], number: index + 1)
    }

    /// Lower case, «ё» as «е», no ъ and ь, what is not a letter of the alphabets or a digit — a space.
    static func normalized(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: "ё", with: "е").replacingOccurrences(of: "[ъь]", with: "",
                                                                                    options: .regularExpression)
            .replacingOccurrences(of: "[^а-яa-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func pass(_ bridges: [String: [String]]) -> Bool {
        let kinds = [StoryKind.story, .invent].map { bridges[$0.rawValue] ?? [] }
        return kinds.allSatisfy { !$0.isEmpty } && kinds.joined().allSatisfy { bridge in
            let turn = TurnContract(mode: .story).finish(bridge)
            return turn.source == .model && turn.record.rules.isEmpty && turn.sentences.joined(separator: " ") == bridge
        }
    }
}

/// The patterns of `story.json`, compiled.
private struct StoryRule: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    let story, invent, notStory, inventGame: [NSRegularExpression]

    /// A pattern that does not compile is no pattern: the probes of the rule catch it.
    init(_ data: StoryData) {
        let compile = { (patterns: [String]) in
            patterns.compactMap {
                try? NSRegularExpression(pattern: $0.replacingOccurrences(of: "{ask}", with: data.ask)
                    .replacingOccurrences(of: "{object}", with: data.object))
            }
        }
        (story, invent) = (compile(data.story), compile(data.invent))
        (notStory, inventGame) = (compile([data.notStory]), compile([data.inventGame]))
    }

    func kind(of utterance: String) -> StoryKind? {
        let text = StoryIntent.normalized(utterance)
        let found = { (patterns: [NSRegularExpression]) in
            patterns.contains { $0.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil }
        }
        if found(invent) { return found(inventGame) ? nil : .invent }
        return found(story) && !found(notStory) ? .story : nil
    }
}
