#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// Ellie drawn in the character's units (−200…200 around the bubble's centre) from one `Frame`: parts in their own
/// coordinates with pivots, like the groups of prototype v3 — head around (0; 30), shoulders (±50; 54), tail (48; 104),
/// torso (0; 146). The outline is painted under the fill, so about 3 units of line show outside every shape.
struct Axolotl {
    let frame: Frame
    /// Screen points per unit: the hairlines of the gills stay thin at any size.
    let unit: Double

    private var pose: Pose { frame.pose }

    func draw(_ base: GraphicsContext) {
        shadow(base)
        var ctx = base
        ctx.translateBy(x: 0, y: -8 + frame.rise)
        ctx.concatenate(turn(pose.lean, around: CGPoint(x: 0, y: 60)))
        let near = 1 + pose.near, squash = frame.squash  // a tap's squash rides the nearness (prototype `cGig`)
        ctx.concatenate(stretch(near * (1 - 0.75 * squash), near * (1 + squash), around: CGPoint(x: 0, y: 40)))
        tail(ctx)
        skin(ctx, ellipse(-30, 141, 21, 13))
        skin(ctx, ellipse(30, 141, 21, 13))
        torso(ctx)
        head(ctx)
        arm(ctx, shoulder: -50, angle: pose.armLeft)
        arm(ctx, shoulder: 50, angle: pose.armRight)
    }

    private func shadow(_ base: GraphicsContext) {
        var ctx = base
        ctx.concatenate(stretch(frame.shadowScale, 1 + (frame.shadowScale - 1) * 0.8, around: CGPoint(x: 0, y: 162)))
        ctx.opacity = frame.shadowOpacity
        let ground = Palette.ground
        ctx.fill(ellipse(0, 162, 72, 13), with: glow([.init(color: Color(ground, opacity: 0.34), location: 0),
                                                       .init(color: Color(ground, opacity: 0), location: 1)],
                                                      at: CGPoint(x: 0, y: 162), radius: 72))
    }

    /// Skin: the outline under a radial gradient that starts at the upper left of the shape's box.
    private func skin(_ ctx: GraphicsContext, _ path: Path) {
        let box = path.boundingRect
        ctx.stroke(path, with: .color(Color(Palette.line)), style: StrokeStyle(lineWidth: 6.5, lineJoin: .round))
        ctx.fill(path, with: glow([.init(color: Color(Palette.skinLight), location: 0),
                                   .init(color: Color(Palette.skin), location: 0.55),
                                   .init(color: Color(Palette.skinShade), location: 1)],
                                  at: CGPoint(x: box.minX + box.width * 0.36, y: box.minY + box.height * 0.3),
                                  radius: max(box.width, box.height) * 0.78))
    }

    private func tail(_ base: GraphicsContext) {
        var ctx = base
        ctx.concatenate(turn(frame.tail, around: CGPoint(x: 48, y: 104)))
        let fin = ellipse(82, 78, 30, 10, -40)
        ctx.fill(fin, with: .color(Color(Palette.gillLilac, opacity: 0.75)))
        ctx.stroke(fin, with: .color(Color(Palette.line)), lineWidth: 2)
        skin(ctx, ellipse(78, 94, 38, 17, -38))
    }

    private func torso(_ base: GraphicsContext) {
        var ctx = base
        ctx.concatenate(stretch(1 - frame.breath * 0.5, 1 + frame.breath, around: CGPoint(x: 0, y: 146)))
        skin(ctx, ellipse(0, 84, 64, 58))
        ctx.fill(ellipse(0, 98, 42, 38), with: glow([.init(color: Color(Palette.bellyLight), location: 0),
                                                      .init(color: Color(Palette.belly), location: 1)],
                                                     at: CGPoint(x: -6.7, y: 86.6), radius: 60))
        ctx.fill(ellipse(0, 40, 54, 18), with: glow([.init(color: Color(Palette.shade, opacity: 0.4), location: 0),
                                                      .init(color: Color(Palette.shade, opacity: 0), location: 1)],
                                                     at: CGPoint(x: 0, y: 34.6), radius: 40))
    }

