import Foundation

public protocol FeedbackServiceProtocol: AnyObject {
    var isSoundEnabled: Bool { get set }
    var isHapticsEnabled: Bool { get set }

    func playEscape(comboIndex: Int)
    func playBlocked()
    func playHint()
    func playLevelComplete()
    func playGameOver()
    func playButtonTap()
}
