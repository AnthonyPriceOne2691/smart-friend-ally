import AllyCore
import Foundation

/// Made-up lines for the demo's console and its previews (Y4, Y5): what a warmed-up phone would show — no name and no
/// word of the child's.
enum DemoConsole {
    static let lines = [
        "подпись: осталось 6 дней", "прогрев: 2,1 с", "голос: Supertonic · малышка", "микрофон: да",
        "слух: диктовка", "звук: дуплекс", "лимит: 10 мин", "память: включена"
    ]
    static let heard = "а почему небо голубое?", said = "Это свет так рассеивается в воздухе!"
    static let memory = ["помнит: 2 факта"]
    static let memoryText = ["Любит загадки про море.", "Любимый цвет — розовый."].joined(separator: "\n")
    static let confirmation = "Стереть всё, что помнит Элли?", acceptance = "приёмка: нет файла приёмки"

    /// The console of the made-up session at `phase`: with a term the child mode is open «при родителе», without one
    /// («Закрыть детский режим») — as if the acceptance held, so «Дочке, при мне» never locks the demo in the console.
    static func model(phase: SessionState, until: Date?, memory: [String]) -> ConsoleModel {
        let access: ChildAccess = until.map { .supervised(until: $0) } ?? .child
        return ConsoleModel(lines: lines, heard: heard, said: said, ready: true, talk: TalkState(phase: phase),
                            memoryLines: memory, memoryConfirmation: confirmation,
                            lockLines: ReleaseGate.lines(access, zone: .current) + [acceptance],
                            open: access.open, exception: until != nil)
    }
}
