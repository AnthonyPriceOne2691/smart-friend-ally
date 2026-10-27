#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The night (prototype v3, `.night`, `.tint-night`, `#stars`): a lilac veil with eight dots of stars over the sky —
/// behind the bubble and the adult's corner — lilac water in the bubble, and the moon with nine stars in it.
struct NightArt {
    let night: Double

    /// The veil over the sky, drawn before the bubble.
    func veil(_ base: GraphicsContext, _ size: CGSize) {
        guard night > 0.001 else { return }
        var ctx = base
        ctx.opacity *= night
        let full = Path(CGRect(origin: .zero, size: size))
        ctx.fill(full, with: .linearGradient(Gradient(colors: [Color(Palette.veilTop, opacity: 0.5),
                                                               Color(Palette.veilLow, opacity: 0.34)]),
                                             startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        for dot in NightArt.dots {
            let spot = CGPoint(x: dot[0] * size.width, y: dot[1] * size.height), white = Color.white.opacity(dot[4])
            ctx.fill(circle(spot, dot[3]), with: glow([.init(color: white, location: 0),
                                                        .init(color: white, location: dot[2] / dot[3]),
                                                        .init(color: .clear, location: 1)], at: spot, radius: dot[3]))
        }
    }

    /// Lilac water: 85% of the night, from the upper middle of the bubble outwards.
    func water(_ base: GraphicsContext, centre: CGPoint, diameter: Double) {
        guard night > 0.001 else { return }
        var ctx = base
        ctx.opacity *= 0.85 * night
        ctx.fill(circle(centre, diameter / 2), with: glow([.init(color: Color(Palette.nightHigh), location: 0),
                                                            .init(color: Color(Palette.nightMid), location: 0.55),
                                                            .init(color: Color(Palette.nightLow), location: 1)],
                                                           at: CGPoint(x: centre.x, y: centre.y - diameter * 0.2),
                                                           radius: diameter * 0.86))
    }

    /// The moon with its halo and the nine stars, in the character's units inside the bubble.
    func sky(_ base: GraphicsContext, stars: [Double]) {
        guard night > 0.001 else { return }
        var ctx = base
        ctx.opacity *= night
        var moon = ctx
        moon.translateBy(x: 112, y: -118)
        moon.scaleBy(x: 1.25, y: 1.25)
        let halo = CGPoint(x: 4, y: -2), tone = Color(Palette.moon)
        moon.fill(circle(halo, 30), with: glow([.init(color: tone.opacity(0.55), location: 0),
                                                 .init(color: tone.opacity(0), location: 1)], at: halo, radius: 30))
        moon.clip(to: circle(CGPoint(x: 5.985, y: -3.989), 13), options: .inverse)  // the crescent's bite
        moon.fill(circle(.zero, 16), with: .color(tone))
        for (star, brightness) in zip(NightArt.stars, stars) {
            sparkle(ctx, at: CGPoint(x: star[0] + star[2] / 2, y: star[1] + star[2] / 2), width: star[2], fill: .white,
                    opacity: brightness)
        }
    }

    /// The veil's dots: place in shares of the screen, core and edge radius (pt), whiteness.
    static let dots: [[Double]] = [[0.14, 0.18, 1.4, 2.4, 0.9], [0.82, 0.12, 1.6, 2.6, 0.9], [0.64, 0.26, 1.1, 2, 0.8],
                                   [0.3, 0.08, 1.2, 2.2, 0.8], [0.92, 0.4, 1.3, 2.3, 0.8], [0.06, 0.46, 1.1, 2, 0.8],
                                   [0.46, 0.06, 1.5, 2.5, 0.9], [0.74, 0.58, 1.1, 2, 0.6]]
    /// The stars in the bubble: the corner of their box and its width, in units.
    static let stars: [[Double]] = [[-146, -130, 13], [-170, -46, 9], [-103, -167, 10], [139, -73, 10], [54, -176, 8],
                                    [158, 20, 8], [-180, 40, 9], [113, 117, 10], [-134, 126, 8]]
}
#endif
