import AllyCore
import SwiftUI

/// Ally: the adult console only — the girl gets her screen with the child lock (R) and the shell (E2).
@main
struct AllyApp: App {
    @StateObject private var loop = VoiceLoop()

    var body: some Scene {
        WindowGroup { Console(loop: loop) }
    }
}

/// «Для взрослых» (A12): readiness, signing days, the session's state and limit; what was heard and said stays on
/// this screen. «Разбудить» starts a session, «Стоп» silences her at once (D2.2).
struct Console: View {
    @ObservedObject var loop: VoiceLoop

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
            HStack {
                Button("Разбудить", action: loop.wake).buttonStyle(.borderedProminent)
                    .disabled(!loop.screen.ready || loop.talk.phase != .asleep).accessibilityIdentifier("console.wake")
                Button("Стоп", action: loop.stop).buttonStyle(.bordered)
                    .disabled(loop.talk.phase == .asleep).accessibilityIdentifier("console.stop")
            }
        }
        .padding()
        .task { await loop.start() }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }  // a locked phone stops the GPU work
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
