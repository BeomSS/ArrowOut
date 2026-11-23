import Foundation

public struct Arrow: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    /// Ordered cells from tail (`cells.first`) to head (`cells.last`). Length >= 1.
    public let cells: [GridPoint]
    public let headDirection: Direction

    public var tail: GridPoint {
        cells[0]
    }

    public var head: GridPoint {
        cells[cells.count - 1]
    }

    public var isSingleCell: Bool {
        cells.count == 1
    }

    public var cellSet: Set<GridPoint> {
        Set(cells)
    }

    public init(
        id: UUID = UUID(),
        cells: [GridPoint],
        headDirection: Direction
    ) {
        precondition(!cells.isEmpty, "Arrow must span at least 1 grid cell.")
        self.id = id
        self.cells = cells
        self.headDirection = headDirection
    }
}
