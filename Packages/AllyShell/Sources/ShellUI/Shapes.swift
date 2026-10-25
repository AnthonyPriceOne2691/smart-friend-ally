#if canImport(SwiftUI)
import ShellCore
import SwiftUI

extension Color {
    /// A palette tone as a SwiftUI colour.
    init(_ tone: Tone, opacity: Double = 1) {
        self.init(.sRGB, red: tone.red, green: tone.green, blue: tone.blue, opacity: opacity)
    }
}

/// An ellipse centred at (x; y), turned by `degrees` around its centre — SVG's `<ellipse transform="rotate(…)">`.
func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ degrees: Double = 0) -> Path {
    let path = Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    return degrees == 0 ? path : path.applying(turn(degrees, around: CGPoint(x: x, y: y)))
}

func circle(_ centre: CGPoint, _ radius: Double) -> Path { ellipse(centre.x, centre.y, radius, radius) }

/// `rotate(degrees cx cy)` as an affine transform.
func turn(_ degrees: Double, around pivot: CGPoint) -> CGAffineTransform {
    CGAffineTransform(translationX: pivot.x, y: pivot.y).rotated(by: degrees * .pi / 180)
        .translatedBy(x: -pivot.x, y: -pivot.y)
}

/// Scale around a pivot.
func stretch(_ x: Double, _ y: Double, around pivot: CGPoint) -> CGAffineTransform {
    CGAffineTransform(translationX: pivot.x, y: pivot.y).scaledBy(x: x, y: y).translatedBy(x: -pivot.x, y: -pivot.y)
}

/// The four-pointed star of prototype v3 (`s-spark`) with its raspberry edge: the crown's glints, the night's stars,
/// the sky's glints.
func sparkle(_ base: GraphicsContext, at centre: CGPoint, width: Double, fill: Color, opacity: Double) {
    var ctx = base
    ctx.opacity *= opacity
    ctx.translateBy(x: centre.x, y: centre.y)
    ctx.scaleBy(x: width / 24, y: width / 24)
    ctx.fill(Blooms.star, with: .color(fill))
    ctx.stroke(Blooms.star, with: .color(Color(Palette.raspberry)),
               style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
}

/// A radial gradient from the centre outwards.
func glow(_ stops: [Gradient.Stop], at centre: CGPoint, radius: Double) -> GraphicsContext.Shading {
    .radialGradient(Gradient(stops: stops), center: centre, startRadius: 0, endRadius: radius)
}
#endif
