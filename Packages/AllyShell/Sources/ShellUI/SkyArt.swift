#if canImport(SwiftUI)
import ShellCore
import SwiftUI

/// The pink sky of app-glass (the parent 2026-10-27): the palette's gradient from sky blue through lilac haze and pink
/// to peach, and its lights; behind the child's bubble and behind the parent's console alike.
enum SkyArt {
    static func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let full = Path(CGRect(origin: .zero, size: size))
        let stops = Palette.sky.map { Gradient.Stop(color: Color($0.tone), location: $0.at) }
        ctx.fill(full, with: .linearGradient(Gradient(stops: stops), startPoint: .zero,
                                             endPoint: CGPoint(x: 0, y: size.height)))
        for light in Palette.skyLights {
            let colour = Color(light.tone, opacity: light.opacity)
            ctx.fill(full, with: glow([.init(color: colour, location: 0), .init(color: colour.opacity(0), location: 1)],
                                      at: CGPoint(x: light.x * size.width, y: light.y * size.height),
                                      radius: light.reach * size.width))
        }
    }
}

/// The parent's screen in the same sky, in plum words (app-glass): the console puts its column on it.
public struct AdultSky<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content.foregroundStyle(Color(Palette.plum))
            .background { Canvas { ctx, size in SkyArt.draw(ctx, size) }.ignoresSafeArea() }
    }
}

extension View {
    /// A card of clear glass with a breath of white behind the view (the console's lines): the words stay on the view,
    /// the glass is only the card under them.
    public func glassCard() -> some View {
        let card = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background { card.fill(.clear).glassEffect(.regular.tint(.white.opacity(0.2)), in: card) }
    }
}
#endif
