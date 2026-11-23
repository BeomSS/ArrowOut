import Foundation

/// Represents either a classic rectangular board or any of the 52 A–Z alphabet silhouettes.
public enum BoardShape: Hashable, Sendable {
    case rectangle
    case silhouette(SilhouetteID)

    // Convenient aliases for common silhouettes
    public static let diamond: BoardShape = .silhouette(.diamond)
    public static let cross: BoardShape = .silhouette(.cross)
    public static let heart: BoardShape = .silhouette(.heart)
    public static let donut: BoardShape = .silhouette(.donut)
    public static let star: BoardShape = .silhouette(.star)

    public var isSpecialShape: Bool {
        if case .silhouette = self { return true }
        return false
    }

    public var displayName: String {
        switch self {
        case .rectangle:
            return String(localized: "클래식")
        case .silhouette(let id):
            return id.displayLabel
        }
    }

    public var symbolName: String {
        switch self {
        case .rectangle:
            return "square.grid.2x2"
        case .silhouette(let id):
            return id.symbolName
        }
    }

    /// Returns the set of playable cells inside `width × height`.
    public func activeCells(width: Int, height: Int) -> Set<GridPoint> {
        switch self {
        case .rectangle:
            var cells = Set<GridPoint>()
            cells.reserveCapacity(width * height)
            for x in 0..<width {
                for y in 0..<height {
                    cells.insert(GridPoint(x: x, y: y))
                }
            }
            return cells

        case .silhouette(let id):
            return SilhouetteCatalog.rasterize(id, width: width, height: height)
        }
    }
}

extension BoardShape: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw == "rectangle" {
            self = .rectangle
        } else if let id = SilhouetteID(rawValue: raw) {
            self = .silhouette(id)
        } else {
            self = .rectangle
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .rectangle:
            try container.encode("rectangle")
        case .silhouette(let id):
            try container.encode(id.rawValue)
        }
    }
}
