import AllyCore
import Memory
import ShellUI
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

/// «Для взрослых» (A12): readiness, signing days, the session's state and limit; what was heard and said stays on
/// this screen. «Разбудить» starts a session, «Я всё» ends the utterance while she listens (D7), «Стоп» silences her
/// at once (D2.2). In the pink sky with plum words, the lines on glass cards, the buttons glass capsules (app-glass).
struct Console: View {
    @ObservedObject var loop: VoiceLoop
    @State private var remembered: String?
    @State private var erasing = false
    @State private var forgetting = false

    var body: some View {
        AdultSky {
            VStack(alignment: .leading, spacing: 12) {
                Text("Для взрослых").font(.system(.title2, design: .rounded).bold())
                    .accessibilityIdentifier("console.adultsOnly")
                ScrollView {  // 20 turn lines overflowed the screen and pushed the button off it (phone, 2026-10-22)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(loop.screen.lines.enumerated()), id: \.offset) {
                            Text($0.element).font(.caption.monospaced())
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .glassCard()
                VStack(alignment: .leading, spacing: 6) {
                    Text(loop.screen.heard).opacity(0.75)
                    Text(loop.screen.said).bold()
                }
                .glassCard()
                Text("Элли: " + Self.word(loop.talk.phase)).font(.system(.body, design: .rounded).weight(.semibold))
                    .accessibilityIdentifier("console.phase")
                ForEach(loop.memoryLines, id: \.self) { Text($0).font(.caption) }
                .accessibilityIdentifier("console.memory")
                ForEach(lockLines, id: \.self) { Text($0).font(.caption) }
                .accessibilityIdentifier("console.lock")
                buttons
                memoryButtons
            }
            .padding()
        }
        .task { await loop.start() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true  // a locked phone stops the GPU work
            loop.refreshAccess()  // an exception copied while the app runs shows up when the console does
        }
    }

    /// The lock, the acceptance and the break, one line each.
    private var lockLines: [String] {
        ReleaseGate.lines(loop.access, zone: .current) + [loop.acceptance, loop.napLine].compactMap { $0 }
    }

    /// The session's buttons and the child mode's, glass capsules: «Разбудить» is the main one.
    private var buttons: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Разбудить", action: loop.wake).buttonStyle(GlassCapsule(prominent: true))
                    .disabled(!loop.screen.ready || loop.talk.phase != .asleep).accessibilityIdentifier("console.wake")
                Button("Я всё", action: loop.done).buttonStyle(GlassCapsule())
                    .disabled(loop.talk.pose != .listens).accessibilityIdentifier("console.done")
                Button("Перебить", action: loop.bargeIn).buttonStyle(GlassCapsule())
                    .disabled(loop.talk.pose != .speaks).accessibilityIdentifier("console.bargeIn")
                Button("Стоп", action: loop.stop).buttonStyle(GlassCapsule())
                    .disabled(loop.talk.phase == .asleep).accessibilityIdentifier("console.stop")
            }
            HStack {
                Button("Дочке, при мне", action: loop.handOver).buttonStyle(GlassCapsule())
                    .disabled(!loop.access.open || loop.talk.phase != .asleep)
                    .accessibilityIdentifier("console.handOver")
                Button("Закрыть детский режим", action: loop.closeChildMode).buttonStyle(GlassCapsule())
                    .disabled(!loop.exception).accessibilityIdentifier("console.closeChildMode")
            }
        }
    }

    /// M39: what she remembers, and the parent's erase with its confirmation; M41: forget one thing — glass capsules.
    private var memoryButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Что помнит Элли") { remembered = loop.memoryText }.buttonStyle(GlassCapsule())
                    .disabled(loop.memoryLines.isEmpty).accessibilityIdentifier("console.memoryText")
                Button("Забыть…") { forgetting = true }.buttonStyle(GlassCapsule())
                    .disabled(loop.memoryLines.isEmpty || loop.talk.phase != .asleep)
                    .accessibilityIdentifier("console.forget")
            }
            Button("Стереть память", role: .destructive) { erasing = true }.buttonStyle(GlassCapsule())
                .disabled(loop.memoryLines.isEmpty || loop.talk.phase != .asleep)
                .accessibilityIdentifier("console.eraseMemory")
        }
        .sheet(isPresented: $forgetting) { ForgetSheet(loop: loop) }
        .confirmationDialog(loop.memoryConfirmation, isPresented: $erasing, titleVisibility: .visible) {
            Button("Стереть", role: .destructive, action: loop.eraseMemory)
        }
        .alert("Что помнит Элли", isPresented: Binding(get: { remembered != nil },
                                                      set: { if !$0 { remembered = nil } })) {
            Button("Закрыть", role: .cancel) {}
        } message: {
            Text(remembered.map { $0.isEmpty ? loop.memoryLines.first ?? "" : $0 } ?? "")
        }
    }

    private static func word(_ phase: SessionState) -> String {
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
    @ObservedObject var loop: VoiceLoop
    @State private var asked: (question: String, forget: () -> Void)?

    var body: some View {
        NavigationStack {
            List(loop.remembered, id: \.entity) { who in
                Section {
                    ForEach(who.items, id: \.fact) { item in
                        Button(item.text) {
                            asked = (MemoryConsole.forgetting(item), { loop.forget(fact: item.fact) })
                        }
                    }
                } header: {
                    HStack {
                        Text(who.title)
                        Spacer()
                        Button("Забыть всё") {
                            asked = (MemoryConsole.forgetting(who), { loop.forget(entity: who.entity) })
                        }
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
        .disabled(loop.talk.phase != .asleep)
    }
}
