import Foundation

public struct EvaluateMoveUseCase: Sendable {
    public init() {}

    public func execute(
        arrowID: UUID,
        board: inout PuzzleBoard,
        currentHearts: inout Int
    ) -> MoveOutcome {
        guard let arrow = board.arrow(withID: arrowID) else {
            return .ignored
        }

        if let blocker = board.firstBlocker(for: arrow) {
            currentHearts = max(0, currentHearts - 1)
            board.markFailed(arrowID: arrowID)
            return .blocked(
                arrow: arrow,
                blockerCell: blocker.cell,
                blockerArrowID: blocker.arrowID,
                remainingHearts: currentHearts,
                isGameOver: currentHearts == 0
            )
        } else {
            board.removeArrow(withID: arrowID)
            return .escaped(
                arrow: arrow,
                remainingCount: board.remainingCount,
                isLevelCleared: board.isCleared
            )
        }
    }
}