    private func head(_ base: GraphicsContext) {
        var ctx = base
        ctx.translateBy(x: pose.headX, y: pose.headY - frame.breath * 90)
        ctx.concatenate(turn(pose.headTilt, around: CGPoint(x: 0, y: 30)))
        gills(ctx)
        skin(ctx, ellipse(0, -40, 100, 80))
        var gloss = ctx
        gloss.opacity = 0.55
        gloss.fill(ellipse(-38, -88, 40, 18, -18), with: glow([.init(color: .white.opacity(0.9), location: 0),
                                                               .init(color: .white.opacity(0), location: 1)],
                                                              at: CGPoint(x: -38, y: -88), radius: 40))
        Face(pose: pose, frame: frame).draw(ctx)
        CrownArt(glints: frame.glints).draw(ctx)
    }

    private func gills(_ ctx: GraphicsContext) {
        let hair = 1 / unit, gradient = Gradient(stops: [.init(color: Color(Palette.gillPink), location: 0),
                                                         .init(color: Color(Palette.gillPeach), location: 0.55),
                                                         .init(color: Color(Palette.gillLilac), location: 1)])
        for (index, gill) in Gill.all.enumerated() {
            let size = frame.gillScales[index]
            var place = CGAffineTransform(translationX: gill.x, y: gill.y)
            if gill.side > 0 { place = place.scaledBy(x: -1, y: 1) }
            place = place.rotated(by: (gill.base + frame.gills[index]) * .pi / 180)
                .scaledBy(x: gill.length * size, y: 1.3 * size.squareRoot())
            let shape = Feather.shape.applying(place)
            ctx.fill(shape, with: .linearGradient(gradient, startPoint: CGPoint.zero.applying(place),
                                                  endPoint: CGPoint(x: 42, y: 0).applying(place)))
            ctx.stroke(shape, with: .color(Color(Palette.line)),
                       style: StrokeStyle(lineWidth: 1.6 * hair, lineJoin: .round))
            ctx.stroke(Feather.vein.applying(place), with: .color(.white.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 1.4 * hair, lineCap: .round))
            ctx.stroke(Feather.barbs.applying(place), with: .color(.white.opacity(0.5)),
                       style: StrokeStyle(lineWidth: hair, lineCap: .round))
        }
    }

    private func arm(_ base: GraphicsContext, shoulder x: Double, angle: Double) {
        var ctx = base
        ctx.translateBy(x: x, y: 54 - frame.breath * 90)
        ctx.rotate(by: .degrees(angle))
        for finger in [-7.5, -2.6, 2.6, 7.5] { skin(ctx, ellipse(finger, abs(finger) > 5 ? 36.5 : 39.8, 3.9, 3.9)) }
        skin(ctx, ellipse(0, 19, 12.5, 21))
        ctx.fill(ellipse(0, 31, 7, 5), with: .color(Color(Palette.belly, opacity: 0.75)))
    }
}

/// The shapes of one gill (prototype v3): a feather with a pale central vein and four barbs.
enum Feather {
    static let shape = Path { path in
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: 36, y: -8), control1: CGPoint(x: 8, y: -12), control2: CGPoint(x: 26, y: -15))
        path.addCurve(to: CGPoint(x: 36, y: 8), control1: CGPoint(x: 42, y: -3), control2: CGPoint(x: 42, y: 4))
        path.addCurve(to: .zero, control1: CGPoint(x: 26, y: 14), control2: CGPoint(x: 8, y: 11))
        path.closeSubpath()
    }
    static let vein = Path { path in
        path.move(to: CGPoint(x: 4, y: 0))
        path.addQuadCurve(to: CGPoint(x: 38, y: -0.5), control: CGPoint(x: 20, y: -1))
    }
    static let barbs = Path { path in
        let pairs = [((15.0, -1.0), (23.0, -8.0)), ((15, 0), (23, 7)), ((25, -1), (31, -6)), ((25, 0), (31, 5))]
        for (start, end) in pairs {
            path.move(to: CGPoint(x: start.0, y: start.1))
            path.addLine(to: CGPoint(x: end.0, y: end.1))
        }
    }
}
#endif
