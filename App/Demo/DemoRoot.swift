import AllyCore
import ShellUI
import SwiftUI

/// The demo's screen (Y4): the child mode or the adult mode (the console) on the made-up session, as in the app; the
/// checking switcher over them only with `-demo-panel YES`.
struct DemoRoot: View {
    @StateObject private var demo = DemoState()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if demo.loading {
                LoadingScreen()
            } else if demo.console {
                ConsoleView(model: demo.consoleModel, actions: demo.consoleActions)
            } else {
                ChildShell(talk: TalkState(phase: demo.phase), until: nil, onTap: demo.tap, onStop: demo.leaveChild)
            }
            if demo.panel { DemoPanel(demo: demo) }
        }
        .accessibilityIdentifier(DemoState.marker)
        .task { demo.begin() }
    }
}

/// The checking switcher, a glass card at the bottom: the eight phases, the console, hide. For checking the
/// look only — the parent does not see it (the parent's word 2026-10-29); the app's child screen has no words and no
/// buttons (screen rules 1–3).
private struct DemoPanel: View {
    @ObservedObject var demo: DemoState

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(DemoScript.phases, id: \.self) { phase in
                    chip(ConsoleView.word(phase), on: demo.phase == phase) { demo.pick(phase) }
                        .accessibilityIdentifier("ally-demo.phase." + phase.rawValue)
                }
            }
            HStack(spacing: 6) {
                chip(demo.console ? "Экран" : "Консоль", on: demo.console) { demo.console.toggle() }
                chip("Скрыть", on: false) { demo.panel = false }
            }
        }
        .padding(10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 12).padding(.bottom, 8)
        .accessibilityIdentifier("ally-demo.panel")
    }

    /// A chip of the switcher: plum words on white, the chosen one white on plum.
    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.footnote.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(on ? Look.plate : Look.words)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(Capsule().fill(on ? Look.words : Look.plate.opacity(0.6)))
        }
        .buttonStyle(.plain)
    }
}
