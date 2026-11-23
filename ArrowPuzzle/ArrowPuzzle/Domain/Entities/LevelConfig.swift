import Foundation

public struct LevelConfig: Hashable, Sendable {
    public let levelNumber: Int
    public let width: Int
    public let height: Int
    public let shape: BoardShape
    public let concept: BoardConcept
    public let maxHearts: Int
    public let minArrowLength: Int
    public let maxArrowLength: Int
    public let preferredTurnProbability: Double
    public let isHardChallenge: Bool
    public let candidateAttempts: Int
    public let seed: UInt64

    public init(
        levelNumber: Int,
        width: Int,
        height: Int,
        shape: BoardShape = .rectangle,
        concept: BoardConcept = .denseLabyrinth,
        maxHearts: Int,
        minArrowLength: Int,
        maxArrowLength: Int,
        preferredTurnProbability: Double,
        isHardChallenge: Bool = false,
        candidateAttempts: Int = 8,
        seed: UInt64
    ) {
        self.levelNumber = levelNumber
        self.width = width
        self.height = height
        self.shape = shape
        self.concept = concept
        self.maxHearts = maxHearts
        self.minArrowLength = minArrowLength
        self.maxArrowLength = maxArrowLength
        self.preferredTurnProbability = preferredTurnProbability
        self.isHardChallenge = isHardChallenge
        self.candidateAttempts = candidateAttempts
        self.seed = seed
    }

    /// Returns whether `level` is a special A–Z silhouette stage and its monotonic occurrence index:
    /// - LV.5, 8, 10: early showcase (indices 0, 1, 2)
    /// - LV.12 ~ 99: every 3 levels (`level % 3 == 0`, indices 3...32)
    /// - LV.102+: every 2 levels (`level % 2 == 0`, indices 33, 34, 35, ...)
    public static func specialOccurrenceIndex(forLevel level: Int) -> Int? {
        switch level {
        case 5: return 0
        case 8: return 1
        case 10: return 2
        case 11...100:
            return level.isMultiple(of: 3) ? (level / 3) - 1 : nil
        case 101...:
            return level.isMultiple(of: 2) ? 32 + (level - 100) / 2 : nil
        default:
            return nil
        }
    }

