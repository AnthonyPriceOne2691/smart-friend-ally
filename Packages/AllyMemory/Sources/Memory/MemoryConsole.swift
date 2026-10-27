import AllySQLite
import Foundation

/// What the parent's console says about the memory (M39, П22): erased at …, knows nothing, N facts; talks waiting for
/// the parse; a parse that failed — words of `memory.json`.
public enum MemoryConsole {
    /// The memory's lines now: its state, then the queue and a failure when there are any.
    public static func lines(_ store: MemoryStore, zone: TimeZone) throws -> [String] {
        let words = Words.shared.console, facts = try store.facts().count, waiting = try store.waiting()
        var lines = [facts > 0 ? count(words.facts, facts)
                     : try store.wipeEpoch().map { erased($0, zone, words.erased) } ?? words.nothing]
        if waiting > 0 { lines.append(words.waiting.replacingOccurrences(of: "{n}", with: "\(waiting)")) }
        if try store.db.rows("SELECT 1 FROM meta WHERE key = 'failed'").isEmpty == false { lines.append(words.failed) }
        return lines
    }

    /// The console's line while the block is off (`in_conversation`, the parent 2026-10-28): she keeps her memory, the
    /// conversation does not get it.
    public static var conversation: String? { MemoryBlock.inConversation ? nil : Words.shared.console.off }

    /// «Стереть всё, что помнит Элли? (14 фактов)».
    public static func confirmation(facts: Int) -> String { count(Words.shared.console.confirm, facts) }

    /// A template with `{n}` and `{facts}` in the right form: 1 факт, 2 факта, 5 фактов, 21 факт.
    static func count(_ template: String, _ count: Int) -> String {
        let forms = Words.shared.console.forms, tens = count % 100, ones = count % 10
        let form = ones == 1 && tens != 11 ? 0 : (2...4).contains(ones) && !(12...14).contains(tens) ? 1 : 2
        return template.replacingOccurrences(of: "{n}", with: "\(count)")
            .replacingOccurrences(of: "{facts}", with: forms[min(form, forms.count - 1)])
    }

    private static func erased(_ moment: Date, _ zone: TimeZone, _ template: String) -> String {
        let format = DateFormatter()
        (format.locale, format.timeZone) = (Locale(identifier: "ru_RU"), zone)
        format.dateFormat = "dd.MM"
        let date = format.string(from: moment)
        format.dateFormat = "HH:mm"
        return template.replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: format.string(from: moment))
    }
}
