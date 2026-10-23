import AllyCore
import SwiftUI

/// The child screen (R): a temporary stand-in on the interface the shell keeps — the shell (Ш3) replaces this body
/// with the axolotl. No words for the girl (screen rule 1): a big circle whose colour follows the pose, a tap on it
/// wakes her; the small label of the term and the stop sign in the corner are for the parent (rules 9, 13).
struct ChildScreen: View {
    let talk: TalkState, until: Date?, onWake: () -> Void, onStop: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle().fill(fill).frame(width: 260, height: 260)
                .overlay(Circle().stroke(Self.plum, lineWidth: 4))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle()).onTapGesture(perform: onWake)
                .accessibilityIdentifier("child.circle")
            VStack(alignment: .trailing, spacing: 6) {
                Button(action: onStop) { Image(systemName: "stop.circle").font(.title3) }
                    .tint(Self.plum).accessibilityIdentifier("child.stop")
                if let until {
                    Text("при родителе · до " + ReleaseGate.when(until, zone: .current)).font(.caption2)
                        .foregroundStyle(Self.plum).accessibilityIdentifier("child.until")
                }
            }
            .padding(24)
        }
        .background(Color(red: 1, green: 0.94, blue: 0.96).ignoresSafeArea())
    }

    private static let plum = Color(red: 0.37, green: 0.10, blue: 0.26)

    private var fill: Color {
        switch talk.pose {
        case .sleeps: Color(red: 0.98, green: 0.80, blue: 0.86)
        case .listens: Color(red: 0.98, green: 0.54, blue: 0.69)
        case .thinks: Color(red: 0.91, green: 0.70, blue: 0.85)
        case .speaks: Color(red: 0.95, green: 0.42, blue: 0.62)
        }
    }
}
