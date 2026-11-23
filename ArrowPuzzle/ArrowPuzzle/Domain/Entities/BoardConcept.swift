import Foundation

/// Visual and structural layout archetype used to seed hero anchor arrows before filling the board.
public enum BoardConcept: String, Codable, Hashable, Sendable, CaseIterable {
    case spiralVortex
    case serpentineMaze
    case concentricFortress
    case hookedKnots
    case denseLabyrinth

    public var displayName: String {
        switch self {
        case .spiralVortex: return String(localized: "소용돌이 미로")
        case .serpentineMaze: return String(localized: "지그재그 미로")
        case .concentricFortress: return String(localized: "겹성곽")
        case .hookedKnots: return String(localized: "갈고리 매듭")
        case .denseLabyrinth: return String(localized: "고밀도 미로")
        }
    }

    public var symbolName: String {
        switch self {
        case .spiralVortex: return "hurricane"
        case .serpentineMaze: return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .concentricFortress: return "square.stack.3d.down.right.fill"
        case .hookedKnots: return "link"
        case .denseLabyrinth: return "square.grid.3x3.fill"
        }
    }

    /// Deterministically assigns a concept per level using non-repeating shuffled bags
    /// so the same concept NEVER appears consecutively or with only a 1-level gap.
    public static func forLevel(_ level: Int) -> BoardConcept {
        let clamped = max(1, level)
        if clamped <= 3 {
            return .denseLabyrinth
        }

        let offset = clamped - 4
        let bagSize = allCases.count
        let bagIndex = offset / bagSize
        let posInBag = offset % bagSize

        let currentBag = shuffledBag(index: bagIndex)
        return currentBag[posInBag]
    }

    private static func shuffledBag(index: Int) -> [BoardConcept] {
        // Compute iteratively from bag 0 so each bag's first 2 entries never match
        // the previous bag's last 2 entries (guarantees minimum gap of >= 2 levels).
        var prevLast: BoardConcept?
        var prevSecondLast: BoardConcept?
        var bag = allCases

        for b in 0...index {
            var state = UInt64(b + 1) &* 0x9E37_79B9_7F4A_7C15 ^ 0xD1B5_4A32_D192_ED03
            var candidate = allCases

            func nextRand() -> UInt64 {
                state &+= 0x9E37_79B9_7F4A_7C15
                var z = state
                z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                return z ^ (z >> 31)
            }

            // Deterministic Fisher-Yates shuffle
            for i in stride(from: candidate.count - 1, through: 1, by: -1) {
                let j = Int(nextRand() % UInt64(i + 1))
                candidate.swapAt(i, j)
            }

            // Guarantee candidate[0] != prevLast and candidate[0] != prevSecondLast
            if let last = prevLast, candidate[0] == last || candidate[0] == prevSecondLast {
                if let swapIdx = candidate.firstIndex(where: { $0 != last && $0 != prevSecondLast }) {
                    candidate.swapAt(0, swapIdx)
                }
            }
            // Guarantee candidate[1] != prevLast (prevents A, B, A pattern across bag boundaries)
            if let last = prevLast, candidate[1] == last {
                if let swapIdx = (2..<candidate.count).first(where: { candidate[$0] != last }) {
                    candidate.swapAt(1, swapIdx)
                }
            }

            prevSecondLast = candidate[candidate.count - 2]
            prevLast = candidate[candidate.count - 1]
            bag = candidate
        }

        return bag
    }
}
