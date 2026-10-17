import Foundation

/// One change the repair made: the rule id and what the rule saw.
public struct RepairAction: Equatable, Sendable {
    public let rule: String
    public let detail: String
}

/// The repaired text and every action, in the order taken.
public struct Repaired: Equatable, Sendable {
    public let text: String
    public let actions: [RepairAction]
}

/// Repairs a model reply before speech synthesis. A port of the Python reference (outside git): `strip_markup`,
/// `symbols_to_words`, `latin_to_cyrillic`, `digits_to_words` (local/spike/discipline/output_filter.py) and
/// `strip_endearments` (local/spike/persona-v2/judge_sheet.py). Placeholders go first, or the bracket step of
/// markup leaves a stray comma; `phone_like` reports the `⟦PHONE⟧` marks of `digits` and changes no text.
public enum Repair {
    /// - Parameter disabled: rule ids to switch off (ablation tests).
    public static func apply(_ text: String, disabled: Set<String> = []) -> Repaired {
        var pass = Pass(rules: .shared, disabled: disabled)
        var out = pass.placeholders(text)
        out = pass.markup(out)
        out = pass.symbols(out)
        out = pass.latin(out)
        out = pass.digits(out)
        out = pass.endearments(out)
        return Repaired(text: pass.finish(out), actions: pass.actions)
    }
}

/// Rule ids of the contract, in pipeline order.
enum Rule: String, CaseIterable {
    case placeholder, markup, emoji, symbols, latin, digits, phoneLike = "phone_like", endearment
}

/// One run of the pipeline: the rules switched off and the actions taken so far.
struct Pass {
    let rules: Rules
    let disabled: Set<String>
    var actions: [RepairAction] = []

    func isOn(_ rule: Rule) -> Bool { !disabled.contains(rule.rawValue) }

    mutating func log(_ rule: Rule, _ detail: String) {
        actions.append(RepairAction(rule: rule.rawValue, detail: detail))
    }

    /// Replaces every match of `pattern` with `template`, logging each matched fragment.
    mutating func cut(_ pattern: Pattern, _ text: String, as rule: Rule, with template: String = "") -> String {
        guard isOn(rule) else { return text }
        let found = pattern.matches(in: text)
        for fragment in found { log(rule, rules.strip(fragment)) }
        return found.isEmpty ? text : pattern.replacing(in: text, with: template)
    }
}
