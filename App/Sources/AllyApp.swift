import SwiftUI

/// Ally, D1: the adult console only — the girl gets her screen after the router is accepted (E2).
@main
struct AllyApp: App {
    @StateObject private var loop = VoiceLoop()

    var body: some Scene {
        WindowGroup { Console(loop: loop) }
    }
}

/// «Для взрослых» (A12): readiness, signing days, the last turn's times; what was heard and said stays on this screen.
struct Console: View {
    @ObservedObject var loop: VoiceLoop

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Для взрослых").font(.title2.bold()).accessibilityIdentifier("console.adultsOnly")
            ForEach(Array(loop.screen.lines.enumerated()), id: \.offset) {
                Text($0.element).font(.caption.monospaced())
            }
            Spacer()
            Text(loop.screen.heard).foregroundStyle(.secondary)
            Text(loop.screen.said).bold()
            Button(loop.screen.busy ? "Слушаю…" : "Сказать фразу", action: loop.talk)
                .buttonStyle(.borderedProminent).disabled(!loop.screen.ready || loop.screen.busy)
                .accessibilityIdentifier("console.talk")
        }
        .padding()
        .task { await loop.start() }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }  // a locked phone stops the GPU work
    }
}
