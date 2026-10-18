import Foundation

extension Pass {
    /// `symbols` (symbols_to_words): + = × ÷ % № & ° and a spoken minus become words, other signs a space.
    mutating func symbols(_ text: String) -> String {
        guard isOn(.symbols) else { return text }
        let out = rules.symbols.reduce(text) { $1.0.replacing(in: $0, with: $1.1) }
        if out != text { log(.symbols, text) }
        return rules.collapse(out)
    }

    /// `latin` (latin_to_cyrillic): Latin letters become Cyrillic.
    mutating func latin(_ text: String) -> String {
        guard isOn(.latin), rules.latinLetter.found(in: text) else { return text }
        let rules = self.rules
        let split = rules.camelCase.replacing(in: text, with: " ")
        log(.latin, split)
        return rules.collapse(rules.letters.replacing(in: split) { rules.cyrillic(word: $0[0]) })
    }

    /// strip_cjk, right after latin: CJK characters go, logged as `latin` like the reference.
    mutating func cjk(_ text: String) -> String {
        guard rules.cjk.found(in: text) else { return text }
        log(.latin, "cjk removed")
        return rules.cjk.replacing(in: text, with: "")
    }

    /// `digits` (digits_to_words): numbers become words, a phone-like run the mark; `phone_like` reports each mark.
    /// A count goes first, so «5 4 3 2 1» is read, not marked.
    mutating func digits(_ text: String) -> String {
        guard isOn(.digits), rules.digit.found(in: text) else { return text }
        let rules = self.rules
        var marks: [Int] = []
        var out = rules.counting.replacing(in: text) { rules.countWords($0[0]) }
        out = rules.phone.replacing(in: out) { groups in
            let count = rules.digit.matches(in: groups[0]).count
            guard count >= 5 else { return groups[0] }
            marks.append(count)
            return rules.phoneMark
        }
        out = rules.longRun.replacing(in: out) { groups in
            marks.append(groups[0].unicodeScalars.count)
            return rules.phoneMark
        }
        out = rules.numberSteps.reduce(out) { $1.0.replacing(in: $0, with: $1.1) }
        log(.digits, out)
        for count in marks where isOn(.phoneLike) { log(.phoneLike, "\(count) digits") }
        return rules.collapse(rules.digitRun.replacing(in: out) { rules.numberWords($0[0]) })
    }
}

extension Rules {
    /// latin_word: a Latin word goes by the dictionary, else by transliteration; inside a Cyrillic word a Latin
    /// letter is a look-alike or a slip («угаdala»); a run over 15 letters is dropped.
    func cyrillic(word: String) -> String {
        guard latinLetter.found(in: word) else { return word }
        guard word.unicodeScalars.count <= 15 else { return "" }
        if cyrillicLetter.found(in: word) {
            return word.map { homoglyph[$0] ?? ($0.isASCII && $0.isLetter ? transliterate(String($0)) : String($0)) }
                .joined()
        }
        let spoken = enWords[word.lowercased()] ?? transliterate(word)
        return word.first?.isUppercase == true ? spoken.prefix(1).uppercased() + spoken.dropFirst() : spoken
    }

    /// translit_ru: at each position the first table entry that fits wins.
    func transliterate(_ word: String) -> String {
        var rest = Substring(word.lowercased()), out = ""
        while !rest.isEmpty {
            let entry = translit.first { rest.hasPrefix($0.latin) }
            out += entry?.cyrillic ?? ""
            rest = rest.dropFirst(entry?.latin.count ?? 1)
        }
        return out
    }

    /// count_words: three or more numbers of up to two digits, each one more (or each one less) than the one before,
    /// become words; anything else («7 7 7 1 2») stays for the phone check.
    func countWords(_ run: String) -> String {
        let values = digitRun.matches(in: run).map { digits in
            digits.compactMap(\.wholeNumberValue).reduce(0) { $0 * 10 + $1 }
        }
        let steps = Set(zip(values, values.dropFirst()).map { $1 - $0 })
        return steps == [1] || steps == [-1] ? digitRun.replacing(in: run) { numberWords($0[0]) } : run
    }

    /// number_words (runs of up to four digits reach it); past six, where the reference would raise, digit by digit.
    func numberWords(_ digits: String) -> String {
        let values = digits.compactMap(\.wholeNumberValue).drop { $0 == 0 }
        guard values.count <= 6 else { return values.map { numbers.units[$0] }.joined(separator: " ") }
        let value = values.reduce(0) { $0 * 10 + $1 }
        guard value >= 1000 else { return underThousand(value).joined(separator: " ") }
        let (thousands, rest) = value.quotientAndRemainder(dividingBy: 1000)
        let last = thousands % 10
        let form = (10...20).contains(thousands % 100) || last == 0 || last >= 5 ? 2 : (last == 1 ? 0 : 1)
        let head = thousands == 1 ? [] : underThousand(thousands, feminine: true)
        return (head + [numbers.thousand[form]] + (rest > 0 ? underThousand(rest) : [])).joined(separator: " ")
    }

    /// under_thousand; `feminine` gives «одна», «две» before «тысяча».
    func underThousand(_ value: Int, feminine: Bool = false) -> [String] {
        let rest = value % 100
        var words = value >= 100 ? [numbers.hundreds[value / 100]] : []
        if rest >= 20 {
            words += [numbers.tens[rest / 10]] + (rest % 10 > 0 ? [numbers.units[rest % 10]] : [])
        } else if rest >= 10 {
            words.append(numbers.teens[rest - 10])
        } else if rest > 0 || words.isEmpty {
            words.append(numbers.units[rest])
        }
        if feminine, let last = words.last, let female = numbers.feminine[last] { words[words.count - 1] = female }
        return words
    }
}
