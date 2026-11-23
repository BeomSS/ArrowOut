import Foundation

public struct DifficultyMetrics: Hashable, Sendable {
    /// Minimum number of sequential peeling waves required to clear the entire board.
    public let peelDepth: Int
    /// Number of arrows that can escape on Move 1.
    public let initialFreeCount: Int
    /// Fraction of arrows that can escape on Move 1 (`0.0...1.0`).
    public let initialFreeRatio: Double
    /// Largest single wave size during topological peeling.
    public let maxWaveSize: Int
}

/// Pure topological peel solver & difficulty analyzer using flat 1D occupancy grids
/// so even 50×50 boards (~450+ arrows) verify in sub-millisecond time.
public struct PuzzleSolver: Sendable {
    public init() {}

    public func isSolvable(_ board: PuzzleBoard) -> Bool {
        solveOrder(for: board) != nil
    }

    public func solveOrder(for board: PuzzleBoard) -> [UUID]? {
        let width = board.width
        let height = board.height
        var occupied = Array(repeating: false, count: width * height)
        for arrow in board.arrows {
            for cell in arrow.cells {
                occupied[cell.y * width + cell.x] = true
            }
        }

        var remaining = board.arrows
        var order: [UUID] = []
        order.reserveCapacity(remaining.count)

        while !remaining.isEmpty {
            var progressed = false
            var nextRemaining: [Arrow] = []
            nextRemaining.reserveCapacity(remaining.count)

            for arrow in remaining {
                if isEscapable(arrow, width: width, height: height, occupied: occupied) {
                    order.append(arrow.id)
                    for cell in arrow.cells {
                        occupied[cell.y * width + cell.x] = false
                    }
                    progressed = true
                } else {
                    nextRemaining.append(arrow)
                }
            }

            if !progressed {
                return nil
            }
            remaining = nextRemaining
        }
        return order
    }

    /// Computes wave-by-wave topological peel depth and initial bottleneck metrics.
    /// Returns `nil` if the board is unsolvable.
    public func analyzeDifficulty(of board: PuzzleBoard) -> DifficultyMetrics? {
        guard !board.arrows.isEmpty else {
            return DifficultyMetrics(peelDepth: 0, initialFreeCount: 0, initialFreeRatio: 0, maxWaveSize: 0)
        }

        let width = board.width
        let height = board.height
        var occupied = Array(repeating: false, count: width * height)
        for arrow in board.arrows {
            for cell in arrow.cells {
                occupied[cell.y * width + cell.x] = true
            }
        }

        var remaining = board.arrows
        var waves = 0
        var initialFree = 0
        var maxWave = 0

        while !remaining.isEmpty {
            var escapable: [Arrow] = []
            var nextRemaining: [Arrow] = []
            nextRemaining.reserveCapacity(remaining.count)

            for arrow in remaining {
                if isEscapable(arrow, width: width, height: height, occupied: occupied) {
                    escapable.append(arrow)
                } else {
                    nextRemaining.append(arrow)
                }
            }

            guard !escapable.isEmpty else {
                return nil
            }

            if waves == 0 {
                initialFree = escapable.count
            }
            waves += 1
            maxWave = max(maxWave, escapable.count)

            for arrow in escapable {
                for cell in arrow.cells {
                    occupied[cell.y * width + cell.x] = false
                }
            }
            remaining = nextRemaining
        }

        return DifficultyMetrics(
            peelDepth: waves,
            initialFreeCount: initialFree,
            initialFreeRatio: Double(initialFree) / Double(board.arrows.count),
            maxWaveSize: maxWave
        )
    }

    public func initialEscapableCount(in board: PuzzleBoard) -> Int {
        let width = board.width
        let height = board.height
        var occupied = Array(repeating: false, count: width * height)
        for arrow in board.arrows {
            for cell in arrow.cells {
                occupied[cell.y * width + cell.x] = true
            }
        }
        return board.arrows.filter {
            isEscapable($0, width: width, height: height, occupied: occupied)
        }.count
    }

    @inline(__always)
    private func isEscapable(
        _ arrow: Arrow,
        width: Int,
        height: Int,
        occupied: [Bool]
    ) -> Bool {
        let dx = arrow.headDirection.dx
        let dy = arrow.headDirection.dy
        var cx = arrow.head.x + dx
        var cy = arrow.head.y + dy
        while cx >= 0 && cx < width && cy >= 0 && cy < height {
            if occupied[cy * width + cx] {
                return false
            }
            cx += dx
            cy += dy
        }
        return true
    }
}
