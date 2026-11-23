import Foundation

public enum MoveOutcome: Sendable, Equatable {
    case escaped(arrow: Arrow, remainingCount: Int, isLevelCleared: Bool)
    case blocked(arrow: Arrow, blockerCell: GridPoint, blockerArrowID: UUID, remainingHearts: Int, isGameOver: Bool)
    case ignored
}
