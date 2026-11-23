import Foundation

public struct GridPoint: Hashable, Sendable, Codable, Equatable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func moved(by direction: Direction, steps: Int = 1) -> GridPoint {
        GridPoint(x: x + direction.dx * steps, y: y + direction.dy * steps)
    }

    public func manhattanDistance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }
}
