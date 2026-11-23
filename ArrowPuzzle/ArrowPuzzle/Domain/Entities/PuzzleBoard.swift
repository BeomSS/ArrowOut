import Foundation

public struct PuzzleBoard: Hashable, Sendable, Codable {
    public let levelNumber: Int
    public let width: Int
    public let height: Int
    public let shape: BoardShape
    public let concept: BoardConcept
    public let activeCells: Set<GridPoint>
    public let subtitle: String?
    public let isHandcrafted: Bool
    public let isHardChallenge: Bool
    public private(set) var arrows: [Arrow]
    public private(set) var failedArrowIDs: Set<UUID>
    public let totalArrowCount: Int

    public var remainingCount: Int {
        arrows.count
    }

    public var clearedCount: Int {
        totalArrowCount - arrows.count
    }

    public var isCleared: Bool {
        arrows.isEmpty
    }

    public init(
        levelNumber: Int,
        width: Int,
        height: Int,
        arrows: [Arrow],
        shape: BoardShape = .rectangle,
        concept: BoardConcept = .denseLabyrinth,
        activeCells: Set<GridPoint>? = nil,
        subtitle: String? = nil,
        isHandcrafted: Bool = false,
        isHardChallenge: Bool = false,
        failedArrowIDs: Set<UUID> = []
    ) {
        self.levelNumber = levelNumber
        self.width = width
        self.height = height
        self.shape = shape
        self.concept = concept
        self.activeCells = activeCells ?? shape.activeCells(width: width, height: height)
        self.subtitle = subtitle
        self.isHandcrafted = isHandcrafted
        self.isHardChallenge = isHardChallenge
        self.arrows = arrows
        self.failedArrowIDs = failedArrowIDs
        self.totalArrowCount = arrows.count
    }

    public func isInside(_ point: GridPoint) -> Bool {
        point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    }

    public func isActiveCell(_ point: GridPoint) -> Bool {
        activeCells.contains(point)
    }

    public func occupancyMap() -> [GridPoint: UUID] {
        var map: [GridPoint: UUID] = [:]
        map.reserveCapacity(activeCells.count)
        for arrow in arrows {
            for cell in arrow.cells {
                map[cell] = arrow.id
            }
        }
        return map
    }

    public func arrow(withID id: UUID) -> Arrow? {
        arrows.first { $0.id == id }
    }

    public func arrow(at point: GridPoint) -> Arrow? {
        arrows.first { $0.cells.contains(point) }
    }

    public func exitRay(for arrow: Arrow) -> [GridPoint] {
        var ray: [GridPoint] = []
        var cursor = arrow.head.moved(by: arrow.headDirection)
        while isInside(cursor) {
            ray.append(cursor)
            cursor = cursor.moved(by: arrow.headDirection)
        }
        return ray
    }

    public func firstBlocker(for arrow: Arrow, occupancy: [GridPoint: UUID]? = nil) -> (cell: GridPoint, arrowID: UUID)? {
        let map = occupancy ?? occupancyMap()
        var cursor = arrow.head.moved(by: arrow.headDirection)
        while isInside(cursor) {
            if let blockingID = map[cursor] {
                return (cursor, blockingID)
            }
            cursor = cursor.moved(by: arrow.headDirection)
        }
        return nil
    }

    public func canEscape(_ arrow: Arrow, occupancy: [GridPoint: UUID]? = nil) -> Bool {
        firstBlocker(for: arrow, occupancy: occupancy) == nil
    }

    public mutating func markFailed(arrowID: UUID) {
        failedArrowIDs.insert(arrowID)
    }

    public mutating func removeArrow(withID id: UUID) {
        arrows.removeAll { $0.id == id }
        failedArrowIDs.remove(id)
    }
}
