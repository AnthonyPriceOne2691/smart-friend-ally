import AllyCore
import SwiftUI

/// Ally: the adult console only — the girl gets her screen with the child lock (R) and the shell (E2).
@main
struct AllyApp: App {
    @StateObject private var loop = VoiceLoop()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            if loop.child {
                ChildScreen(talk: loop.talk, until: loop.access.until, onWake: loop.childWake, onStop: loop.childStop)
            } else {
                Console(loop: loop)
            }
        }
        .onChange(of: phase) { _, now in if now == .background { _ = loop.pauseMemory() } }  // M35
    }
}

/// The console of the app (A12): the view is `ConsoleView` (design-demo: the demo shows the same one on made-up lines),
/// the loop gives it the session and the buttons; the warm-up starts with it, and the screen stays on.
struct Console: View {
    @ObservedObject var loop: VoiceLoop

    var body: some View {
        ConsoleView(model: loop.console, actions: loop.consoleActions)
            .safeAreaInset(edge: .bottom, alignment: .leading) {  // sim-app: only the iPhone app on a Mac shows it
                MacFilesButton(loop: loop).padding(.horizontal)
            }
            .task { await loop.start() }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true  // a locked phone stops the GPU work
                loop.refreshAccess()  // an exception copied while the app runs shows up when the console does
            }
    }
}

extension VoiceLoop {
    /// The console's look at the loop: the session, the lock, the acceptance and the break, the memory.
    var console: ConsoleModel {
        ConsoleModel(lines: screen.lines, heard: screen.heard, said: screen.said, ready: screen.ready, talk: talk,
                     memoryLines: memoryLines, memoryConfirmation: memoryConfirmation,
                     lockLines: ReleaseGate.lines(access, zone: .current) + [acceptance, napLine].compactMap { $0 },
                     open: access.open, exception: exception)
    }

    /// The console's buttons on the loop's own actions; what she remembers is read only on the parent's press.
    var consoleActions: ConsoleActions {
        ConsoleActions(wake: wake, done: done, bargeIn: bargeIn, stop: stop, handOver: handOver,
                       closeChildMode: closeChildMode, eraseMemory: eraseMemory, memoryText: { self.memoryText })
    }
}
