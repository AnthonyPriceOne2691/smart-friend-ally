#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The look of the adult's chrome in one place (design-demo): what the parent asks to change live — the words and
/// their plates, the glass tints, sizes, radii, fonts, fades and the press — read by the adult's corner (`AdultZone`),
/// the glass buttons (`GlassCapsule`), the glass cards (`glassCard`) and the console. The paints are `Palette`'s
/// (ShellCore: their contrast is tested on Linux, rule 9); the circle and the stop target — `Layout` (rules 2 and 13);
/// Ellie's drawing keeps its numbers in her own grid. Every value is the one signed by the parent 2026-10-27/28.
public enum Look {
    /// Plum: every word and sign of the adult's; white: the plate under the words, inside the glass (V21, L137).
    public static let words = Color(Palette.plum), plate = Color.white

    /// The glass tints: the adult's corner — a blush of the blossom; the main button — the skin's pink; the console's
    /// cards — a breath of white.
    public static let zoneTint = Color(Palette.blossom, opacity: 0.35)
    public static let mainTint = Color(Palette.skin, opacity: 0.55)
    public static let cardTint = Color.white.opacity(0.2)

    /// The adult's corner: the term's words and plate, the glass ring round it, the gap to the stop sign, the sign and
    /// the white square in it.
    public static let labelFont = Font.system(size: 12, weight: .heavy, design: .rounded)
    public static let labelPadding: CGFloat = 12, labelHeight: CGFloat = 28, ring: CGFloat = 5, zoneSpacing: CGFloat = 6
    public static let stopSign: CGFloat = 32, stopSquare: CGFloat = 11, stopSquareRadius: CGFloat = 3

    /// The glass buttons: words (the main one bold), the side padding, the height of a finger's target (≥ 44 pt,
    /// F4), how far a long word shrinks, the fade of a disabled one, the press — 0.96 on a spring of 0.3 s (rule 10).
    public static func buttonFont(prominent: Bool) -> Font {
        .system(size: 17, weight: prominent ? .bold : .semibold, design: .rounded)
    }

    public static let buttonPadding: CGFloat = 16, buttonHeight: CGFloat = 44, buttonShrink: CGFloat = 0.85
    public static let disabledFade = 0.4, pressScale: CGFloat = 0.96
    public static let press = Animation.spring(duration: 0.3)

    /// The console's glass cards: the corner radius and the padding round the words.
    public static let cardRadius: CGFloat = 22, cardPadding: CGFloat = 14

    /// The console: the title, the lines of the log, the state of Ellie, the notes of the lock and the memory; the
    /// gaps between the blocks, the lines, «heard» and «said», the rows of buttons; how pale «heard» is.
    public static let titleFont = Font.system(.title2, design: .rounded).bold()
    public static let lineFont = Font.caption.monospaced()
    public static let phaseFont = Font.system(.body, design: .rounded).weight(.semibold)
    public static let noteFont = Font.caption
    public static let blockSpacing: CGFloat = 12, lineSpacing: CGFloat = 12, pairSpacing: CGFloat = 6
    public static let rowSpacing: CGFloat = 10, heardFade = 0.75

    /// The loading screen (child-open): the bubble's canvas (the bubble is 0.62 of it, ≈ 186 pt, with room for its
    /// shadow), the gap to the word, the word and its plate (the plate and the glass ring — as the adult's corner).
    public static let loadingBubble: CGFloat = 300, loadingGap: CGFloat = 0
    public static let loadingFont = Font.system(size: 22, weight: .heavy, design: .rounded)
    public static let loadingPadding: CGFloat = 22, loadingHeight: CGFloat = 48
}
#endif
