import Foundation

public struct FindHintUseCase: Sendable {
    public init() {}

    /// Picks the most helpful escapable arrow — preferring one that unblocks the most other arrows.
    public func execute(in board: PuzzleBoard) -> Arrow? {
        let occupancy = board.occupancyMap()
        let escapable = board.arrows.filter { board.canEscape($0, occupancy: occupancy) }
        guard !escapable.isEmpty else { return nil }

        // Score each escapable arrow by how many other arrows become newly escapable once removed.
        var bestArrow = escapable[0]
        var bestScore = -1

        for candidate in escapable {
            var nextOccupancy = occupancy
            for cell in candidate.cells {
                nextOccupancy.removeValue(forKey: cell)
            }
            var newlyUnlocked = 0
            for other in board.arrows where other.id != candidate.id {
                if !board.canEscape(other, occupancy: occupancy) &&
                    board.canEscape(other, occupancy: nextOccupancy) {
                    newlyUnlocked += 1
                }
            }
            // Tie-break by longer arrow (usually visually clears more board space).
            let score = newlyUnlocked * 100 + candidate.cells.count
            if score > bestScore {
                bestScore = score
                bestArrow = candidate
            }
        }
        return bestArrow
    }
}
