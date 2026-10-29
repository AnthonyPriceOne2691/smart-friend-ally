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
    static let confirmation = "Стереть всё, что помнит Элли?"
    /// The lock's lines: the child screen is open always, without a label (the parent 2026-10-29); the acceptance —
    /// as on a phone without its file.
    static let lock = ["детский экран: открыт всегда", "приёмка: нет файла приёмки"]

    /// The console of the made-up session at `phase`.
    static func model(phase: SessionState, memory: [String]) -> ConsoleModel {
        ConsoleModel(lines: lines, heard: heard, said: said, ready: true, talk: TalkState(phase: phase),
                     memoryLines: memory, memoryConfirmation: confirmation, lockLines: lock, open: true)
    }
}
