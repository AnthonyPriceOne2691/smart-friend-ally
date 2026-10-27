#if canImport(SwiftUI)
import AllyCore
import Foundation
import ShellCore
import SwiftUI

/// The child's screen (Ш3): Ellie alive in her bubble with the crown, the bubble as the only target and the adult's
/// corner. What a tap does is the phase's (`Tap`): asleep she stirs at once and the app may wake her, listening it ends
/// her utterance («я всё»), speaking it cuts her (D6.2), otherwise nothing. No words for the girl; the status bar and
/// the home bar are hidden and the system gestures wait for a second swipe (screen rules 1–3, 15).
public struct ChildShell: View {
    let talk: TalkState, until: Date?, onTap: () -> Void, onStop: () -> Void
    @State private var pokes = 0

    public init(talk: TalkState, until: Date?, onTap: @escaping () -> Void, onStop: @escaping () -> Void) {
        (self.talk, self.until, self.onTap, self.onStop) = (talk, until, onTap, onStop)
    }

    public var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let layout = ShellCore.Layout(width: proxy.size.width + insets.leading + insets.trailing,
                                          height: proxy.size.height + insets.top + insets.bottom,
                                          safeTop: insets.top, safeBottom: insets.bottom)
            ZStack(alignment: .topLeading) {
                LiveScene(phase: talk.phase, pokes: pokes, safeTop: insets.top, safeBottom: insets.bottom)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .global) { tap($0, on: layout) }
                    .accessibilityIdentifier("child.circle")
                AdultZone(label: Tap.label(until: until, zone: .current), layout: layout, onStop: onStop)
            }
            .ignoresSafeArea()
        }
        .modifier(SystemBarsHidden())
    }

    /// A touch on Ellie does what the phase says; the sky and the bottom strip are not hers.
    private func tap(_ point: CGPoint, on layout: ShellCore.Layout) {
        guard layout.hits(x: point.x, y: point.y) else { return }
        switch Tap.action(talk.phase) {
        case .wake:
            pokes += 1
            onTap()
        case .done, .bargeIn: onTap()
        case .ignore: break
        }
    }
}

/// The phone's own bars and edge gestures stay out of the child's way (screen rule 15); the Mac has none.
private struct SystemBarsHidden: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.statusBarHidden().persistentSystemOverlays(.hidden).defersSystemGestures(on: .all)
        #else
        content
        #endif
    }
}
#endif
