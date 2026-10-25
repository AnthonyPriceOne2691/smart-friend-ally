import Foundation

/// A colour as 0xRRGGBB in sRGB, with the WCAG 2.1 relative luminance and contrast ratio (screen rule 9).
public struct Tone: Hashable, Sendable {
    public let rgb: UInt32

    public init(_ rgb: UInt32) { self.rgb = rgb }

    public var red: Double { Double((rgb >> 16) & 0xFF) / 255 }
    public var green: Double { Double((rgb >> 8) & 0xFF) / 255 }
    public var blue: Double { Double(rgb & 0xFF) / 255 }

    public var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    public func contrast(with other: Tone) -> Double {
        let (light, dark) = (max(luminance, other.luminance), min(luminance, other.luminance))
        return (light + 0.05) / (dark + 0.05)
    }
}

/// A line and the fill it borders: the pairs rule 9 holds to 3:1.
public struct Border: Sendable {
    public let line: Tone, fill: Tone

    public init(_ line: Tone, on fill: Tone) { (self.line, self.fill) = (line, fill) }
}

/// The tokens of prototype v3, approved by the parent 2026-10-17: pink only as fills, plum and raspberry lines.
public enum Palette {
    public static let skyTop = Tone(0xFFF6FA), skyMid = Tone(0xFFE6F1), skyLow = Tone(0xFCD2E5)
    public static let skyLilac = Tone(0xEFDDFF), skyPeach = Tone(0xFFE3D9), blossom = Tone(0xFFF0F5)
    public static let plum = Tone(0x5E1A42), raspberry = Tone(0xC2185B), line = Tone(0xB4487A)
    public static let skinLight = Tone(0xFFC4D8), skin = Tone(0xF98AAF), skinShade = Tone(0xE2739A)
    public static let bellyLight = Tone(0xFFF4F7), belly = Tone(0xFFE6EE), cheek = Tone(0xFF6FA0)
    public static let eye = Tone(0x2E2A4F), eyeLow = Tone(0x47426E), eyeGlow = Tone(0x8C8FD8), brow = Tone(0xB79BE0)
    public static let mouth = Tone(0x7A2F57), tongue = Tone(0xFF8FB0), shade = Tone(0xD9709A), ground = Tone(0x6F9FC4)
    public static let gillPink = Tone(0xFF9CC4), gillPeach = Tone(0xFFC9A8), gillLilac = Tone(0xC9B3FF)
    public static let waterCore = Tone(0xE9FAFF), water = Tone(0xDDF7FF), waterEdge = Tone(0xCFF3FF)
    public static let band = Tone(0xB8EAFB)
    public static let film = [Tone(0xFFB9D9), Tone(0xD9C6FF), Tone(0xBDEBFF), Tone(0xFFF0C2)]
    /// The crown: rose petals and middle, the carnation's three ruffles and their line, the lisianthus with its heart
    /// and stamens, two greens of the leaves, the glints in white, gold and pink (outlines — `line`, the rose's swirl
    /// — `raspberry`).
    public static let roseOut = Tone(0xFF9CC4), roseMid = Tone(0xFF7DB0), carnOut = Tone(0xFFC3DA)
    public static let carnIn = Tone(0xFF9DC6), carnCore = Tone(0xF577AE), carnLine = Tone(0xE0559A)
    public static let lisOut = Tone(0xF9D0EC), lisIn = Tone(0xEBA7D9), lisCore = Tone(0xFFF6D6)
    public static let lisStamen = Tone(0x9CCB8F), leaf = Tone(0x8FD9B6), leafDark = Tone(0x6FC4A2)
    public static let glitter = [Tone(0xFFFFFF), Tone(0xFFE08A), Tone(0xFFD1EC)]
    /// The light (Ш2б): night in the water, the veil's two lilacs, the moon, the lilac of thinking, the glow and the
    /// pearls of listening, the line of a water bubble.
    public static let nightHigh = Tone(0xB9A7F0), nightMid = Tone(0x8E7AD8), nightLow = Tone(0x6A57BC)
    public static let veilTop = Tone(0x442C88), veilLow = Tone(0x825AB0), moon = Tone(0xFFF1B8)
    public static let thinkTint = Tone(0xD7C6FF), aura = Tone(0xFF96C6), pearl = Tone(0xFF8FC0)
    public static let waterLine = Tone(0x60B0D6)

    /// Every line the drawing puts on a fill: eyes and mouth on the skin, her outline on the water, the rim on the sky.
    public static let borders = [
        Border(eye, on: skin), Border(mouth, on: skin), Border(line, on: water), Border(line, on: waterEdge),
        Border(raspberry, on: skyMid), Border(raspberry, on: skyLow), Border(plum, on: blossom)
    ]
}
