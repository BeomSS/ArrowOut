import Foundation

public final class UserDefaultsProgressRepository: ProgressRepositoryProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let progressKey = "com.arrowpuzzle.user_progress.v1"
    private let sessionKey = "com.arrowpuzzle.saved_session.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadProgress() -> UserProgress {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(UserProgress.self, from: data) else {
            return UserProgress()
        }
        return progress
    }

    public func saveProgress(_ progress: UserProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: progressKey)
    }

    public func loadSavedSession() -> SavedGameSession? {
        guard let data = defaults.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(SavedGameSession.self, from: data) else {
            return nil
        }
        return session
    }

    public func saveSession(_ session: SavedGameSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: sessionKey)
    }

    public func clearSavedSession() {
        defaults.removeObject(forKey: sessionKey)
    }
}
