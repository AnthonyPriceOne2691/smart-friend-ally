#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// Ellie's face on her head (prototype v3): blush, brows, eyes with two highlights and lashes or closed lids, and
/// a mouth that is always visible — a smile line over an opening with a tongue.
struct Face {
    let pose: Pose, frame: Frame

    func draw(_ ctx: GraphicsContext) {
        for side in [-1.0, 1.0] { cheek(ctx, side) }
        brows(ctx)
        for side in [-1.0, 1.0] { eye(ctx, side) }
        mouth(ctx)
    }

    private func cheek(_ base: GraphicsContext, _ side: Double) {
        var ctx = base
        ctx.opacity = pose.blush
        let blush = Palette.cheek, centre = CGPoint(x: side * 64, y: -10)
        let stops: [Gradient.Stop] = [.init(color: Color(blush, opacity: 0.58), location: 0),
                                      .init(color: Color(blush, opacity: 0.32), location: 0.55),
                                      .init(color: Color(blush, opacity: 0), location: 1)]
        ctx.fill(ellipse(centre.x, centre.y, 19, 11.5), with: glow(stops, at: centre, radius: 19))
    }

    private func brows(_ ctx: GraphicsContext) {
        let height = -74 + pose.browY + pose.eyeY * 0.5
        let lifts = [max(pose.browTilt, 0), -min(pose.browTilt, 0)]
        for (index, side) in [-1.0, 1.0].enumerated() {
            let place = CGAffineTransform(translationX: side * 40 + pose.eyeX * 0.3, y: height - lifts[index])
            ctx.stroke(Lines.brow.applying(place), with: .color(Color(Palette.brow)),
                       style: StrokeStyle(lineWidth: 3.8, lineCap: .round))
        }
    }

    private func eye(_ base: GraphicsContext, _ side: Double) {
        var ctx = base
        ctx.translateBy(x: side * 40 + pose.eyeX, y: -44 + pose.eyeY)
        var ball = ctx
        ball.opacity = frame.eyeballs
        ball.scaleBy(x: pose.eyeWide, y: pose.eyeWide * frame.eyeOpen)
        let iris = Gradient(stops: [.init(color: Color(Palette.eye), location: 0),
                                    .init(color: Color(Palette.eye), location: 0.62),
                                    .init(color: Color(Palette.eyeLow), location: 1)])
        ball.fill(ellipse(0, 0, 17, 20), with: .linearGradient(iris, startPoint: CGPoint(x: 0, y: -20),
                                                               endPoint: CGPoint(x: 0, y: 20)))
        ball.fill(ellipse(0, 10, 10, 6), with: .color(Color(Palette.eyeGlow, opacity: 0.5)))
        let shine = (x: -pose.eyeX * 0.35, y: -pose.eyeY * 0.35)
        ball.fill(ellipse(-5.5 + shine.x, -8 + shine.y, 6.5, 6.5), with: .color(.white))
        ball.fill(ellipse(6 + shine.x, 7 + shine.y, 3, 3), with: .color(.white))
        ball.stroke(Lines.lashes(side), with: .color(Color(Palette.eye)),
                    style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
        var lid = ctx
        lid.opacity = frame.lids
        lid.stroke(Lines.lid(side), with: .color(Color(Palette.eye)),
                   style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func mouth(_ base: GraphicsContext) {
        var ctx = base
        ctx.translateBy(x: pose.mouthX, y: -4)
        ctx.scaleBy(x: pose.mouthWidth, y: 1)
        var inside = ctx
        inside.scaleBy(x: 1, y: max(0.02, min(pose.mouthOpen, 1.2) * pose.mouthTall))
        inside.fill(ellipse(0, 6.5, 10, 7.5), with: .color(Color(Palette.mouth)))
        inside.fill(ellipse(1, 10, 6.2, 3.6), with: .color(Color(Palette.tongue)))
        let smile = 0.55 + 0.45 * pose.smile
        ctx.stroke(Lines.smile.applying(CGAffineTransform(scaleX: smile, y: smile)), with: .color(Color(Palette.mouth)),
                   style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
    }
}

/// The face's strokes (prototype v3).
enum Lines {
    static let brow = Path { path in
        path.move(to: CGPoint(x: -8, y: 2))
        path.addQuadCurve(to: CGPoint(x: 8, y: 2), control: CGPoint(x: 0, y: -2.5))
    }
    static let smile = Path { path in
        path.move(to: CGPoint(x: -11, y: 0))
        path.addQuadCurve(to: CGPoint(x: 11, y: 0), control: CGPoint(x: 0, y: 7))
    }

    /// Three lashes on the outer side of the eye: left eye — to the left, right eye — to the right.
    static func lashes(_ side: Double) -> Path {
        Path { path in
            for (start, end) in [((12.0, -14.0), (16.0, -20.0)), ((15, -9), (21, -12.5)), ((16.5, -3.5), (23, -4.5))] {
                path.move(to: CGPoint(x: start.0 * side, y: start.1))
                path.addLine(to: CGPoint(x: end.0 * side, y: end.1))
            }
        }
    }

    /// A closed eye: a soft arc and a little lash on the outer corner.
    static func lid(_ side: Double) -> Path {
        Path { path in
            path.move(to: CGPoint(x: -15, y: 0))
            path.addQuadCurve(to: CGPoint(x: 15, y: 0), control: CGPoint(x: 0, y: 10))
            path.move(to: CGPoint(x: 14 * side, y: 1))
            path.addLine(to: CGPoint(x: 20 * side, y: -2))
        }
    }
}
#endif
