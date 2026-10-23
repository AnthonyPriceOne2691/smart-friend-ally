import Foundation

/// Слово после таблицы: что с ним сделали — для следа без слов.
struct Respelled {
    var word: SpokenWord
    var pinned = false
    var respelled = false
}

extension SpeechTextTable {
    /// Слово ответа расстановщика → слово для голоса. Запись имени заменяет его целиком, правила чтения её не трогают;
    /// закреплённое ударение заменяет номер ударной и «ё», поставленную расстановщиком; правила чтения меняют буквы,
    /// номер ударной — тот же.
    func respell(_ word: SpokenWord) -> Respelled {
        let key = word.letters.lowercased()
        if let name = names[key] {
            let letters = SpokenWord.cased(name.letters, like: word.letters)
            return Respelled(word: SpokenWord(letters: letters, stress: name.stress), pinned: true)
        }
        var out = Respelled(word: word)
        if let pinned = stress[Self.plain(key)] {
            out.word = SpokenWord(letters: SpokenWord.cased(pinned.letters, like: word.letters), stress: pinned.stress)
            out.pinned = true
        }
        let base = out.word.letters.lowercased()
        let spelled = spelling(base, stressedLast: out.word.stress == out.word.vowelCount - 1)
        if spelled != base {
            out.word.letters = SpokenWord.cased(spelled, like: word.letters)
            out.respelled = true
        }
        return out
    }

    /// Правила чтения над словом строчными: слово целиком — иначе самое длинное окончание вне исключений и сочетания
    /// букв. Безударный конец — и при неизвестном ударении: так у прилагательных, большинства слов на -ого/-его.
    func spelling(_ key: String, stressedLast: Bool) -> String {
        if let whole = words[key] { return whole }
        var text = key
        if let rule = endings.first(where: { key.hasSuffix($0.end) && !($0.except ?? []).contains(key) }) {
            text = String(key.dropLast(rule.end.count)) + (stressedLast ? rule.to : rule.unstressed ?? rule.to)
        }
        for (from, to) in parts {
            text = text.replacingOccurrences(of: from, with: to)
        }
        return text
    }
}
