import Foundation

/// Her name and her brothers' names from the memory, read at each wake (memory-forget, M42); none — nothing is counted
/// by name, the word «брат» still is.
public struct FamilyNames: Equatable, Sendable {
    public let her: String?, brothers: [String]

    public init(her: String? = nil, brothers: [String] = []) { (self.her, self.brothers) = (her, brothers) }
}

/// `window.json`, one copy: the brother's stem, a name's endings, how often.
struct WindowData: Decodable, Sendable {
    let brother: String, endings: [String], brotherMost: Int, nameShare: Int

    static let shared: WindowData = {
        guard let url = Bundle.module.url(forResource: "window", withExtension: "json"),
              let bytes = try? Data(contentsOf: url) else { fatalError("AllyCore: window.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(WindowData.self, from: bytes)
        } catch {
            fatalError("AllyCore: window.json does not decode: \(error)")
        }
    }()

    /// A name's forms as one alternation, longest first: the name and its stem with the endings, «е» for «ё» too.
    func forms(_ name: String) -> String {
        let base = name.lowercased().replacingOccurrences(of: "ё", with: "е")
        let stem = ["а", "я", "ь", "й"].contains(base.last.map(String.init) ?? "") ? String(base.dropLast()) : base
        return Set([base] + endings.map { stem + $0 }).sorted { ($0.count, $0) > ($1.count, $1) }
            .map { NSRegularExpression.escapedPattern(for: $0).replacingOccurrences(of: "е", with: "[её]") }
            .joined(separator: "|")
    }
}

/// What one turn may say (M42): her name goes as an address — and a sentence still naming her goes — while one more
/// reply with it would pass the share; past the most replies in which Elly raised the brother, a sentence about him
/// goes, unless she speaks of him this turn. Applied to the model's text before the contract: what goes is never said
/// and never reaches the model's memory (D5).
public struct TurnWindow: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    public static let open = TurnWindow(addresses: [], drops: [])
    let addresses: [NSRegularExpression], drops: [NSRegularExpression]

    /// The text without her name's addresses and without the sentences this turn may not say.
    func apply(_ text: String) -> String {
        guard !addresses.isEmpty || !drops.isEmpty else { return text }
        let stripped = addresses.reduce(text) { out, pattern in
            pattern.stringByReplacingMatches(in: out, range: Self.whole(out), withTemplate: "")
        }
        let string = NSString(string: stripped)
        let pieces = Self.sentence.matches(in: stripped, range: Self.whole(stripped))
            .map { string.substring(with: $0.range) }
        let kept = pieces.filter { piece in !drops.contains { Self.found($0, in: piece) } }
        return kept.count == pieces.count ? stripped : kept.joined()
    }

    static let sentence = regex("[^.!?…]+(?:[.!?…]+\\s*|$)")

    /// An alternation as whole words.
    static func word(_ alternation: String) -> String { "(?<!\\p{L})(?:\(alternation))(?!\\p{L})" }

    static func regex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            fatalError("AllyCore: window pattern \(pattern) does not compile: \(error)")
        }
    }

    static func found(_ pattern: NSRegularExpression, in text: String) -> Bool {
        pattern.firstMatch(in: text, range: whole(text)) != nil
    }

    static func whole(_ text: String) -> NSRange { NSRange(location: 0, length: text.utf16.count) }
}

/// The session's count (M42): Elly's replies, those that named her, those in which she raised the brother herself.
struct WindowCount: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    private let data = WindowData.shared, her: String?, name: NSRegularExpression?, brother: NSRegularExpression
    private(set) var replies = 0, named = 0, raised = 0

    init(names: FamilyNames = FamilyNames()) {
        let data = WindowData.shared, her = names.her.map(data.forms)
        let brothers = ["\(data.brother)\\p{L}*"] + names.brothers.map(data.forms)
        (self.her, name) = (her, her.map { TurnWindow.regex(TurnWindow.word($0)) })
        brother = TurnWindow.regex(TurnWindow.word(brothers.joined(separator: "|")))
    }

    /// What this turn may say: her name — while one more reply with it stays within the share; the brother — past the
    /// most only when she speaks of him herself.
    func window(heard: String) -> TurnWindow {
        var addresses: [NSRegularExpression] = [], drops: [NSRegularExpression] = []
        if let her, let name, (named + 1) * data.nameShare > replies + 1 {
            let called = "(?:\(her))(?!\\p{L})"
            addresses = [TurnWindow.regex("(^|(?<=[.!?…]\\s))\(called)\\s*[,!]\\s*"),
                         TurnWindow.regex(",\\s*\(called)(?=\\s*[,!?.…])")]
            drops.append(name)
        }
        if raised >= data.brotherMost, !TurnWindow.found(brother, in: heard) { drops.append(brother) }
        return TurnWindow(addresses: addresses, drops: drops)
    }

    /// One reply said: counted — with her name, with the brother she did not bring up herself.
    mutating func count(said: [String], heard: String) {
        let text = said.joined(separator: " ")
        replies += 1
        named += name.map { TurnWindow.found($0, in: text) ? 1 : 0 } ?? 0
        raised += TurnWindow.found(brother, in: text) && !TurnWindow.found(brother, in: heard) ? 1 : 0
    }
}
