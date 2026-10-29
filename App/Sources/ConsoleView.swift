import AllyCore
import ShellUI
import SwiftUI

/// What the console shows (A12), one look at the session for the screen: the app fills it from `VoiceLoop`, the demo
/// (design-demo) from made-up lines. Every button's rule reads it — the same rules as before the console left
/// `AllyApp.swift`.
struct ConsoleModel {
    var lines: [String] = [], heard = "", said = "", ready = false
    var talk = TalkState()
    /// M39: what she remembers, one line each, and the question before the erase.
    var memoryLines: [String] = [], memoryConfirmation = ""
    /// The lock, the acceptance and the break, one line each (R, R2, Ш3).
    var lockLines: [String] = []
    /// The child mode may be handed over (the access is open), an exception lies in the container.
    var open = false, exception = false
}

/// What the console's buttons do; `memoryText` is asked only when the parent presses «Что помнит Элли».
struct ConsoleActions {
    var wake: @MainActor () -> Void = {}, done: @MainActor () -> Void = {}
    var bargeIn: @MainActor () -> Void = {}, stop: @MainActor () -> Void = {}
    var handOver: @MainActor () -> Void = {}, closeChildMode: @MainActor () -> Void = {}
    var eraseMemory: @MainActor () -> Void = {}
    var memoryText: @MainActor () -> String = { "" }
}

/// «Для взрослых» (A12): readiness, signing days, the session's state and limit; what was heard and said stays on
/// this screen. «Разбудить» starts a session, «Я всё» ends the utterance while she listens (D7), «Стоп» silences her
/// at once (D2.2). In the pink sky with plum words, the lines on glass cards, the buttons glass capsules (app-glass);
/// sizes and fonts — `Look` (design-demo).
struct ConsoleView: View {
    let model: ConsoleModel, actions: ConsoleActions
    @State private var remembered: String?
    @State private var erasing = false

    var body: some View {
        AdultSky {
            VStack(alignment: .leading, spacing: Look.blockSpacing) {
                Text("Для взрослых").font(Look.titleFont)
                    .accessibilityIdentifier("console.adultsOnly")
                ScrollView {  // 20 turn lines overflowed the screen and pushed the button off it (phone, 2026-10-22)
                    VStack(alignment: .leading, spacing: Look.lineSpacing) {
                        ForEach(Array(model.lines.enumerated()), id: \.offset) {
                            Text($0.element).font(Look.lineFont)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .glassCard()
                VStack(alignment: .leading, spacing: Look.pairSpacing) {
                    Text(model.heard).opacity(Look.heardFade)
                    Text(model.said).bold()
                }
                .glassCard()
                Text("Элли: " + Self.word(model.talk.phase)).font(Look.phaseFont)
                    .accessibilityIdentifier("console.phase")
                ForEach(model.memoryLines, id: \.self) { Text($0).font(Look.noteFont) }
                .accessibilityIdentifier("console.memory")
                ForEach(model.lockLines, id: \.self) { Text($0).font(Look.noteFont) }
                .accessibilityIdentifier("console.lock")
                buttons
                memoryButtons
            }
            .padding()
        }
    }

    /// The session's buttons and the child mode's, glass capsules: «Разбудить» is the main one.
    private var buttons: some View {
        VStack(alignment: .leading, spacing: Look.rowSpacing) {
            HStack {
                Button("Разбудить", action: actions.wake).buttonStyle(GlassCapsule(prominent: true))
                    .disabled(!model.ready || model.talk.phase != .asleep).accessibilityIdentifier("console.wake")
                Button("Я всё", action: actions.done).buttonStyle(GlassCapsule())
                    .disabled(model.talk.pose != .listens).accessibilityIdentifier("console.done")
                Button("Перебить", action: actions.bargeIn).buttonStyle(GlassCapsule())
                    .disabled(model.talk.pose != .speaks).accessibilityIdentifier("console.bargeIn")
                Button("Стоп", action: actions.stop).buttonStyle(GlassCapsule())
                    .disabled(model.talk.phase == .asleep).accessibilityIdentifier("console.stop")
            }
            HStack {
                Button("Дочке, при мне", action: actions.handOver).buttonStyle(GlassCapsule())
                    .disabled(!model.open || model.talk.phase != .asleep)
                    .accessibilityIdentifier("console.handOver")
                Button("Закрыть детский режим", action: actions.closeChildMode).buttonStyle(GlassCapsule())
                    .disabled(!model.exception).accessibilityIdentifier("console.closeChildMode")
            }
        }
    }

    /// M39: what she remembers, and the parent's erase with its confirmation — glass capsules too.
    private var memoryButtons: some View {
        HStack {
            Button("Что помнит Элли") { remembered = actions.memoryText() }.buttonStyle(GlassCapsule())
                .disabled(model.memoryLines.isEmpty).accessibilityIdentifier("console.memoryText")
            Button("Стереть память", role: .destructive) { erasing = true }.buttonStyle(GlassCapsule())
                .disabled(model.memoryLines.isEmpty || model.talk.phase != .asleep)
                .accessibilityIdentifier("console.eraseMemory")
        }
        .confirmationDialog(model.memoryConfirmation, isPresented: $erasing, titleVisibility: .visible) {
            Button("Стереть", role: .destructive, action: actions.eraseMemory)
        }
        .alert("Что помнит Элли", isPresented: Binding(get: { remembered != nil },
                                                      set: { if !$0 { remembered = nil } })) {
            Button("Закрыть", role: .cancel) {}
        } message: {
            Text(remembered.map { $0.isEmpty ? model.memoryLines.first ?? "" : $0 } ?? "")
        }
    }

    /// The phase in the console's words (the demo's switcher names its chips with them too).
    static func word(_ phase: SessionState) -> String {
        switch phase {
        case .asleep: "спит"
        case .greeting: "здоровается"
        case .listening: "слушает"
        case .thinking: "думает"
        case .speaking: "говорит"
        case .windingDown: "дослушивает"
        case .goodbye: "прощается"
        case .paused: "пауза"
        }
    }
}
