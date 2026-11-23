import Foundation

public struct UserProgress: Codable, Equatable, Sendable {
    public var currentLevel: Int
    public var highestUnlockedLevel: Int
    public var totalClearedLevels: Int
    public var isSoundEnabled: Bool
    public var isHapticsEnabled: Bool
    public var isDarkTheme: Bool

    public init(
        currentLevel: Int = 1,
        highestUnlockedLevel: Int = 1,
        totalClearedLevels: Int = 0,
        isSoundEnabled: Bool = true,
        isHapticsEnabled: Bool = true,
        isDarkTheme: Bool = false
    ) {
        self.currentLevel = currentLevel
        self.highestUnlockedLevel = highestUnlockedLevel
        self.totalClearedLevels = totalClearedLevels
        self.isSoundEnabled = isSoundEnabled
        self.isHapticsEnabled = isHapticsEnabled
        self.isDarkTheme = isDarkTheme
    }
}

/// Persisted mid-level board snapshot so large puzzles can be resumed cleanly across app launches.
public struct SavedGameSession: Codable, Equatable, Sendable {
    public let board: PuzzleBoard
    public let hearts: Int
    public let maxHearts: Int
    public let mistakesCount: Int
    public let hintsUsedCount: Int
    public let elapsedSeconds: Int

    public init(
        board: PuzzleBoard,
        hearts: Int,
        maxHearts: Int,
        mistakesCount: Int,
        hintsUsedCount: Int,
        elapsedSeconds: Int
    ) {
        self.board = board
        self.hearts = hearts
        self.maxHearts = maxHearts
        self.mistakesCount = mistakesCount
        self.hintsUsedCount = hintsUsedCount
        self.elapsedSeconds = elapsedSeconds
    }
}

public protocol ProgressRepositoryProtocol: Sendable {
    func loadProgress() -> UserProgress
    func saveProgress(_ progress: UserProgress)

    func loadSavedSession() -> SavedGameSession?
    func saveSession(_ session: SavedGameSession)
    func clearSavedSession()
}
