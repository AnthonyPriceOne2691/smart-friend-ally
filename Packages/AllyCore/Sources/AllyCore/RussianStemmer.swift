/// Snowball's Russian stemmer (snowballstem.org, BSD-3 — Martin Porter, Richard Boulton, Olly Betts), ported from the
/// published algorithm. Suffixes come off the end inside RV, the part after the first vowel: perfective gerund, else an
/// optional reflexive and then adjectival, verb or noun; then «и»; «ост(ь)» only inside R2; then «нн», superlative and
/// «ь». Of a suffix list the longest match decides; a failed condition does not fall back to a shorter one (`among`).
/// Input — a lower-case word with «ё» already «е».
enum RussianStemmer {
    private typealias Suffixes = [[Character]]

    private static let vowels = Set("аеиоуыэюя")
    private static let gerund = groups(["в", "вши", "вшись"], ["ив", "ивши", "ившись", "ыв", "ывши", "ывшись"])
    private static let adjective = groups([
        "ее", "ие", "ые", "ое", "ими", "ыми", "ей", "ий", "ый", "ой", "ем", "им", "ым", "ом", "его", "ого", "ему",
        "ому", "их", "ых", "ую", "юю", "ая", "яя", "ою", "ею"
    ])
    private static let participle = groups(["ем", "нн", "вш", "ющ", "щ"], ["ивш", "ывш", "ующ"])
    private static let reflexive = groups(["ся", "сь"])
    private static let verb = groups(
        ["ла", "на", "ете", "йте", "ли", "й", "л", "ем", "н", "ло", "но", "ет", "ют", "ны", "ть", "ешь", "нно"],
        ["ила", "ыла", "ена", "ейте", "уйте", "ите", "или", "ыли", "ей", "уй", "ил", "ыл", "им", "ым", "ен", "ило",
         "ыло", "ено", "ят", "ует", "уют", "ит", "ыт", "ены", "ить", "ыть", "ишь", "ую", "ю"]
    )
    private static let noun = groups([
        "а", "ев", "ов", "ие", "ье", "е", "иями", "ями", "ами", "еи", "ии", "и", "ией", "ей", "ой", "ий", "й", "иям",
        "ям", "ием", "ем", "ам", "ом", "о", "у", "ах", "иях", "ях", "ы", "ь", "ию", "ью", "ю", "ия", "ья", "я"
    ])
    private static let iEnding = groups(["и"]), derivational = groups(["ост", "ость"])
    private static let superlative = groups(["ейш", "ейше"])

    static func stem(_ word: String) -> String {
        var letters = Array(word)
        let (rv, r2) = regions(letters)
        guard rv < letters.count else { return word }
        if !strip(&letters, rv, gerund, firstAfterAOrYa: true) {
            _ = strip(&letters, rv, reflexive)
            if strip(&letters, rv, adjective) {
                _ = strip(&letters, rv, participle, firstAfterAOrYa: true)
            } else if !strip(&letters, rv, verb, firstAfterAOrYa: true) {
                _ = strip(&letters, rv, noun)
            }
        }
        _ = strip(&letters, rv, iEnding)
        if let found = longest(letters, rv, derivational), letters.count - found.count >= r2 {
            letters.removeLast(found.count)
        }
        tidy(&letters, rv)
        return String(letters)
    }

    /// Step 4: a superlative goes, then «нн» → «н»; or «нн» → «н»; or «ь» goes.
    private static func tidy(_ letters: inout [Character], _ rv: Int) {
        if strip(&letters, rv, superlative) || ends(letters, rv, Array("нн")) {
            if ends(letters, rv, Array("нн")) { letters.removeLast() }
        } else if ends(letters, rv, ["ь"]) {
            letters.removeLast()
        }
    }

    /// RV starts after the first vowel; R2 after a non-vowel that follows a vowel, twice (Snowball's `mark_regions`).
    private static func regions(_ letters: [Character]) -> (rv: Int, r2: Int) {
        var index = 0
        func past(vowel: Bool) -> Bool {
            while index < letters.count {
                defer { index += 1 }
                if vowels.contains(letters[index]) == vowel { return true }
            }
            return false
        }
        guard past(vowel: true) else { return (letters.count, letters.count) }
        let rv = index
        let found = past(vowel: false) && past(vowel: true) && past(vowel: false)
        return (rv, found ? index : letters.count)
    }

    /// Removes the longest suffix of the groups inside RV; one of group 0 only after «а» or «я», which stays.
    private static func strip(_ letters: inout [Character], _ rv: Int, _ suffixes: [Suffixes],
                              firstAfterAOrYa: Bool = false) -> Bool {
        guard let found = longest(letters, rv, suffixes) else { return false }
        let start = letters.count - found.count
        if firstAfterAOrYa, found.group == 0 {
            guard start > rv, letters[start - 1] == "а" || letters[start - 1] == "я" else { return false }
        }
        letters.removeLast(found.count)
        return true
    }

    private static func longest(_ letters: [Character], _ rv: Int, _ suffixes: [Suffixes])
        -> (count: Int, group: Int)? {
        var best: (count: Int, group: Int)?
        for (group, list) in suffixes.enumerated() {
            for suffix in list where suffix.count > (best?.count ?? 0) && ends(letters, rv, suffix) {
                best = (suffix.count, group)
            }
        }
        return best
    }

    private static func ends(_ letters: [Character], _ rv: Int, _ suffix: [Character]) -> Bool {
        suffix.count <= letters.count - rv && letters.suffix(suffix.count).elementsEqual(suffix)
    }

    private static func groups(_ lists: [String]...) -> [Suffixes] { lists.map { $0.map(Array.init) } }
}
