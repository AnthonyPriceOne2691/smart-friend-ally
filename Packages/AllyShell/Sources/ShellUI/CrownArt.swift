#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The flower crown on her head (prototype v3): the leaves, then roses, carnations and lisianthus in the prototype's
/// order, then the glints at the frame's brightness. Drawn in the head's coordinates, seated by `Crown.scale` about
/// (0; `Crown.pivotY`), so it turns with the head.
struct CrownArt {
    let glints: [Double]

    func draw(_ base: GraphicsContext) {
        var ctx = base
        ctx.concatenate(stretch(Crown.scale, Crown.scale, around: CGPoint(x: 0, y: Crown.pivotY)))
        for leaf in Crown.leaves {
            let shape = ellipse(leaf.x, leaf.y, Crown.leafLength, Crown.leafWidth, leaf.turn)
            ctx.fill(shape, with: .color(Color(leaf.dark ? Palette.leafDark : Palette.leaf)))
            ctx.stroke(shape, with: .color(Color(Palette.line)), lineWidth: 1.1)
        }
        for flower in Crown.flowers { bloom(ctx, flower) }
        for (glint, brightness) in zip(Crown.glints, glints) { shine(ctx, glint, brightness) }
    }

    /// A flower in its 24-unit symbol, scaled to its width.
    private func bloom(_ base: GraphicsContext, _ flower: Crown.Flower) {
        var ctx = base
        ctx.translateBy(x: flower.x, y: flower.y)
        ctx.scaleBy(x: flower.width / 24, y: flower.width / 24)
        switch flower.kind {
        case .rose: rose(ctx)
        case .carnation: carnation(ctx)
        case .lisianthus: lisianthus(ctx)
        }
    }

    /// Five petals around the middle, each turned along its way out.
    private func petals(_ ctx: GraphicsContext, width: Double, height: Double, out distance: Double, fill: Tone) {
        for index in 0..<5 {
            let degrees = Double(index) * 72, radians = degrees * .pi / 180
            let shape = ellipse(distance * sin(radians), -distance * cos(radians), width, height, degrees)
            ctx.fill(shape, with: .color(Color(fill)))
            ctx.stroke(shape, with: .color(Color(Palette.line)), lineWidth: 1)
        }
    }

    private func rose(_ ctx: GraphicsContext) {
        petals(ctx, width: 5, height: 5.6, out: 5.6, fill: Palette.roseOut)
        let middle = circle(.zero, 5.9)
        ctx.fill(middle, with: .color(Color(Palette.roseMid)))
        ctx.stroke(middle, with: .color(Color(Palette.line)), lineWidth: 1)
        ctx.stroke(Blooms.swirl, with: .color(Color(Palette.raspberry)),
                   style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        ctx.fill(ellipse(-3, -3.6, 1.8, 1, -30), with: .color(.white.opacity(0.7)))
    }

    private func carnation(_ ctx: GraphicsContext) {
        let fills = [Palette.carnOut, Palette.carnIn, Palette.carnCore], lines = [Palette.line, Palette.carnLine]
        for (index, ruffle) in Blooms.ruffles.enumerated() {
            ctx.fill(ruffle, with: .color(Color(fills[index])))
            ctx.stroke(ruffle, with: .color(Color(lines[min(index, 1)])), lineWidth: 1 - 0.1 * Double(index))
        }
    }

    private func lisianthus(_ ctx: GraphicsContext) {
        petals(ctx, width: 5.4, height: 6.4, out: 4.8, fill: Palette.lisOut)
        ctx.fill(circle(.zero, 4.9), with: .color(Color(Palette.lisIn)))
        ctx.fill(circle(.zero, 2.3), with: .color(Color(Palette.lisCore)))
        ctx.stroke(circle(.zero, 2.3), with: .color(Color(Palette.line)), lineWidth: 0.8)
        for (x, y) in [(-0.9, -0.6), (0.9, -0.4), (0, 0.9)] {
            ctx.fill(circle(CGPoint(x: x, y: y), 0.55), with: .color(Color(Palette.lisStamen)))
        }
    }

    /// A glint: a star with a raspberry edge or a plain dot, at its brightness.
    private func shine(_ base: GraphicsContext, _ glint: Crown.Glint, _ brightness: Double) {
        let tone = Color(Palette.glitter[glint.tone]), spot = CGPoint(x: glint.x, y: glint.y)
        guard glint.star else {
            var dot = base
            dot.opacity *= brightness
            return dot.fill(circle(spot, glint.size), with: .color(tone))
        }
        sparkle(base, at: spot, width: glint.size, fill: tone, opacity: brightness)
    }
}

/// The fixed shapes of the crown's symbols (prototype v3): the rose's swirl, the carnation's three ruffles, the star.
enum Blooms {
    static let swirl = Path { path in
        path.move(to: CGPoint(x: -2.9, y: 0.6))
        let curves = [((3.1, 0.4), (-2.9, -2.9), (3.1, -3.1)), ((-1.1, 1.0), (3.1, 2.9), (-0.8, 3.3)),
                      ((1.1, 0.2), (-1.4, -0.7), (0.9, -1.1))]
        for (end, first, second) in curves {
            path.addCurve(to: CGPoint(x: end.0, y: end.1), control1: CGPoint(x: first.0, y: first.1),
                          control2: CGPoint(x: second.0, y: second.1))
        }
    }

    /// Three rings of teeth — 11, 8 and 6 points on radii 10.6, 6.9 and 3.4 — the carnation's paths, by formula.
    static let ruffles = [ruffle(11, outer: 10.6, inner: 8.4, from: -90), ruffle(8, outer: 6.9, inner: 5.2, from: -79),
                          ruffle(6, outer: 3.4, inner: 2.4, from: -85)]

    static let star = Path { path in
        path.move(to: CGPoint(x: 0, y: -11))
        for (end, control) in [((11.0, 0.0), (1.6, -1.6)), ((0, 11), (1.6, 1.6)), ((-11, 0), (-1.6, 1.6)),
                               ((0, -11), (-1.6, -1.6))] {
            path.addQuadCurve(to: CGPoint(x: end.0, y: end.1), control: CGPoint(x: control.0, y: control.1))
        }
        path.closeSubpath()
    }

    /// Teeth on a circle of `outer` from the angle `start`, each bent through `inner` halfway to the next.
    static func ruffle(_ count: Int, outer: Double, inner: Double, from start: Double) -> Path {
        let step = 360 / Double(count)
        let point = { (radius: Double, degrees: Double) in
            CGPoint(x: radius * cos(degrees * .pi / 180), y: radius * sin(degrees * .pi / 180))
        }
        return Path { path in
            path.move(to: point(outer, start))
            for index in 1...count {
                let degrees = start + Double(index) * step
                path.addQuadCurve(to: point(outer, degrees), control: point(inner, degrees - step / 2))
            }
            path.closeSubpath()
        }
    }
}
#endif
