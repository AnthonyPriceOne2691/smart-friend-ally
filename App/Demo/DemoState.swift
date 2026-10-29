import AllyCore
import Foundation
import ShellCore

/// Her own way through a short talk (Y4, the parent's word 2026-10-29 after the show): nobody speaks — she sleeps; a
/// tap wakes her and she greets, then listens while the girl's phrase runs on a timer (no microphone), thinks, answers
/// and listens again; the last time nobody answers, so she says goodbye and falls asleep.
enum DemoScript {
    static let steps: [(phase: SessionState, seconds: Double)] = [
        (.greeting, 3), (.listening, 4), (.thinking, 1.5), (.speaking, 4), (.listening, 4), (.thinking, 1.5),
        (.speaking, 4), (.listening, 6), (.goodbye, 4)
    ]
    /// All eight phases of the session, in the order of the checking switcher.
    static let phases: [SessionState] = [
        .asleep, .greeting, .listening, .thinking, .speaking, .windingDown, .goodbye, .paused
    ]

    /// The step a tap sends the talk to from step `index`, as in the app (`Tap`): a wake starts it, «я всё» ends the
    /// listening, a barge-in cuts her to the next listening; nil — the tap does nothing.
    static func next(after tap: Tap, at index: Int) -> Int? {
        switch tap {
        case .wake: 0
        case .done: index + 1
        case .bargeIn: steps.indices.first { $0 > index && steps[$0].phase == .listening } ?? steps.count - 1
        case .ignore: nil
        }
    }
}

/// The made-up session of the demo (Y4): it opens as the child mode — Ellie and the stop sign in the corner, no label
/// (the parent 2026-10-29); the stop sign silences her and opens the adult mode, the app's console on made-up lines,
/// whose «Дочке, при мне» returns. The phase switcher is for checking the look only and needs a launch argument.
@MainActor
final class DemoState: ObservableObject {
    /// The demo's mark in its own binary: the boundary oracle refuses an app for the phone that carries it (Y2).
    static let marker = "ally-demo · не для телефона"

    @Published private(set) var phase = SessionState.asleep
    @Published var console = false
    @Published var panel = false
    @Published private(set) var memory = DemoConsole.memory
    private var talk: Task<Void, Never>?, step = 0

    /// The start: she sleeps on the child screen. For checks only (arguments of `simctl launch` land in the defaults):
    /// `-demo-panel YES` shows the switcher, `-demo-screen console` opens the console, `-demo-phase thinking` holds a
    /// phase, `-demo-wake YES` wakes her as a tap would (the simulator takes no taps from the command line).
    func begin(_ defaults: UserDefaults = .standard) {
        panel = defaults.bool(forKey: "demo-panel")
        console = defaults.string(forKey: "demo-screen") == "console"
        if let raw = defaults.string(forKey: "demo-phase"), let asked = SessionState(rawValue: raw) { pick(asked) }
        if defaults.bool(forKey: "demo-wake") { act(.wake) }
    }

    /// A tap on Ellie: what a tap does in this phase in the app (`Tap.action`).
    func tap() { act(Tap.action(phase)) }

    /// A wake, «я всё» or a barge-in — from a tap or from the console's buttons.
    func act(_ tap: Tap) {
        guard let start = DemoScript.next(after: tap, at: step) else { return }
        talk?.cancel()
        talk = Task { [weak self] in
            for index in start..<DemoScript.steps.count {
                guard let self, !Task.isCancelled else { return }
                (self.step, self.phase) = (index, DemoScript.steps[index].phase)
                try? await Task.sleep(for: .seconds(DemoScript.steps[index].seconds))
            }
            guard let self, !Task.isCancelled else { return }
            (self.step, self.phase) = (0, .asleep)
        }
    }

    /// The console's «Стоп»: silence at once, she sleeps.
    func stop() { pick(.asleep) }

    /// The stop sign on the child screen, as in the app: silence and the console — one action, no Face ID in the demo.
    func leaveChild() {
        stop()
        console = true
    }

    /// A phase held by hand (the checking switcher, `-demo-phase`): the talk stops.
    func pick(_ next: SessionState) {
        talk?.cancel()
        (talk, step, phase) = (nil, 0, next)
    }

    var consoleModel: ConsoleModel {
        DemoConsole.model(phase: phase, memory: memory)
    }

    var consoleActions: ConsoleActions {
        ConsoleActions(wake: { self.act(.wake) }, done: { self.act(.done) }, bargeIn: { self.act(.bargeIn) },
                       stop: { self.stop() }, handOver: { self.console = false },
                       eraseMemory: { self.memory = [] }, memoryText: { DemoConsole.memoryText })
    }
}
