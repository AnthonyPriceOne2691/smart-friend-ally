#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The live thing of the loading screen (child-open; the parent 2026-10-29: «красивый такой какой-нибудь штучкой»):
/// Ellie's water bubble, empty, floating gently on the pink sky with little bubbles rising in it — the bubble she
/// appears in once everything has warmed up. No words: the loading's word is the app's. Reduce Motion — no float, the
/// bubbles rise at half the pace (screen rule 10: smooth, no flashes).
public struct LoadingBubble: View {
    @Environment(\.accessibilityReduceMotion) private var calm

    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            Canvas { ctx, size in draw(ctx, size, time: context.date.timeIntervalSinceReferenceDate) }
        }
    }

    /// The bubble's back, the rising bubbles clipped to its water, its film and rim over them. The bubble takes 0.62
    /// of the canvas: its soft shadow fades out inside it — cut at the canvas edge, it showed a pale square.
    private func draw(_ ctx: GraphicsContext, _ size: CGSize, time t: Double) {
        let diameter = min(size.width, size.height) * 0.62
        let float = calm ? 0 : sin(t * 2 * .pi / Self.period) * Self.float
        let centre = CGPoint(x: size.width / 2, y: size.height / 2 + float)
        let bubble = Bubble(centre: centre, diameter: diameter)
        bubble.back(ctx)
        var water = ctx
        water.clip(to: circle(centre, diameter / 2 - 6))
        for rise in Rise.all { rise.draw(water, centre: centre, diameter: diameter, time: calm ? t / 2 : t) }
        bubble.front(ctx)
    }

    /// One float up and down in 2.4 s, 6 pt each way — the pace of the child screen's bubble.
    static let period = 2.4, float = 6.0
}

/// A little bubble rising through the water: its column and size in shares of the diameter, rounds a second, phase.
struct Rise {
    let x: Double, size: Double, pace: Double, phase: Double

    static let all = [
        Rise(x: -0.18, size: 0.035, pace: 0.23, phase: 0), Rise(x: 0.06, size: 0.05, pace: 0.17, phase: 0.4),
        Rise(x: 0.22, size: 0.028, pace: 0.29, phase: 0.7), Rise(x: -0.04, size: 0.022, pace: 0.33, phase: 0.15)
    ]

    /// From the bottom of the water to its top, fading in and out so none pops (rule 10).
    func draw(_ base: GraphicsContext, centre: CGPoint, diameter: Double, time t: Double) {
        let share = (t * pace + phase).truncatingRemainder(dividingBy: 1)
        let spot = CGPoint(x: centre.x + diameter * x, y: centre.y + diameter * (0.4 - share * 0.8))
        var ctx = base
        ctx.opacity = sin(.pi * share)
        let ring = circle(spot, diameter * size)
        ctx.fill(ring, with: .color(.white.opacity(0.55)))
        ctx.stroke(ring, with: .color(Color(Palette.waterLine)), lineWidth: 1.5)
    }
}
#endif
