import Foundation

/// The flower crown of prototype v3 (`<g id="crown">`, approved by the parent 2026-10-17: «на голове пустовато»): three
/// rows of roses, carnations and lisianthus on 22 leaves, strewn with 56 glints that twinkle each at its own tempo. The
/// numbers are the prototype's own; `scale` about `pivot` seats the crown on her head between the top gills, and it
/// turns with the head.
public enum Crown {
    public enum Kind: Sendable { case rose, carnation, lisianthus }

    /// A flower: its kind, its centre and the width of its 24-unit symbol (given as the SVG's box corner).
    public struct Flower: Sendable {
        public let kind: Kind, x: Double, y: Double, width: Double

        init(_ kind: Kind, _ left: Double, _ top: Double, _ width: Double) {
            (self.kind, x, y, self.width) = (kind, left + width / 2, top + width / 2, width)
        }
    }

    /// A leaf of `leafLength` × `leafWidth`: its centre, its turn in degrees, the darker green or the lighter one.
    public struct Leaf: Sendable {
        public let x: Double, y: Double, turn: Double, dark: Bool

        init(_ x: Double, _ y: Double, _ turn: Double, _ dark: Bool) {
            (self.x, self.y, self.turn, self.dark) = (x, y, turn, dark)
        }
    }

    /// A glint: a four-pointed star of width `size` (given as the SVG's box corner) or a dot of radius `size`; its
    /// tone is an index into `Palette.glitter` — white, gold, pink.
    public struct Glint: Sendable {
        public let star: Bool, tone: Int, x: Double, y: Double, size: Double

        init(_ star: Bool, _ tone: Int, _ x: Double, _ y: Double, _ size: Double) {
            let corner = star ? size / 2 : 0
            (self.star, self.tone, self.x, self.y, self.size) = (star, tone, x + corner, y + corner, size)
        }
    }

    /// The seat on her head: 0.8 about (0; −120) in head units; leaves are ellipses of 8.2 × 3.8.
    public static let scale = 0.8, pivotY = -120.0, leafLength = 8.2, leafWidth = 3.8

    /// In the prototype's order: the back row first, the front row last.
    public static let flowers = [
        Flower(.rose, -78.5, -119.2, 18.8), Flower(.carnation, -58.3, -132.9, 19.8),
        Flower(.lisianthus, -35.3, -141.6, 20.8), Flower(.rose, -9.4, -143.4, 18.8),
        Flower(.carnation, 15, -141.1, 19.8), Flower(.lisianthus, 38, -133.4, 20.8), Flower(.rose, 59.7, -119.2, 18.8),
        Flower(.carnation, -80.3, -104, 17.6), Flower(.lisianthus, -63.6, -118.6, 18.5),
        Flower(.rose, -43.6, -129, 19.4), Flower(.carnation, -20.3, -133.1, 17.6),
        Flower(.lisianthus, 2.3, -133.6, 18.5), Flower(.rose, 24.2, -129, 19.4), Flower(.carnation, 45.5, -118.2, 17.6),
        Flower(.lisianthus, 62.3, -104.5, 18.5), Flower(.lisianthus, -67.4, -101.5, 15),
        Flower(.rose, -49.7, -114.1, 15.8), Flower(.carnation, -30.7, -121.6, 16.6),
        Flower(.lisianthus, -7.5, -123.5, 15), Flower(.rose, 14.4, -121.2, 15.8),
        Flower(.carnation, 33.5, -114.5, 16.6), Flower(.lisianthus, 52.4, -101.5, 15)
    ]

    public static let leaves = [
        Leaf(-77.8, -111.5, -79.4, false), Leaf(-63.1, -85.3, -15.4, true), Leaf(-62.9, -122.9, -5.4, true),
        Leaf(-53, -94.5, -69.4, false), Leaf(-46.2, -131.6, -59.7, false), Leaf(-41.3, -101.9, 4.3, true),
        Leaf(-28.3, -137.6, 13.7, true), Leaf(-28.3, -107.5, -50.3, false), Leaf(-9.5, -140.6, -41.1, false),
        Leaf(-14.4, -110.9, 22.9, true), Leaf(9.5, -140.6, 32, true), Leaf(0, -112, -32, false),
        Leaf(28.3, -137.6, -22.9, false), Leaf(14.4, -110.9, 41.1, true), Leaf(46.2, -131.6, 50.3, true),
        Leaf(28.3, -107.5, -13.7, false), Leaf(62.9, -122.9, -4.3, false), Leaf(41.3, -101.9, 59.7, true),
        Leaf(77.8, -111.5, 69.4, true), Leaf(53, -94.5, 5.4, false), Leaf(90.4, -97.8, 15.4, false),
        Leaf(63.1, -85.3, 79.4, true)
    ]

