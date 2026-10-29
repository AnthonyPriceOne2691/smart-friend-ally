#if canImport(SwiftUI)
import AllyCore
import ShellCore
import SwiftUI

/// The app's icon (app-icon, the parent 2026-10-29: «из того, что уже есть»; variant В «мордочка крупно», the parent's
/// choice of four): Ellie of the child screen waving from her bubble on the pink sky, drawn by the screen's own parts —
/// `SkyArt`, `Bubble`, `Axolotl` with the crown — and, for the phone's dark theme, under the screen's night
/// (`NightArt`). The square is 440 pt, the phone's width, so the rim and the lines keep the screen's weight at any size
/// of the picture; `IconTests` renders it to 1024 px and holds the catalogs to it (`scripts/render_app_icon.sh`).
public struct IconScene: View {
    let night: Bool

    public init(night: Bool = false) { self.night = night }

    public var body: some View {
        Canvas { ctx, size in draw(ctx, size) }
    }

    /// Variant В: the bubble 404 pt of the 440-pt square; Ellie 1.5 times larger and 62 units lower, so her face fills
    /// the bubble and the tips of the gills go past its edge; the greeting at 1.3 s — the head straight, the crown in
    /// the middle, a hand waving.
    static let side = 440.0, diameter = 404.0, zoom = 1.5, lift = 62.0, moment = 1.3

    /// The screen's layers (`ShellScene`) in a still square: sky and night's veil, the bubble with its water and little
    /// bubbles, the night in the water, Ellie, the film and the rim.
    private func draw(_ base: GraphicsContext, _ size: CGSize) {
        var ctx = base
        ctx.scaleBy(x: size.width / Self.side, y: size.height / Self.side)
        let square = CGSize(width: Self.side, height: Self.side), dark = NightArt(night: night ? 1 : 0)
        let middle = CGPoint(x: Self.side / 2, y: Self.side / 2)
        let bubble = Bubble(centre: middle, diameter: Self.diameter)
        SkyArt.draw(ctx, square)
        dark.veil(ctx, square)
        bubble.back(ctx)
        var water = ctx
        water.clip(to: circle(middle, Self.diameter / 2))
        var inside = water
        inside.translateBy(x: middle.x, y: middle.y)
        inside.scaleBy(x: Self.diameter / 400, y: Self.diameter / 400)
        inside.clip(to: circle(.zero, 194))
        BubbleArt.water(inside, BubbleField.still(time: Self.moment))
        dark.water(water, centre: middle, diameter: Self.diameter)
        dark.sky(inside, stars: Light.still(.asleep, time: Self.moment).stars)
        inside.translateBy(x: 0, y: Self.lift)
        inside.scaleBy(x: Self.zoom, y: Self.zoom)
        Axolotl(frame: Frame.at(.greeting, time: Self.moment), unit: Self.diameter / 400 * Self.zoom).draw(inside)
        bubble.front(ctx)
    }
}
#endif
