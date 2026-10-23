#if canImport(SwiftUI)
import AllyCore
import ShellCore
import SwiftUI

/// The picture of the child screen for one frame: the pink sky, the bubble and Ellie in it, laid out by `Layout`. No
/// words and no controls — the tap, the adult's label and stop join in Ш3; `LiveScene` animates it.
public struct ShellScene: View {
    let frame: Frame, safeTop: Double, safeBottom: Double

    public init(frame: Frame, safeTop: Double = 0, safeBottom: Double = 0) {
        (self.frame, self.safeTop, self.safeBottom) = (frame, safeTop, safeBottom)
    }

    /// A still frame of one phase at one moment (Ш1's snapshots).
    public init(phase: SessionState, time: Double, voice: Double? = nil, mic: Double? = nil, safeTop: Double = 0,
                safeBottom: Double = 0) {
        self.init(frame: Frame.at(phase, time: time, voice: voice, mic: mic), safeTop: safeTop, safeBottom: safeBottom)
    }

    public var body: some View {
        Canvas { ctx, size in draw(ctx, size) }
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let layout = Layout(width: size.width, height: size.height, safeTop: safeTop, safeBottom: safeBottom)
        let centre = CGPoint(x: layout.centre.x, y: layout.centre.y)
        sky(ctx, size)
        let bubble = Bubble(centre: centre, diameter: layout.diameter)
        bubble.back(ctx)
        var world = ctx
        world.clip(to: circle(centre, layout.diameter / 2))
        world.translateBy(x: centre.x, y: centre.y)
        world.scaleBy(x: layout.unit, y: layout.unit)
        world.clip(to: circle(.zero, 194))
        Axolotl(frame: frame, unit: layout.unit).draw(world)
        bubble.front(ctx)
    }

    /// Pink from top to bottom; a lilac light in the upper right, a peach one in the lower left, white in the middle.
    private func sky(_ ctx: GraphicsContext, _ size: CGSize) {
        let full = Path(CGRect(origin: .zero, size: size))
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color(Palette.skyTop), Color(Palette.skyMid), Color(Palette.skyLow)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        let lights = [(Color(Palette.skyLilac), CGPoint(x: 0.88, y: 0.06), 0.7),
                      (Color(Palette.skyPeach), CGPoint(x: 0.06, y: 0.96), 0.6),
                      (Color.white.opacity(0.6), CGPoint(x: 0.5, y: 0.52), 0.9)]
        for (colour, place, reach) in lights {
            let spot = CGPoint(x: place.x * size.width, y: place.y * size.height)
            ctx.fill(full, with: glow([.init(color: colour, location: 0), .init(color: colour.opacity(0), location: 1)],
                                      at: spot, radius: reach * size.width))
        }
    }
}
#endif
