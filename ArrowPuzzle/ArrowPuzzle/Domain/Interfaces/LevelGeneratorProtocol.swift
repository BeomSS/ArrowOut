import Foundation

public protocol LevelGeneratorProtocol: Sendable {
    func generateBoard(config: LevelConfig) -> PuzzleBoard
}
