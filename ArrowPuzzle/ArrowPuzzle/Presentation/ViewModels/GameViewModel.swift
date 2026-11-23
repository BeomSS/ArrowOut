import Combine
import Foundation
import SwiftUI

public enum GamePhase: Equatable {
    case playing
    case transitioning
    case levelComplete
    case gameOver
}

@MainActor
public final class GameViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published public private(set) var levelNumber: Int = 1
    @Published public private(set) var highestUnlockedLevel: Int = 1
    @Published public private(set) var hearts: Int = 5
    @Published public private(set) var maxHearts: Int = 5
    @Published public private(set) var remainingArrows: Int = 0
    @Published public private(set) var totalArrows: Int = 0
    @Published public private(set) var gridDimensionsText: String = "3×3"
    @Published public private(set) var boardShape: BoardShape = .rectangle
    @Published public private(set) var levelSubtitle: String?
    @Published public private(set) var isHandcraftedLevel: Bool = false
    @Published public private(set) var isHardChallenge: Bool = false
    @Published public private(set) var phase: GamePhase = .playing
    @Published public private(set) var mistakesCount: Int = 0
    @Published public private(set) var hintsUsedCount: Int = 0
    @Published public private(set) var elapsedSeconds: Int = 0
    @Published public private(set) var comboCount: Int = 0

    @Published public private(set) var isSoundEnabled: Bool = true
    @Published public private(set) var isHapticsEnabled: Bool = true
    @Published public private(set) var isDarkTheme: Bool = false
    #if DEBUG
    @Published public var isLevelSheetPresented: Bool = false
    #endif

    public var theme: AppTheme {
        AppTheme(isDark: isDarkTheme)
    }

    public var clearProgress: Double {
        guard totalArrows > 0 else { return 0 }
        return Double(totalArrows - remainingArrows) / Double(totalArrows)
    }

    // MARK: - Scene
    public let scene: PuzzleBoardScene

    // MARK: - Clean Architecture Dependencies
    private let generateLevelUseCase: GenerateLevelUseCase
    private let evaluateMoveUseCase: EvaluateMoveUseCase
    private let findHintUseCase: FindHintUseCase
    private let progressRepository: ProgressRepositoryProtocol
    private let feedbackService: FeedbackServiceProtocol

    // MARK: - Internal State
    private var board: PuzzleBoard?
    private var progress: UserProgress
    private var levelStartDate: Date = Date()
    private var accumulatedElapsedSeconds: Int = 0
    private var lastEscapeDate: Date = .distantPast
    private var activeHintArrowID: UUID?

    // Race-free phase transition & background next-level prefetching
    private var pendingPhaseTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var prefetchedLevel: (levelNumber: Int, board: PuzzleBoard, config: LevelConfig)?

    public init(
        generateLevelUseCase: GenerateLevelUseCase,
        evaluateMoveUseCase: EvaluateMoveUseCase,
        findHintUseCase: FindHintUseCase,
        progressRepository: ProgressRepositoryProtocol,
        feedbackService: FeedbackServiceProtocol
    ) {
        self.generateLevelUseCase = generateLevelUseCase
        self.evaluateMoveUseCase = evaluateMoveUseCase
        self.findHintUseCase = findHintUseCase
        self.progressRepository = progressRepository
        self.feedbackService = feedbackService

        let loaded = progressRepository.loadProgress()
        self.progress = loaded
        self.levelNumber = loaded.currentLevel
        self.highestUnlockedLevel = loaded.highestUnlockedLevel
        self.isSoundEnabled = loaded.isSoundEnabled
        self.isHapticsEnabled = loaded.isHapticsEnabled
        self.isDarkTheme = loaded.isDarkTheme

        self.feedbackService.isSoundEnabled = loaded.isSoundEnabled
        self.feedbackService.isHapticsEnabled = loaded.isHapticsEnabled

        self.scene = PuzzleBoardScene(size: CGSize(width: 390, height: 844))
        self.scene.interactionDelegate = self

        // Resume saved mid-level session if valid for the current level
        if let saved = progressRepository.loadSavedSession(),
           saved.board.levelNumber == loaded.currentLevel,
           !saved.board.isCleared,
           saved.hearts > 0 {
            restoreSavedSession(saved)
        } else {
            startLevel(loaded.currentLevel)
        }
    }

    // MARK: - User Actions

    public func startLevel(_ level: Int) {
        pendingPhaseTask?.cancel()
        pendingPhaseTask = nil

        let clamped = max(1, level)
        let generated: (board: PuzzleBoard, config: LevelConfig)
        if let cached = prefetchedLevel, cached.levelNumber == clamped {
            generated = (cached.board, cached.config)
            prefetchedLevel = nil
        } else {
            generated = generateLevelUseCase.execute(levelNumber: clamped)
        }

        progressRepository.clearSavedSession()
        applyBoardState(
            board: generated.board,
            hearts: generated.config.maxHearts,
            maxHearts: generated.config.maxHearts,
            isHard: generated.board.isHardChallenge || generated.config.isHardChallenge,
            mistakes: 0,
            hintsUsed: 0,
            priorElapsedSeconds: 0
        )

        progress.currentLevel = clamped
        progressRepository.saveProgress(progress)

        schedulePrefetch(for: clamped + 1)
    }

    public func restartCurrentLevel() {
        feedbackService.playButtonTap()
        progressRepository.clearSavedSession()
        startLevel(levelNumber)
    }

    public func advanceToNextLevel() {
        feedbackService.playButtonTap()
        startLevel(levelNumber + 1)
    }

    public func requestHint() {
        guard phase == .playing, let currentBoard = board else { return }
        guard let suggested = findHintUseCase.execute(in: currentBoard) else { return }

        if activeHintArrowID != suggested.id {
            hintsUsedCount += 1
            activeHintArrowID = suggested.id
            persistCurrentSession()
        }
        feedbackService.playHint()
        scene.highlightHint(arrowID: suggested.id)
    }

    public func resetCamera() {
        feedbackService.playButtonTap()
        scene.fitCameraToBoard(animated: true)
    }

    public func toggleSound() {
        isSoundEnabled.toggle()
        feedbackService.isSoundEnabled = isSoundEnabled
        progress.isSoundEnabled = isSoundEnabled
        progressRepository.saveProgress(progress)
        feedbackService.playButtonTap()
    }

    public func toggleHaptics() {
        isHapticsEnabled.toggle()
        feedbackService.isHapticsEnabled = isHapticsEnabled
        progress.isHapticsEnabled = isHapticsEnabled
        progressRepository.saveProgress(progress)
        feedbackService.playButtonTap()
    }

    public func toggleTheme() {
        isDarkTheme.toggle()
        progress.isDarkTheme = isDarkTheme
        progressRepository.saveProgress(progress)
        feedbackService.playButtonTap()
        scene.applyTheme(theme)
    }

    // MARK: - Session Restore & Prefetch

    private func restoreSavedSession(_ session: SavedGameSession) {
        let config = LevelConfig.forLevel(session.board.levelNumber)
        applyBoardState(
            board: session.board,
            hearts: session.hearts,
            maxHearts: session.maxHearts,
            isHard: session.board.isHardChallenge || config.isHardChallenge,
            mistakes: session.mistakesCount,
            hintsUsed: session.hintsUsedCount,
            priorElapsedSeconds: session.elapsedSeconds
        )
        schedulePrefetch(for: session.board.levelNumber + 1)
    }

    private func applyBoardState(
        board newBoard: PuzzleBoard,
        hearts: Int,
        maxHearts: Int,
        isHard: Bool,
        mistakes: Int,
        hintsUsed: Int,
        priorElapsedSeconds: Int
    ) {
        self.board = newBoard
        self.levelNumber = newBoard.levelNumber
        self.maxHearts = maxHearts
        self.hearts = hearts
        self.totalArrows = newBoard.totalArrowCount
        self.remainingArrows = newBoard.remainingCount
        self.gridDimensionsText = "\(newBoard.width)×\(newBoard.height)"
        self.boardShape = newBoard.shape
        self.levelSubtitle = newBoard.subtitle
        self.isHandcraftedLevel = newBoard.isHandcrafted
        self.isHardChallenge = isHard
        self.phase = .playing
        self.mistakesCount = mistakes
        self.hintsUsedCount = hintsUsed
        self.accumulatedElapsedSeconds = priorElapsedSeconds
        self.elapsedSeconds = priorElapsedSeconds
        self.comboCount = 0
        self.activeHintArrowID = nil
        self.levelStartDate = Date()

        scene.loadBoard(newBoard, theme: theme)
    }

    private func currentElapsedSeconds() -> Int {
        accumulatedElapsedSeconds + max(0, Int(Date().timeIntervalSince(levelStartDate)))
    }

    private func persistCurrentSession() {
        guard phase == .playing, let currentBoard = board, !currentBoard.isCleared, hearts > 0 else {
            return
        }
        let session = SavedGameSession(
            board: currentBoard,
            hearts: hearts,
            maxHearts: maxHearts,
            mistakesCount: mistakesCount,
            hintsUsedCount: hintsUsedCount,
            elapsedSeconds: currentElapsedSeconds()
        )
        progressRepository.saveSession(session)
    }

    private func schedulePrefetch(for nextLevel: Int) {
        if prefetchedLevel?.levelNumber == nextLevel { return }
        prefetchTask?.cancel()
        let useCase = self.generateLevelUseCase
        prefetchTask = Task.detached(priority: .utility) { [weak self] in
            let generated = useCase.execute(levelNumber: nextLevel)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.prefetchedLevel = (nextLevel, generated.board, generated.config)
            }
        }
    }

    // MARK: - Move Evaluation

    private func handleArrowTap(arrowID: UUID) {
        guard phase == .playing, var mutableBoard = board else { return }

        var mutableHearts = hearts
        let outcome = evaluateMoveUseCase.execute(
            arrowID: arrowID,
            board: &mutableBoard,
            currentHearts: &mutableHearts
        )

        self.board = mutableBoard

        switch outcome {
        case .escaped(let arrow, let remaining, let isCleared):
            remainingArrows = remaining
            if activeHintArrowID == arrow.id {
                activeHintArrowID = nil
            }

            let now = Date()
            if now.timeIntervalSince(lastEscapeDate) < 1.35 {
                comboCount += 1
            } else {
                comboCount = 0
            }
            lastEscapeDate = now

            feedbackService.playEscape(comboIndex: comboCount)
            scene.playEscapeAnimation(for: arrow.id)

            if isCleared {
                completeCurrentLevel()
            } else {
                persistCurrentSession()
            }

        case .blocked(let arrow, let blockerCell, let blockerArrowID, let remainingHearts, let isGameOver):
            hearts = remainingHearts
            mistakesCount += 1
            comboCount = 0

            feedbackService.playBlocked()
            scene.playBlockedAnimation(
                arrowID: arrow.id,
                blockerCell: blockerCell,
                blockerArrowID: blockerArrowID
            )

            if isGameOver {
                triggerGameOver()
            } else {
                persistCurrentSession()
            }

        case .ignored:
            break
        }
    }

    private func completeCurrentLevel() {
        phase = .transitioning
        elapsedSeconds = max(1, currentElapsedSeconds())
        progressRepository.clearSavedSession()

        if levelNumber + 1 > highestUnlockedLevel {
            highestUnlockedLevel = levelNumber + 1
            progress.highestUnlockedLevel = highestUnlockedLevel
        }
        progress.totalClearedLevels += 1
        progressRepository.saveProgress(progress)

        pendingPhaseTask?.cancel()
        pendingPhaseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 360_000_000)
            guard let self, !Task.isCancelled, self.phase == .transitioning else { return }
            self.scene.playLevelCompleteCelebration()
            self.feedbackService.playLevelComplete()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                self.phase = .levelComplete
            }
        }
    }

    private func triggerGameOver() {
        phase = .transitioning
        elapsedSeconds = max(1, currentElapsedSeconds())
        progressRepository.clearSavedSession()

        pendingPhaseTask?.cancel()
        pendingPhaseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard let self, !Task.isCancelled, self.phase == .transitioning else { return }
            self.feedbackService.playGameOver()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                self.phase = .gameOver
            }
        }
    }
}

extension GameViewModel: PuzzleBoardSceneDelegate {
    nonisolated public func puzzleScene(_ scene: PuzzleBoardScene, didTapArrowWithID arrowID: UUID) {
        Task { @MainActor [weak self] in
            self?.handleArrowTap(arrowID: arrowID)
        }
    }
}
