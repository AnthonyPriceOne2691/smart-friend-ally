import Discipline
import Foundation

/// The first sentence of a growing reply, cut only where repair can not move the boundary: end marks, then whitespace
/// and a letter (the next sentence has begun: «! [Имя]?» merges into «!?»), not after a digit («2.5», «1. Кошка»), not
/// inside an open thinking block, and a head that, repaired, keeps a letter and the end mark («www.kot.ru.» loses it).
/// The contract repairs before it splits, so a raw cut loses words; a late cut only delays sentence 1 (A3).
public enum SentenceStream {
    static let marks: Set<Character> = [".", "!", "?", "…"]

    public static func first(in text: String) -> String? {
        let chars = Array(text)
        return ends(chars).lazy.compactMap { safeHead(String(chars[...$0])) }.first
    }

    /// The reply up to the last sentence the next one has begun after, if that goes past `after` characters: what the
    /// contract of a story reads (story-mode). Not inside an aside still open — repair takes a closed one away whole.
    /// Repair runs only on what is new, it would be too much on every token.
    public static func complete(in text: String, after: Int = 0) -> String? {
        let chars = Array(text)
        return ends(chars).reversed().prefix { $0 + 1 > after }.first { end in
            !openAside(chars[...end]) && safeHead(String(chars[...end])) != nil
        }.map { String(chars[...$0]) }
    }

    private static func openAside(_ head: ArraySlice<Character>) -> Bool {
        [("(", ")"), ("[", "]"), ("{", "}")].contains { open, close in
            head.filter { $0 == open }.count > head.filter { $0 == close }.count
        }
    }

    /// Where a sentence may end: the last of its end marks, whitespace and a letter after them, not after a digit.
    private static func ends(_ chars: [Character]) -> [Int] {
        var index = 0, found: [Int] = []
        while index < chars.count {
            guard marks.contains(chars[index]) else {
                index += 1
                continue
            }
            var end = index, next = index + 1
            while next < chars.count, marks.contains(chars[next]) { (end, next) = (next, next + 1) }
            while next < chars.count, chars[next].isWhitespace { next += 1 }
            if next > end + 1, next < chars.count, chars[next].isLetter, index == 0 || !chars[index - 1].isNumber {
                found.append(end)
            }
            index = end + 1
        }
        return found
    }

    static func safeHead(_ head: String) -> String? {
        let low = head.lowercased(), repaired = Repair.apply(head).text
        let thinking = low.contains("<think") && !low.contains("</think")
            || low.contains("<|channel|>") && !low.contains("<|message|>")
        guard !thinking, repaired.contains(where: \.isLetter), let last = repaired.last, marks.contains(last) else {
            return nil
        }
        return head.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