    /// Multi-tier progression up to LV.200 (fixed thereafter):
    /// - LV.1–3: Fast handcrafted tutorial (3×3 → 5×5, 5 hearts)
    /// - LV.4–60: Normal up to 22×22 · Special shapes larger (16×16 → 34×34) for crisp silhouettes
    /// - LV.61–100: Normal 22×22 → 50×50 · Special shapes 34×34 → 60×60
    /// - LV.101–200: Special shapes appear every 2 levels & scale 60×60 → 100×100 · Normal 50×50 → 64×64
    /// - LV.201+: Fixed at 64×64 (normal) and 100×100 (special shapes)
    public static func forLevel(_ level: Int) -> LevelConfig {
        let clampedLevel = max(1, level)
        let isTutorial = clampedLevel <= 3
        let maxHearts = isTutorial ? 5 : 3
        let isHard = clampedLevel >= 10 && clampedLevel % 5 == 0

        let (width, height, shape, minLen, maxLen, turnProb):
            (Int, Int, BoardShape, Int, Int, Double)

        if let occurrenceIdx = specialOccurrenceIndex(forLevel: clampedLevel) {
            let resolvedShape = BoardShape.silhouette(
                SilhouetteCatalog.silhouette(forSpecialOccurrence: occurrenceIdx)
            )
            let tierSize: Int
            if clampedLevel <= 10 {
                // Early special shapes need enough resolution (16..18) for silhouettes to read clearly
                tierSize = clampedLevel == 5 ? 16 : (clampedLevel == 8 ? 17 : 18)
            } else if clampedLevel <= 60 {
                let progress = Double(clampedLevel - 10) / 50.0
                tierSize = 18 + Int(round(progress * 16.0)) // 18×18 → 34×34
            } else if clampedLevel <= 100 {
                let progress = min(1.0, Double(clampedLevel - 60) / 39.0)
                tierSize = 34 + Int(round(progress * 26.0)) // 34×34 → 60×60 (at LV.99)
            } else if clampedLevel <= 200 {
                let progress = Double(clampedLevel - 100) / 100.0
                tierSize = 60 + Int(round(progress * 40.0)) // 60×60 → 100×100
            } else {
                tierSize = 100
            }

            let shapedMinLen = tierSize >= 70 ? 5 : (tierSize >= 45 ? 4 : 3)
            let shapedMaxLen = tierSize >= 80 ? 14 : (tierSize >= 55 ? 11 : (tierSize >= 32 ? 8 : 6))
            (width, height, shape, minLen, maxLen, turnProb) = (
                tierSize, tierSize, resolvedShape, shapedMinLen, shapedMaxLen, 0.80
            )
        } else {
            switch clampedLevel {
            case 1:
                (width, height, shape, minLen, maxLen, turnProb) = (3, 3, .rectangle, 2, 2, 0.30)
            case 2:
                (width, height, shape, minLen, maxLen, turnProb) = (4, 4, .rectangle, 2, 4, 0.50)
            case 3:
                (width, height, shape, minLen, maxLen, turnProb) = (5, 5, .rectangle, 2, 5, 0.62)
            case 4:
                (width, height, shape, minLen, maxLen, turnProb) = (8, 8, .rectangle, 2, 5, 0.72)
            case 6:
                (width, height, shape, minLen, maxLen, turnProb) = (9, 9, .rectangle, 2, 5, 0.74)
            case 7:
                (width, height, shape, minLen, maxLen, turnProb) = (10, 10, .rectangle, 2, 5, 0.74)
            case 9:
                (width, height, shape, minLen, maxLen, turnProb) = (11, 11, .rectangle, 3, 6, 0.75)
            case 11...60:
                switch clampedLevel {
                case 11...14:
                    (width, height, shape, minLen, maxLen, turnProb) = (12, 12, .rectangle, 3, 6, 0.74)
                case 15...19:
                    (width, height, shape, minLen, maxLen, turnProb) = (13, 13, .rectangle, 3, 6, 0.75)
                case 20...24:
                    (width, height, shape, minLen, maxLen, turnProb) = (15, 15, .rectangle, 3, 6, 0.76)
                case 25...29:
                    (width, height, shape, minLen, maxLen, turnProb) = (16, 16, .rectangle, 3, 6, 0.76)
                case 30...35:
                    (width, height, shape, minLen, maxLen, turnProb) = (17, 17, .rectangle, 3, 6, 0.78)
                case 36...42:
                    (width, height, shape, minLen, maxLen, turnProb) = (18, 18, .rectangle, 3, 6, 0.78)
                case 43...49:
                    (width, height, shape, minLen, maxLen, turnProb) = (20, 20, .rectangle, 3, 7, 0.80)
                case 50...57:
                    (width, height, shape, minLen, maxLen, turnProb) = (21, 21, .rectangle, 3, 7, 0.80)
                default:
                    (width, height, shape, minLen, maxLen, turnProb) = (22, 22, .rectangle, 3, 7, 0.82)
                }
            case 61...100:
                let progress = Double(clampedLevel - 60) / 40.0
                let size = 22 + Int(round(progress * 28.0)) // 22×22 → 50×50
                let dynMaxLen = size >= 40 ? 9 : (size >= 30 ? 8 : 7)
                (width, height, shape, minLen, maxLen, turnProb) = (size, size, .rectangle, 3, dynMaxLen, 0.82)
            case 101...200:
                let progress = Double(clampedLevel - 100) / 100.0
                let size = 50 + Int(round(progress * 14.0)) // 50×50 → 64×64
                (width, height, shape, minLen, maxLen, turnProb) = (size, size, .rectangle, 4, 11, 0.82)
            default:
                (width, height, shape, minLen, maxLen, turnProb) = (64, 64, .rectangle, 4, 11, 0.82)
            }
        }

        // Scale search attempts inversely with grid size so even 100×100 stays snappy
        let baseAttempts: Int
        if width >= 55 {
            baseAttempts = 1
        } else if width >= 36 {
            baseAttempts = isHard ? 2 : 1
        } else if width >= 24 {
            baseAttempts = isHard ? 3 : 2
        } else if shape != .rectangle {
            baseAttempts = isHard ? 6 : 4
        } else if width >= 18 {
            baseAttempts = isHard ? 5 : 4
        } else {
            baseAttempts = isHard ? 8 : 6
        }

        let seed = UInt64(clampedLevel) &* 0x9E37_79B9_7F4A_7C15 ^ 0xA5A5_5A5A_1234_5678
        let concept = BoardConcept.forLevel(clampedLevel)

        return LevelConfig(
            levelNumber: clampedLevel,
            width: width,
            height: height,
            shape: shape,
            concept: concept,
            maxHearts: maxHearts,
            minArrowLength: minLen,
            maxArrowLength: maxLen,
            preferredTurnProbability: turnProb,
            isHardChallenge: isHard,
            candidateAttempts: baseAttempts,
            seed: seed
        )
    }
}
