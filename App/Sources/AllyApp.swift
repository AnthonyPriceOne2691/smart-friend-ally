import AllyCore
import SwiftUI

/// Ally: the adult console only — the girl gets her screen with the child lock (R) and the shell (E2).
@main
struct AllyApp: App {
    @StateObject private var loop = VoiceLoop()

    var body: some Scene {
        WindowGroup {
            if loop.child {
                ChildScreen(talk: loop.talk, until: loop.access.until, onWake: loop.childWake, onStop: loop.childStop)
            } else {
                Console(loop: loop)
            }
        }
    }
}

/// «Для взрослых» (A12): readiness, signing days, the session's state and limit; what was heard and said stays on
/// this screen. «Разбудить» starts a session, «Я всё» ends the utterance while she listens (D7), «Стоп» silences her
/// at once (D2.2); the black box's line and «Стереть чёрный ящик» with the parent's yes, only while she sleeps
/// (D3.2, B17).
struct Console: View {
    @ObservedObject var loop: VoiceLoop
    @State private var asking: (sessions: Int, bytes: Int)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Для взрослых").font(.title2.bold()).accessibilityIdentifier("console.adultsOnly")
            ScrollView {  // 20 turn lines overflowed the screen and pushed the button off it (phone, 2026-10-22)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(loop.screen.lines.enumerated()), id: \.offset) {
                        Text($0.element).font(.caption.monospaced())
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(loop.screen.heard).foregroundStyle(.secondary)
            Text(loop.screen.said).bold()
            Text("Элли: " + Self.word(loop.talk.phase)).accessibilityIdentifier("console.phase")
            ForEach(ReleaseGate.lines(loop.access, zone: .current) + [loop.acceptance, loop.napLine].compactMap { $0 },
                    id: \.self) {
                Text($0).font(.caption)
            }
            .accessibilityIdentifier("console.lock")
            Text(loop.screen.box).font(.caption.monospaced()).accessibilityIdentifier("console.blackbox")
            HStack {
                Button("Разбудить", action: loop.wake).buttonStyle(.borderedProminent)
                    .disabled(!loop.screen.ready || loop.talk.phase != .asleep).accessibilityIdentifier("console.wake")
                Button("Я всё", action: loop.done).buttonStyle(.bordered)
                    .disabled(loop.talk.pose != .listens).accessibilityIdentifier("console.done")
                Button("Стоп", action: loop.stop).buttonStyle(.bordered)
                    .disabled(loop.talk.phase == .asleep).accessibilityIdentifier("console.stop")
            }
            HStack {
                Button("Дочке, при мне", action: loop.handOver).buttonStyle(.bordered)
                    .disabled(!loop.access.open || loop.talk.phase != .asleep)
                    .accessibilityIdentifier("console.handOver")
                Button("Закрыть детский режим", action: loop.closeChildMode).buttonStyle(.bordered)
                    .disabled(!loop.exception).accessibilityIdentifier("console.closeChildMode")
            }
            Button("Стереть чёрный ящик") { asking = loop.boxHeld() }.buttonStyle(.bordered)
                .disabled(loop.talk.phase != .asleep).accessibilityIdentifier("console.erase")
        }
        .padding()
        .alert(Self.question(asking), isPresented: Binding(get: { asking != nil }, set: { if !$0 { asking = nil } })) {
            Button("Стереть", role: .destructive, action: loop.eraseBox)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Сначала выгрузи на Mac.")
        }
        .task { await loop.start() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true  // a locked phone stops the GPU work
            loop.refreshAccess()  // an exception copied while the app runs shows up when the console does
        }
    }

    /// «Стереть 5 сессий (41 МБ)?» — what the box holds before the parent's yes.
    private static func question(_ held: (sessions: Int, bytes: Int)?) -> String {
        let n = held?.sessions ?? 0, mb = Int((Double(held?.bytes ?? 0) / 1_048_576).rounded())
        let tail = n % 100 / 10 == 1 ? 5 : n % 10
        let w = tail == 1 ? "сессию" : (2...4).contains(tail) ? "сессии" : "сессий"
        return "Стереть \(n) \(w) (\(mb) МБ)?"
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
        }
    }
}
