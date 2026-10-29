import AllyCore
import ShellUI
import SwiftUI

/// The canvas of Xcode (Y5): every phase of the child screen and the console twice, on the demo's made-up lines. Pin
/// a preview, then change `Look.swift` or `Palette.swift` — the canvas redraws without a run (scheme AllyDemo).
enum DemoPreviews {
    static let until = Date().addingTimeInterval(3 * 3600)

    static func child(_ phase: SessionState) -> some View {
        ChildShell(talk: TalkState(phase: phase), until: until, onTap: {}, onStop: {})
    }

    static func console(_ phase: SessionState) -> some View {
        ConsoleView(model: DemoConsole.model(phase: phase, until: until, memory: DemoConsole.memory),
                    actions: ConsoleActions())
    }
}

#Preview("Спит") { DemoPreviews.child(.asleep) }
#Preview("Здоровается") { DemoPreviews.child(.greeting) }
#Preview("Слушает") { DemoPreviews.child(.listening) }
#Preview("Думает") { DemoPreviews.child(.thinking) }
#Preview("Говорит") { DemoPreviews.child(.speaking) }
#Preview("Дослушивает") { DemoPreviews.child(.windingDown) }
#Preview("Прощается") { DemoPreviews.child(.goodbye) }
#Preview("Пауза") { DemoPreviews.child(.paused) }
#Preview("Консоль · спит") { DemoPreviews.console(.asleep) }
#Preview("Консоль · говорит") { DemoPreviews.console(.speaking) }
