import Foundation

extension Pass {
    /// `placeholder`: «[Имя девочки]» with the comma before it (judge_sheet.PLACEHOLDER).
    mutating func placeholders(_ text: String) -> String { cut(rules.placeholder, text, as: .placeholder) }

    /// `markup`, `emoji` (strip_markup): thinking, emoji, urls, list markers, markdown, asides; lines → sentences.
    mutating func markup(_ text: String) -> String {
        var out = cut(rules.thinking, text, as: .markup, with: " ")
        out = cut(rules.emoji, out, as: .emoji)
        out = cut(rules.url, out, as: .markup)
        out = cut(rules.list, out, as: .markup)
        out = markdown(out)
        out = brackets(out)
        out = lines(out)
        return rules.collapse(rules.spaceBeforePunct.replacing(in: out, with: "$1"))
    }

    private mutating func markdown(_ text: String) -> String {
        guard isOn(.markup) else { return text }
        let out = rules.markdown.reduce(text) { $1.0.replacing(in: $0, with: $1.1) }
        if out != text { log(.markup, "markdown") }
        return out
    }

    private mutating func brackets(_ text: String) -> String {
        guard isOn(.markup), rules.bracket.found(in: text) else { return text }
        log(.markup, "brackets")
        return rules.bracket.replacing(in: rules.bracketGroup.replacing(in: text, with: " "), with: " ")
    }

    /// A line without an ending gets a period, a line without a word goes; logged when more than whitespace changes.
    private mutating func lines(_ text: String) -> String {
        guard isOn(.markup) else { return text }
        var lines = text.unicodeScalars.split(separator: "\n", omittingEmptySubsequences: false)
            .map { rules.strip(String($0)) }
            .filter { rules.wordChar.found(in: $0) }
        if lines.count > 1 { lines = lines.map { rules.sentenceEnd.found(in: $0) ? $0 : $0 + "." } }
        let out = lines.joined(separator: " ")
        if rules.collapse(out) != rules.collapse(text) { log(.markup, "lines") }
        return out
    }

    /// `endearment` (strip_endearments): adult endearments where the girl is addressed, a lone «Ты моя хорошая!».
    mutating func endearments(_ text: String) -> String {
        rules.endearments.reduce(text) { out, pattern in cut(pattern, out, as: .endearment) }
    }

    /// Always, as strip_endearments does: sentences start with a capital, whitespace is single.
    func finish(_ text: String) -> String {
        let out = rules.sentenceStart.replacing(in: text) { $0[1] + $0[2].uppercased() }
        return rules.strip(rules.multiSpace.replacing(in: out, with: " "))
    }
}
