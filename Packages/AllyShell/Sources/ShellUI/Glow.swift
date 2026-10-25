#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The glow round the bubble and the 28 pearls of listening (prototype v3, `.aura`, `.pearl`), and the lilac of
/// thinking in the water (`.tint-think`).
struct GlowArt {
    let light: Light, centre: CGPoint, diameter: Double

    /// Behind the bubble: the pink glow, then the pearls on their ring.
    func back(_ base: GraphicsContext) {
        var aura = base
        aura.opacity *= light.aura
        let reach = diameter * 0.74 * light.auraScale, pink = Color(Palette.aura)
        aura.fill(circle(centre, reach), with: glow([.init(color: pink.opacity(0.62), location: 0),
                                                      .init(color: pink.opacity(0.62), location: 0.58),
                                                      .init(color: pink.opacity(0.26), location: 0.77),
                                                      .init(color: pink.opacity(0), location: 1)],
                                                     at: centre, radius: reach))
        guard light.pearlsShown > 0.001 else { return }
        var pearls = base
        pearls.opacity *= light.pearlsShown
        let ring = diameter * Light.pearlRing
        for (index, size) in light.pearls.enumerated() {
            let angle = Double(index) * 2 * .pi / Double(Light.pearlCount)
            let radius = diameter * Light.pearlSize / 2 * size
            let spot = CGPoint(x: centre.x + ring * sin(angle), y: centre.y - ring * cos(angle))
            let shine = CGPoint(x: spot.x - radius * 0.3, y: spot.y - radius * 0.4)
            pearls.fill(circle(spot, radius), with: glow([.init(color: .white, location: 0),
                                                           .init(color: .white, location: 0.2),
                                                           .init(color: Color(Palette.pearl), location: 0.48),
                                                           .init(color: Color(Palette.raspberry), location: 1)],
                                                          at: shine, radius: radius * 1.91))
        }
    }

    /// The lilac of thinking: clear in the middle, lilac towards the edge of the water.
    func think(_ base: GraphicsContext) {
        guard light.think > 0.001 else { return }
        var ctx = base
        ctx.opacity *= light.think
        let lilac = Color(Palette.thinkTint)
        ctx.fill(circle(centre, diameter / 2), with: glow([.init(color: lilac.opacity(0), location: 0),
                                                            .init(color: lilac.opacity(0), location: 0.34),
                                                            .init(color: lilac, location: 1)],
                                                           at: CGPoint(x: centre.x, y: centre.y - diameter * 0.12),
                                                           radius: diameter * 0.796))
    }
}
#endif