    /// In the prototype's order, which also gives each glint its tempo and phase (`twinkle`).
    public static let glints = [
        Glint(false, 0, -8.5, -128.6, 2.81), Glint(true, 1, -12.6, -141.2, 6.5), Glint(true, 1, -55.7, -116.5, 6.5),
        Glint(true, 2, -63.7, -102, 5.5), Glint(true, 0, 4.8, -142, 5.5), Glint(false, 1, 16.1, -122.4, 2.81),
        Glint(true, 1, 24.3, -130.4, 6.5), Glint(true, 2, 20.8, -138, 5.5), Glint(true, 0, -65.8, -96.3, 6.5),
        Glint(true, 1, 15, -138.1, 7.5), Glint(false, 1, -11.5, -137.4, 2.03), Glint(true, 2, 21.5, -126.9, 5.5),
        Glint(true, 0, -9.7, -122.4, 5.5), Glint(true, 1, 30.3, -118.5, 6.5), Glint(true, 1, -0.8, -114.7, 5.5),
        Glint(false, 2, -19.2, -136.5, 2.81), Glint(true, 0, -60.7, -92.4, 5.5), Glint(true, 1, -57, -130.2, 5.5),
        Glint(true, 1, -10.5, -146.7, 9), Glint(true, 2, -17.5, -131.4, 6.5), Glint(false, 0, 43.4, -109.4, 1.72),
        Glint(true, 1, -32.1, -111.6, 9), Glint(true, 1, 35.2, -109.7, 6.5), Glint(true, 2, 25.6, -110.6, 9),
        Glint(true, 0, 41.4, -108.7, 6.5), Glint(false, 1, -8.3, -116.7, 2.03), Glint(true, 1, -18.1, -126.9, 9),
        Glint(true, 2, -16.4, -120.7, 7.5), Glint(true, 0, 64.4, -124.6, 7.5), Glint(true, 1, 61.1, -86.5, 6.5),
        Glint(false, 1, -20.4, -136.6, 1.72), Glint(true, 2, -67.9, -94.7, 9), Glint(true, 0, -48.2, -130.4, 7.5),
        Glint(true, 1, 49.8, -111.3, 5.5), Glint(true, 1, -70.4, -109, 6.5), Glint(false, 2, -71.4, -92.2, 2.81),
        Glint(true, 0, -65.4, -113.1, 6.5), Glint(true, 1, 50.5, -103.2, 6.5), Glint(true, 1, -33, -116.9, 6.5),
        Glint(true, 2, 31.1, -112.8, 6.5), Glint(false, 0, 31, -118.6, 2.81), Glint(true, 1, 14.8, -125.7, 5.5),
        Glint(true, 1, -66.9, -109.8, 7.5), Glint(true, 2, -50.6, -126.9, 7.5), Glint(true, 0, -20, -143.4, 9),
        Glint(false, 1, -31.8, -111.1, 1.72), Glint(true, 1, -63, -109.7, 5.5), Glint(true, 2, -45.5, -135.8, 6.5),
        Glint(true, 0, 32.1, -110.1, 9), Glint(true, 1, -11.5, -115.8, 6.5), Glint(false, 1, -37.5, -121.1, 2.03),
        Glint(true, 2, -62.3, -99.5, 9), Glint(true, 0, 74.5, -102.1, 6.5), Glint(true, 1, 13.2, -143.7, 9),
        Glint(true, 1, 66.9, -111.3, 5.5), Glint(false, 2, -77.1, -98.7, 2.81)
    ]

    /// How bright glint `index` is at `t` (prototype v3, `glitF` and `glitP`): 0.35…1 at its own tempo; Reduce Motion
    /// keeps a steady 0.8.
    public static func twinkle(_ index: Int, at t: Double, calm: Bool = false) -> Double {
        guard !calm else { return 0.8 }
        let phase = hash(Double(index) + 77) * 2 * .pi
        return 0.35 + 0.65 * (0.5 + 0.5 * sin(t * tempo(index) + phase))
    }

    /// A glint's tempo, rad/s: 1.4…3.2 — a period of 2–4.5 s, far below three flashes a second (screen rule 10).
    public static func tempo(_ index: Int) -> Double { 1.4 + 1.8 * hash(Double(index) + 41) }

    /// The prototype's `hash`: a fixed pseudo-random number in [0, 1) for n.
    static func hash(_ n: Double) -> Double {
        let wave = sin(n * 127.1 + 311.7) * 43_758.545_312_3
        return wave - floor(wave)
    }
}
