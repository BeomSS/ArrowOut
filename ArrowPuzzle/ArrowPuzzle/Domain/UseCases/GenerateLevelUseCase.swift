import Foundation

public struct GenerateLevelUseCase: Sendable {
    private let generator: LevelGeneratorProtocol
    private let solver: PuzzleSolver

    public init(generator: LevelGeneratorProtocol, solver: PuzzleSolver = PuzzleSolver()) {
        self.generator = generator
        self.solver = solver
    }

    public func execute(levelNumber: Int) -> (board: PuzzleBoard, config: LevelConfig) {
        let config = LevelConfig.forLevel(levelNumber)
        let board = generator.generateBoard(config: config)
        // Defensive guarantee: the procedural generator is mathematically acyclic,
        // and we verify solvability before returning.
        assert(solver.isSolvable(board), "Generated level \(levelNumber) must be solvable.")
        return (board, config)
    }
}
