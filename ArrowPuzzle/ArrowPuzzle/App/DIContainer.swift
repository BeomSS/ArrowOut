import Foundation

/// Composition root assembling Data -> Domain -> Presentation dependencies.
@MainActor
public final class DIContainer {
    private let solver: PuzzleSolver
    private let levelGenerator: LevelGeneratorProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let feedbackService: FeedbackServiceProtocol

    public init() {
        self.solver = PuzzleSolver()
        let handcraftedProvider = HandcraftedLevelProvider()
        let proceduralGenerator = ProceduralLevelGenerator(solver: solver)
        self.levelGenerator = HybridLevelGenerator(
            handcraftedProvider: handcraftedProvider,
            proceduralGenerator: proceduralGenerator,
            solver: solver
        )
        self.progressRepository = UserDefaultsProgressRepository()
        self.feedbackService = SystemFeedbackService()
    }

    public func makeGameViewModel() -> GameViewModel {
        let generateLevelUseCase = GenerateLevelUseCase(generator: levelGenerator, solver: solver)
        let evaluateMoveUseCase = EvaluateMoveUseCase()
        let findHintUseCase = FindHintUseCase()

        return GameViewModel(
            generateLevelUseCase: generateLevelUseCase,
            evaluateMoveUseCase: evaluateMoveUseCase,
            findHintUseCase: findHintUseCase,
            progressRepository: progressRepository,
            feedbackService: feedbackService
        )
    }
}
