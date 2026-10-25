#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The water bubble that holds Ellie (prototype v3, `.orb`) — the child's only tap target from Ш3 on. Behind her:
/// a soft floor shadow, the lifted disc, the water with its light and shade. Over her: the rainbow film, the highlights
/// and the raspberry rim with its pale band. Night, tints and the glow of listening — `NightArt` and `GlowArt` (Ш2б).
struct Bubble {
    let centre: CGPoint, diameter: Double

    private var radius: Double { diameter / 2 }

    /// The soft shadow on the «floor» — it stays when the bubble floats, shrinking as the bubble sinks (Ш2б).
    func floor(_ base: GraphicsContext, _ light: Light) {
        let floor = CGPoint(x: centre.x, y: centre.y + diameter * 0.53)
        let pink = Color(red: 214 / 255, green: 95 / 255, blue: 152 / 255)
        var ctx = base
        ctx.opacity = 0.85 - light.bob * 0.02
        ctx.concatenate(stretch(light.floor, light.floor, around: floor))
        ctx.fill(ellipse(floor.x, floor.y, diameter * 0.3, diameter * 0.0375),
                 with: glow([.init(color: pink.opacity(0.3), location: 0), .init(color: pink.opacity(0), location: 1)],
                            at: floor, radius: diameter * 0.3))
    }

    func back(_ ctx: GraphicsContext) {
        let disc = circle(centre, radius)
        var lifted = ctx
        lifted.addFilter(.shadow(color: Color(red: 200 / 255, green: 80 / 255, blue: 140 / 255, opacity: 0.18),
                                 radius: 25, x: 0, y: 24))
        lifted.fill(disc, with: .color(Color(Palette.waterEdge)))
        ctx.fill(disc, with: glow([.init(color: Color(Palette.waterCore), location: 0),
                                   .init(color: Color(Palette.water), location: 0.55),
                                   .init(color: Color(Palette.waterEdge), location: 1)],
                                  at: CGPoint(x: centre.x, y: centre.y - diameter * 0.1), radius: diameter * 0.78))
        let shade = Color(red: 70 / 255, green: 160 / 255, blue: 200 / 255, opacity: 0.18)
        ctx.fill(disc, with: .linearGradient(Gradient(colors: [.white.opacity(0.5), .clear, .clear, shade]),
                                             startPoint: CGPoint(x: centre.x, y: centre.y - radius),
                                             endPoint: CGPoint(x: centre.x, y: centre.y + radius)))
    }

    func front(_ ctx: GraphicsContext) {
        var film = ctx
        film.opacity = 0.5
        film.addFilter(.blur(radius: 1.5))
        let colours = (Palette.film + [Palette.film[0]]).map { Color($0) }
        film.stroke(circle(centre, radius * 0.905), with: .conicGradient(Gradient(colors: colours), center: centre,
                                                                          angle: .degrees(210)),
                    lineWidth: radius * 0.1)
        for shine in Shine.all { highlight(ctx, shine) }
        ctx.fill(circle(CGPoint(x: centre.x - diameter * 0.31, y: centre.y - diameter * 0.23), diameter * 0.016),
                 with: .color(.white.opacity(0.95)))
        ctx.stroke(circle(centre, radius - 5.5), with: .color(Color(Palette.band)), lineWidth: 3)
        ctx.stroke(circle(centre, radius - 2), with: .color(Color(Palette.raspberry)), lineWidth: 4)
    }

    /// A soft white highlight on the film, placed in shares of the diameter from the centre.
    private func highlight(_ ctx: GraphicsContext, _ shine: Shine) {
        let spot = CGPoint(x: centre.x + diameter * shine.x, y: centre.y + diameter * shine.y)
        ctx.fill(ellipse(spot.x, spot.y, diameter * shine.width, diameter * shine.height),
                 with: glow([.init(color: .white.opacity(shine.alpha), location: 0), .init(color: .clear, location: 1)],
                            at: spot, radius: diameter * shine.width))
    }
}

/// The two soft highlights of the film (prototype v3, `.orb-gloss`): upper left and lower right.
struct Shine {
    let x: Double, y: Double, width: Double, height: Double, alpha: Double

    static let all = [Shine(x: -0.18, y: -0.38, width: 0.11, height: 0.05, alpha: 0.8),
                      Shine(x: 0.14, y: 0.42, width: 0.13, height: 0.04, alpha: 0.45)]
}
#endif
