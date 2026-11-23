import Foundation

public enum Direction: Int, CaseIterable, Hashable, Sendable, Codable {
    case up = 0
    case right = 1
    case down = 2
    case left = 3

    public var dx: Int {
        switch self {
        case .up, .down: return 0
        case .right: return 1
        case .left: return -1
        }
    }

    public var dy: Int {
        switch self {
        case .up: return 1
        case .down: return -1
        case .left, .right: return 0
        }
    }

    public var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    public var turnedClockwise: Direction {
        switch self {
        case .up: return .right
        case .right: return .down
        case .down: return .left
        case .left: return .up
        }
    }

    public var turnedCounterClockwise: Direction {
        switch self {
        case .up: return .left
        case .left: return .down
        case .down: return .right
        case .right: return .up
        }
    }

    /// Angle in radians where `.right` is 0, `.up` is pi/2 (matching SpriteKit coordinates).
    public var radians: Double {
        switch self {
        case .right: return 0
        case .up: return .pi / 2
        case .left: return .pi
        case .down: return -.pi / 2
        }
    }

    public static func from(from start: GridPoint, to end: GridPoint) -> Direction? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        switch (dx, dy) {
        case (0, 1): return .up
        case (0, -1): return .down
        case (1, 0): return .right
        case (-1, 0): return .left
        default: return nil
        }
    }
}
