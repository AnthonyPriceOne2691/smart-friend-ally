#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The adult's buttons (app-glass): smooth glass capsules with plum words, at least 44 pt high — the main one tinted
/// pink, the rest clear. Drawn with `glassEffect` itself rather than the system's glass button styles: on a Mac window
/// out of focus those lose their tint, and the snapshots would not show what the phone does. A disabled button keeps
/// clear glass and fades its words to 0.4; a press shrinks it to 0.96 on a spring of 0.3 s (screen rule 10).
public struct GlassCapsule: ButtonStyle {
    let prominent: Bool

    public init(prominent: Bool = false) { self.prominent = prominent }

    public func makeBody(configuration: Configuration) -> some View {
        GlassCapsuleBody(label: configuration.label, pressed: configuration.isPressed, prominent: prominent)
    }

    static let main = Glass.regular.tint(Look.mainTint).interactive()
    static let plain = Glass.regular.interactive()
}

private struct GlassCapsuleBody<Label: View>: View {
    let label: Label, pressed: Bool, prominent: Bool
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        label.font(Look.buttonFont(prominent: prominent))
            .lineLimit(1).minimumScaleFactor(Look.buttonShrink)  // four in a row fit 440 pt; a narrower phone shrinks
            .foregroundStyle(Look.words.opacity(enabled ? 1 : Look.disabledFade))
            .padding(.horizontal, Look.buttonPadding).frame(minHeight: Look.buttonHeight)
            .glassEffect(enabled && prominent ? GlassCapsule.main : GlassCapsule.plain, in: .capsule)
            .scaleEffect(pressed ? Look.pressScale : 1)
            .animation(Look.press, value: pressed)
    }
}
#endif
