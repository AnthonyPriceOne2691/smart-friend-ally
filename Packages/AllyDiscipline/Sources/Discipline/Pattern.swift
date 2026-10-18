import Foundation

/// A regular expression compiled once. Lines end only at "\n", as in Python `re`.
struct Pattern: @unchecked Sendable {  // NSRegularExpression is immutable and thread-safe
    private let regex: NSRegularExpression

    init(_ pattern: String, _ options: NSRegularExpression.Options = []) {
        do {
            regex = try NSRegularExpression(pattern: pattern, options: options.union(.useUnixLineSeparators))
        } catch {
            fatalError("Discipline: pattern \(pattern) does not compile: \(error)")
        }
    }

    func found(in text: String) -> Bool { regex.firstMatch(in: text, range: Self.whole(text)) != nil }

    /// Where the matches are, left to right, as UTF-16 ranges.
    func ranges(in text: String) -> [NSRange] { regex.matches(in: text, range: Self.whole(text)).map(\.range) }

    /// The matched fragments, left to right (match ranges are UTF-16 offsets, so they are cut through NSString).
    func matches(in text: String) -> [String] {
        let string = NSString(string: text)
        return regex.matches(in: text, range: Self.whole(text)).map { string.substring(with: $0.range) }
    }

    func replacing(in text: String, with template: String) -> String {  // groups as $1
        regex.stringByReplacingMatches(in: text, range: Self.whole(text), withTemplate: template)
    }

    /// Replaces each match with `transform(groups)`; a group that took no part is "".
    func replacing(in text: String, by transform: ([String]) -> String) -> String {
        let string = NSString(string: text)
        var out = "", end = 0
        for match in regex.matches(in: text, range: Self.whole(text)) {
            let groups = (0..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : string.substring(with: range)
            }
            out += string.substring(with: NSRange(location: end, length: match.range.location - end))
            out += transform(groups)
            end = match.range.location + match.range.length
        }
        return out + string.substring(from: end)
    }

    private static func whole(_ text: String) -> NSRange { NSRange(location: 0, length: text.utf16.count) }
}
