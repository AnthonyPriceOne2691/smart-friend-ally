#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The adult's corner of the child screen (R, screen rule 13, the parent's answer 4): under the island on the right —
/// a white plate with the term in small plum letters and a round plum stop sign of 32 pt in its 44 pt target, each in
/// clear glass (app-glass, the parent 2026-10-27): the plate in a capsule 5 pt wider, the sign in a circle of 44 pt.
/// The glass is only the underlay — the words and the colours stay on the plate and the sign, so they read at night
/// and on any glass (V21, F3). The only words on the child screen live in this file (the rule `child_screen_text` lets
/// it through); the girl reads none of them, and only the stop sign answers a touch.
public struct AdultZone: View {
    let label: String?, layout: ShellCore.Layout, onStop: () -> Void

    public init(label: String?, layout: ShellCore.Layout, onStop: @escaping () -> Void) {
        (self.label, self.layout, self.onStop) = (label, layout, onStop)
    }

    public var body: some View {
        let target = layout.stopTarget, plum = Color(Palette.plum)
        HStack(spacing: 6) {
            if let label {
                Text(label).font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(plum)
                    .padding(.horizontal, 12).frame(height: 28)
                    .background(Capsule().fill(Color.white))  // opaque: at night the veil lies behind it (Ш2б)
                    .padding(5)
                    .background { Capsule().fill(.clear).glassEffect(Self.glass, in: .capsule) }
                    .allowsHitTesting(false).accessibilityIdentifier("child.until")
            }
            Button(action: onStop) {
                Circle().fill(plum).frame(width: 32, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 11, height: 11))
                    .frame(width: target.width, height: target.height)
                    .background { Circle().fill(.clear).glassEffect(Self.glass.interactive(), in: .circle) }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityIdentifier("child.stop")
        }
        .padding(.top, target.y)
        .padding(.trailing, layout.width - target.x - target.width)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    /// Clear glass with a blush of the blossom; no `GlassEffectContainer` — in it the glass lay over the plate and
    /// the sign (the stand, 2026-10-27).
    static let glass = Glass.regular.tint(Color(Palette.blossom, opacity: 0.35))
}
#endif
