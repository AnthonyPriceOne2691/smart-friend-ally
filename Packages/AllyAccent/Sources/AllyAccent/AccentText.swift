import Foundation

/// Текст RUAccent 1.5.8.3 — как в Python, на скалярах Unicode вместо индексов `str`: фильтр `normalize`, предложения,
/// `split_by_words`, склейка, `delete_spaces_before_punc`, `fix_capital`.
enum AccentText {
    /// Знаки, которые оставляет регулярка `normalize`, кроме букв, цифр и пробельных. Двойной кавычки в ней нет:
    /// литералы Python `r"…;"` и `"''(){}…"` склеились, и знак выпал.
    static let kept = Set("—.,!?:;'(){}[]«»„“”-".unicodeScalars)
    /// Знаки `delete_spaces_before_punc` в порядке Python: замены идут по одному проходу на знак.
    static let punctuation = ##"!"#$%&'()*,./:;<=>?@[\]^_`{|}-"##

    /// `\s` Python: пробельные Unicode и разделители U+001C–U+001F.
    static func isSpace(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.isWhitespace || (0x1C...0x1F).contains(scalar.value)
    }

    /// Буквы и цифры фильтра: a–z, A–Z, 0–9, а–я, А–Я, ё, Ё. После фильтра это и есть `\w` разбиения на слова.
    static func isLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x401, 0x410...0x44F, 0x451: true
        default: false
        }
    }

    static func string(_ scalars: [Unicode.Scalar]) -> String {
        String(String.UnicodeScalarView(scalars))
    }

    static func normalize(_ text: String) -> String {
        string(text.unicodeScalars.filter { isLetter($0) || isSpace($0) || kept.contains($0) })
    }

    /// Предложения: конец — «.», «!» или «?» перед пробельным. Пробельные между предложениями уходят к следующему,
    /// хвост из пробельных — к последнему, как у razdel на фразах стенда; фраза из пробельных — ни одного предложения.
    static func sentences(_ text: String) -> [String] {
        let scalars = Array(text.unicodeScalars)
        guard scalars.contains(where: { !isSpace($0) }) else { return [] }
        var pieces: [[Unicode.Scalar]] = [[]]
        for (index, scalar) in scalars.enumerated() {
            pieces[pieces.count - 1].append(scalar)
            if ".!?".unicodeScalars.contains(scalar), index + 1 < scalars.count, isSpace(scalars[index + 1]) {
                pieces.append([])
            }
        }
        if pieces.count > 1, pieces[pieces.count - 1].allSatisfy(isSpace) {
            let tail = pieces.removeLast()
            pieces[pieces.count - 1] += tail
        }
        return pieces.map(string)
    }

    /// `split_by_words`: слово — серия букв и цифр или серия прочих знаков, между словами — пробельные; « - » сначала
    /// становится « ~ ». Промежутков на один больше, чем слов: до первого, между словами, после последнего.
    static func words(_ sentence: String) -> (words: [String], gaps: [String]) {
        var words: [[Unicode.Scalar]] = [], gaps: [[Unicode.Scalar]] = [[]]
        var previous: Unicode.Scalar?
        for scalar in sentence.replacing(" - ", with: " ~ ").unicodeScalars {
            if isSpace(scalar) {
                gaps[gaps.count - 1].append(scalar)
            } else if let last = previous, !isSpace(last), isLetter(last) == isLetter(scalar) {
                words[words.count - 1].append(scalar)
            } else {
                words.append([scalar])
                gaps.append([])
            }
            previous = scalar
        }
        return (words.map(string), gaps.map(string))
    }

    /// Склейка: промежуток и слово по порядку, хвост — затем `delete_spaces_before_punc`.
    static func join(_ words: [String], _ gaps: [String]) -> String {
        deleteSpacesBeforePunc(zip(gaps, words).map { $0 + $1 }.joined() + (gaps.last ?? ""))
    }

    /// `delete_spaces_before_punc`: на каждый знак — один проход замены « x» → «x», у «-» до него ещё « -» и «- »;
    /// в конце «~» → «-».
    static func deleteSpacesBeforePunc(_ text: String) -> String {
        var out = text
        for mark in punctuation {
            if mark == "-" {
                out = out.replacing(" -", with: "-").replacing("- ", with: "-")
            }
            out = out.replacing(" \(mark)", with: "\(mark)")
        }
        return out.replacing("~", with: "-")
    }

    /// `fix_capital`: при равной длине — регистр каждого скаляра как в исходном слове, иначе цель как есть.
    static func fixCapital(_ source: String, _ target: String) -> String {
        let upper = source.unicodeScalars.map(\.properties.isUppercase)
        let letters = Array(target.unicodeScalars)
        guard upper.count == letters.count else { return target }
        return zip(upper, letters).map { $0 ? String($1).uppercased() : String($1).lowercased() }.joined()
    }
}
