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
    /// M41: what she remembers by entity, for «Забыть…».
    var forgettable: [ForgetGroup] = []
    /// The lock, the acceptance, the break and the black box, one line each (R, R2, Ш3, D3.2).
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
    /// M41: forget one fact, or everything about one entity — by the ids of `ForgetGroup`.
    var forgetFact: @MainActor (Int64) -> Void = { _ in }, forgetEntity: @MainActor (Int64) -> Void = { _ in }
    /// B17: what the black box holds, for the question before its erase, and the erase after the parent's yes.
    var boxHeld: @MainActor () -> (sessions: Int, bytes: Int)? = { nil }, eraseBox: @MainActor () -> Void = {}
}

/// M41: an entity of her memory as the console shows it — the title, the facts in the block's words — with the parent's
/// question before each «Забыть»; plain values, so the demo builds the console without the memory.
struct ForgetGroup: Identifiable {
    struct Item: Identifiable { let id: Int64, text: String, question: String }
    let id: Int64, title: String, question: String, items: [Item]
}

/// «Для взрослых» (A12): readiness, signing days, the session's state and limit; what was heard and said stays on
/// this screen. «Разбудить» starts a session, «Я всё» ends the utterance while she listens (D7), «Стоп» silences her
/// at once (D2.2). In the pink sky with plum words, the lines on glass cards, the buttons glass capsules (app-glass);
/// sizes and fonts — `Look` (design-demo).
struct ConsoleView: View {
    let model: ConsoleModel, actions: ConsoleActions
    @State private var remembered: String?
    @State private var erasing = false
    @State private var forgetting = false
    @State private var asking: (sessions: Int, bytes: Int)?

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
                boxButton
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

    /// M39: what she remembers, and the parent's erase with its confirmation; M41: forget one thing — glass capsules.
    private var memoryButtons: some View {
        VStack(alignment: .leading, spacing: Look.rowSpacing) {
            HStack {
                Button("Что помнит Элли") { remembered = actions.memoryText() }.buttonStyle(GlassCapsule())
                    .disabled(model.memoryLines.isEmpty).accessibilityIdentifier("console.memoryText")
                Button("Забыть…") { forgetting = true }.buttonStyle(GlassCapsule())
                    .disabled(model.forgettable.isEmpty || model.talk.phase != .asleep)
                    .accessibilityIdentifier("console.forget")
            }
            Button("Стереть память", role: .destructive) { erasing = true }.buttonStyle(GlassCapsule())
                .disabled(model.memoryLines.isEmpty || model.talk.phase != .asleep)
                .accessibilityIdentifier("console.eraseMemory")
        }
        .sheet(isPresented: $forgetting) {
            ForgetSheet(groups: model.forgettable, asleep: model.talk.phase == .asleep, actions: actions)
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

    /// B17: the black box's erase — the parent's yes on what it holds, only while she sleeps.
    private var boxButton: some View {
        Button("Стереть чёрный ящик", role: .destructive) { asking = actions.boxHeld() }.buttonStyle(GlassCapsule())
            .disabled(model.talk.phase != .asleep).accessibilityIdentifier("console.erase")
            .alert(Self.question(asking), isPresented: Binding(get: { asking != nil },
                                                               set: { if !$0 { asking = nil } })) {
                Button("Стереть", role: .destructive, action: actions.eraseBox)
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Сначала выгрузи на Mac.")
            }
    }

    /// «Стереть 5 сессий (41 МБ)?» — what the box holds before the parent's yes.
    private static func question(_ held: (sessions: Int, bytes: Int)?) -> String {
        let n = held?.sessions ?? 0, mb = Int((Double(held?.bytes ?? 0) / 1_048_576).rounded())
        let tail = n % 100 / 10 == 1 ? 5 : n % 10
        let w = tail == 1 ? "сессию" : (2...4).contains(tail) ? "сессии" : "сессий"
        return "Стереть \(n) \(w) (\(mb) МБ)?"
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

/// M41: what she remembers by entity — the parent forgets one fact or everything about one entity, each confirmed.
struct ForgetSheet: View {
    let groups: [ForgetGroup], asleep: Bool, actions: ConsoleActions
    @State private var asked: (question: String, forget: @MainActor () -> Void)?

    var body: some View {
        NavigationStack {
            List(groups) { who in
                Section {
                    ForEach(who.items) { item in
                        Button(item.text) { asked = (item.question, { actions.forgetFact(item.id) }) }
                    }
                } header: {
                    HStack {
                        Text(who.title)
                        Spacer()
                        Button("Забыть всё") { asked = (who.question, { actions.forgetEntity(who.id) }) }
                    }
                }
            }
            .navigationTitle("Забыть")
            .confirmationDialog(asked?.question ?? "", isPresented: Binding(get: { asked != nil },
                                                                            set: { if !$0 { asked = nil } }),
                                titleVisibility: .visible) {
                Button("Забыть", role: .destructive) { asked?.forget() }
            }
        }
        .disabled(!asleep)
    }
}
