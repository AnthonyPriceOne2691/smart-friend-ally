import Foundation

/// The app's first screens without the lock (child-open; the parent 2026-10-29: «Детский экран открыт всегда», a
/// loading screen while the model warms up, «А потом раз и появляется Элли»): no exception, no term, no label — after
/// the warm-up Ellie at once when she can talk, else the console with the reason.
public enum Launch: Equatable, Sendable {
    case child, console

    /// After the warm-up: Ellie when her model, voice and ear are ready and the rules below the model passed their
    /// self-test at load (J2); otherwise the console, whose lines say why (J3). The same rule lets «Дочке, при мне»
    /// bring her back; the exception and its term take no part in it.
    public static func after(ready: Bool, build: ReleaseGate.Build) -> Launch {
        ready && build.router && build.contract ? .child : .console
    }
}

extension ReleaseGate {
    /// Who the child session's records name: `child` only while the signed acceptance holds (R2) — then the black box
    /// keeps no words; otherwise `supervised`, and the black box writes every child session for the parent, who reads
    /// it on his Mac (J4).
    public static func audience(_ access: ChildAccess) -> Audience { access == .child ? .child : .supervised }
}

/// The console's line of the loading (J6): the whole and each stage in seconds with tenths and a comma — «загрузка:
/// 18,4 с · модель 12,1 · голос 2,3 · слух 1,4». A real loading by the parent's word, not a splash (screen rule 14 is
/// about those), so its length is measured and said.
public enum LoadingLine {
    public static func text(total: Double, stages: [(name: String, seconds: Double)]) -> String {
        (["загрузка: " + tenths(total) + " с"] + stages.map { $0.name + " " + tenths($0.seconds) })
            .joined(separator: " · ")
    }

    static func tenths(_ seconds: Double) -> String {
        String(format: "%.1f", max(seconds, 0)).replacingOccurrences(of: ".", with: ",")
    }
}
