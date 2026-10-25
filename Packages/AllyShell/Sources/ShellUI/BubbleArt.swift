#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The bubbles of the screen (prototype v3): soap bubbles in the sky (`.bub`), the puffs of thinking and the «Z» of
/// sleep (`.soap`, `.p-z`), little bubbles in the water (`.wbub`) and the sky's glints (`.tw`).
enum BubbleArt {
    /// The sky's glints: the corner of their box in shares of the screen and its width (pt).
    static let glints: [[Double]] = [[0.13, 0.21, 14], [0.86, 0.18, 17], [0.08, 0.46, 12], [0.92, 0.48, 14],
                                     [0.28, 0.07, 12], [0.66, 0.12, 13]]

    /// The sky's eight soap bubbles and six glints, in screen points — under the veil of the night.
    static func sky(_ ctx: GraphicsContext, _ field: BubbleField, _ light: Light, _ size: CGSize) {
        for bubble in field.sky {
            let centre = CGPoint(x: bubble.x * size.width, y: bubble.y * size.height)
            var turned = ctx
            turned.concatenate(turn(bubble.turn, around: centre))
            turned.concatenate(stretch(1 + bubble.wobble, 1 - bubble.wobble, around: centre))
            soap(turned, at: centre, diameter: bubble.size)
        }
        for (glint, brightness) in zip(glints, light.glints) {
            let centre = CGPoint(x: glint[0] * size.width + glint[2] / 2, y: glint[1] * size.height + glint[2] / 2)
            sparkle(ctx, at: centre, width: glint[2], fill: .white, opacity: brightness)
        }
    }

    /// The water's little bubbles, in the character's units — clipped to the water by the caller.
    static func water(_ ctx: GraphicsContext, _ field: BubbleField) {
        for bubble in field.water {
            let shape = circle(CGPoint(x: bubble.x, y: bubble.y), bubble.radius)
            ctx.fill(shape, with: .color(.white.opacity(0.45)))
            ctx.stroke(shape, with: .color(Color(Palette.waterLine, opacity: 0.6)), lineWidth: 1.6)
        }
    }

    /// The puffs round the bubble's centre: units of the character to screen points, each at its own visibility.
    static func puffs(_ base: GraphicsContext, _ field: BubbleField, centre: CGPoint, unit: Double) {
        for puff in field.puffs where puff.opacity > 0.001 {
            var ctx = base
            ctx.opacity *= puff.opacity
            let spot = CGPoint(x: centre.x + puff.x * unit, y: centre.y + puff.y * unit)
            let diameter = puff.size * puff.scale
            ctx.concatenate(turn(puff.turn, around: spot))
            soap(ctx, at: spot, diameter: diameter, ring: true)
            if puff.z { zee(ctx, at: spot, diameter: diameter) }
        }
    }

    /// A soap bubble: a clear body with a white edge, two highlights and a rainbow film; a puff has a raspberry ring.
    static func soap(_ ctx: GraphicsContext, at centre: CGPoint, diameter: Double, ring: Bool = false) {
        let radius = diameter / 2, disc = circle(centre, radius)
        ctx.fill(disc, with: glow([.init(color: .white.opacity(0.08), location: 0),
                                   .init(color: .white.opacity(0.08), location: 0.66),
                                   .init(color: .white.opacity(0.3), location: 0.9),
                                   .init(color: .white.opacity(0.8), location: 0.97),
                                   .init(color: .clear, location: 1)], at: centre, radius: radius))
        var film = ctx
        film.opacity *= 0.55
        let colours = (Palette.film + [Palette.film[0]]).map { Color($0) }
        film.stroke(circle(centre, radius * 0.89), with: .conicGradient(Gradient(colors: colours), center: centre,
                                                                         angle: .degrees(200)),
                    lineWidth: radius * 0.16)
        for shine in [[-0.38, -0.46, 0.12, 0.3, 0.95], [0.4, 0.5, 0.08, 0.23, 0.45]] {
            let spot = CGPoint(x: centre.x + radius * shine[0], y: centre.y + radius * shine[1])
            let white = Color.white.opacity(shine[4])
            ctx.fill(circle(spot, radius * shine[3]), with: glow([.init(color: white, location: 0),
                                                                   .init(color: white, location: shine[2] / shine[3]),
                                                                   .init(color: .clear, location: 1)],
                                                                  at: spot, radius: radius * shine[3]))
        }
        if ring {
            ctx.stroke(circle(centre, radius - 0.75), with: .color(Color(Palette.raspberry, opacity: 0.34)),
                       lineWidth: 1.5)
        }
    }

    /// The plum «Z» of sleep in the middle of its bubble, 60% of it across.
    private static func zee(_ base: GraphicsContext, at centre: CGPoint, diameter: Double) {
        var ctx = base
        ctx.translateBy(x: centre.x, y: centre.y)
        ctx.scaleBy(x: diameter * 0.6 / 24, y: diameter * 0.6 / 24)
        let letter = Path { path in
            path.move(to: CGPoint(x: -5.5, y: -5.5))
            path.addLine(to: CGPoint(x: 5.5, y: -5.5))
            path.addLine(to: CGPoint(x: -5.5, y: 5.5))
            path.addLine(to: CGPoint(x: 5.5, y: 5.5))
        }
        ctx.stroke(letter, with: .color(Color(Palette.plum)), style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                                                                 lineJoin: .round))
    }
}
#endif
