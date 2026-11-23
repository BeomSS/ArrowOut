import Foundation

/// Serves handcrafted JSON levels when available (Levels 1–10) and seamlessly transitions
/// to the mask-aware `ProceduralLevelGenerator` for Level 11 and beyond.
public struct HybridLevelGenerator: LevelGeneratorProtocol, Sendable {
    private let handcraftedProvider: HandcraftedLevelProvider
    private let proceduralGenerator: ProceduralLevelGenerator
    private let solver: PuzzleSolver

    public init(
        handcraftedProvider: HandcraftedLevelProvider,
        proceduralGenerator: ProceduralLevelGenerator,
        solver: PuzzleSolver = PuzzleSolver()
    ) {
        self.handcraftedProvider = handcraftedProvider
        self.proceduralGenerator = proceduralGenerator
        self.solver = solver
    }

    public func generateBoard(config: LevelConfig) -> PuzzleBoard {
        if let handcrafted = handcraftedProvider.board(forLevel: config.levelNumber),
           solver.isSolvable(handcrafted) {
            return handcrafted
        }
        return proceduralGenerator.generateBoard(config: config)
    }
}
