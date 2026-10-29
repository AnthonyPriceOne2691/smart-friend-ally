import AllyCore
import SwiftUI

/// Ally, a child's app (child-open, the parent 2026-10-29): the loading screen while everything for her first answer
/// warms up, then Ellie at once — no lock, no label; her stop sign leads to the console, which also says why she is not
/// shown when she cannot talk. The screen stays on from the launch: the child screen comes first now (L130).
@main
struct AllyApp: App {
    @StateObject private var loop = VoiceLoop()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Group {
                if loop.warming {
                    LoadingScreen()
                } else if loop.child {
                    ChildScreen(talk: loop.talk, onWake: loop.childWake, onStop: loop.childStop)
                } else {
                    Console(loop: loop)
                }
            }
            .task {
                UIApplication.shared.isIdleTimerDisabled = true  // a locked phone stops the GPU work
                await loop.start()
            }
        }
        .onChange(of: phase) { _, now in if now == .background { _ = loop.pauseMemory() } }  // M35
    }
}

/// The console of the app (A12): the view is `ConsoleView` (design-demo: the demo shows the same one on made-up lines),
/// the loop gives it the session and the buttons; the warm-up starts with the app (child-open), the screen stays on.
struct Console: View {
    @ObservedObject var loop: VoiceLoop

    var body: some View {
        ConsoleView(model: loop.console, actions: loop.consoleActions)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true  // a locked phone stops the GPU work
                loop.refreshAccess()  // the acceptance and a leftover exception file show up when the console does
            }
    }
}

extension VoiceLoop {
    /// The console's look at the loop: the session, the open child screen, the acceptance and the break, the memory.
    var console: ConsoleModel {
        ConsoleModel(lines: screen.lines, heard: screen.heard, said: screen.said, ready: screen.ready, talk: talk,
                     memoryLines: memoryLines, memoryConfirmation: memoryConfirmation,
                     lockLines: ["детский экран: открыт всегда"] + [acceptance, napLine].compactMap { $0 },
                     open: childAllowed, exception: exception)
    }

    /// The console's buttons on the loop's own actions; what she remembers is read only on the parent's press.
    var consoleActions: ConsoleActions {
        ConsoleActions(wake: wake, done: done, bargeIn: bargeIn, stop: stop, handOver: handOver,
                       closeChildMode: closeChildMode, eraseMemory: eraseMemory, memoryText: { self.memoryText })
    }
}
