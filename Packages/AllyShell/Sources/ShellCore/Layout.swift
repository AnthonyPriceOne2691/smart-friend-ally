import Foundation

/// A point in screen points; plain Doubles, so the layout reads the same on Linux and Apple platforms.
public struct Point: Equatable, Sendable {
    public let x: Double, y: Double
}

/// A rectangle in screen points.
public struct Box: Equatable, Sendable {
    public let x: Double, y: Double, width: Double, height: Double

    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var maxY: Double { y + height }
}

/// Where the bubble sits on the child screen, in points: the formula of prototype v3 with screen rule 2 as its limits —
/// the side strips stay 24 pt wide and the bottom 140 pt stay free (children rest their wrists there); the circle is
/// never smaller than 240 pt. Rule 13: the adult's stop target lives in the top corner, under the safe area.
public struct Layout: Equatable, Sendable {
    public static let sideStrip = 24.0, freeBottom = 140.0, stopSide = 44.0, edge = 16.0

    public let width: Double, height: Double, safeTop: Double, safeBottom: Double

    public init(width: Double, height: Double, safeTop: Double = 0, safeBottom: Double = 0) {
        (self.width, self.height, self.safeTop, self.safeBottom) = (width, height, safeTop, safeBottom)
    }

    public var safeHeight: Double { height - safeTop - safeBottom }

    public var diameter: Double {
        max(240, min(width * 0.86, width - 2 * Layout.sideStrip, safeHeight * 0.58, 520))
    }

    /// 55% down the safe height, raised when the bottom 140 pt would not stay free.
    public var centre: Point {
        Point(x: width / 2, y: min(safeTop + safeHeight * 0.55, height - Layout.freeBottom - diameter / 2))
    }

    /// Points per unit of the character's grid: 400 units across the bubble.
    public var unit: Double { diameter / 400 }

    public var bottomGap: Double { height - centre.y - diameter / 2 }
    public var sideGap: Double { (width - diameter) / 2 }

    /// The adult's stop button (drawn in Ш3): 44 × 44 pt at the right edge, just under the safe area.
    public var stopTarget: Box {
        Box(x: width - Layout.edge - Layout.stopSide, y: safeTop, width: Layout.stopSide, height: Layout.stopSide)
    }
}
