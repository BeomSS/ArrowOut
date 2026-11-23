import Foundation

/// Loads handcrafted JSON levels (Levels 1–10) into pure Domain `PuzzleBoard` instances.
public final class HandcraftedLevelProvider: @unchecked Sendable {
    private struct LevelDTO: Decodable {
        let levelNumber: Int
        let width: Int
        let height: Int
        let shape: BoardShape?
        let subtitle: String?
        let isHardChallenge: Bool?
        let arrows: [ArrowDTO]
    }

    private struct ArrowDTO: Decodable {
        let cells: [[Int]]
        /// Required only for 1-cell arrows; inferred from the last two cells for multi-cell arrows.
        let direction: String?
    }

    private let levelsByNumber: [Int: PuzzleBoard]

    public var availableLevelNumbers: [Int] {
        levelsByNumber.keys.sorted()
    }

    public convenience init(bundle: Bundle = .main, resourceName: String = "HandcraftedLevels") {
        if let url = bundle.url(forResource: resourceName, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            self.init(jsonData: data)
        } else {
            self.init(jsonData: Data())
        }
    }

    public init(jsonData: Data) {
        guard !jsonData.isEmpty,
              let decoded = try? JSONDecoder().decode([LevelDTO].self, from: jsonData) else {
            self.levelsByNumber = [:]
            return
        }

        var map: [Int: PuzzleBoard] = [:]
        for dto in decoded {
            if let board = Self.mapToBoard(dto) {
                map[dto.levelNumber] = board
            }
        }
        self.levelsByNumber = map
    }

    public func board(forLevel levelNumber: Int) -> PuzzleBoard? {
        levelsByNumber[levelNumber]
    }

    private static func mapToBoard(_ dto: LevelDTO) -> PuzzleBoard? {
        let shape = dto.shape ?? .rectangle
        let activeCells = shape.activeCells(width: dto.width, height: dto.height)
        var arrows: [Arrow] = []
        arrows.reserveCapacity(dto.arrows.count)

        for (index, arrowDTO) in dto.arrows.enumerated() {
            let points = arrowDTO.cells.compactMap { pair -> GridPoint? in
                guard pair.count == 2 else { return nil }
                return GridPoint(x: pair[0], y: pair[1])
            }
            guard !points.isEmpty else { return nil }

            let headDir: Direction
            if points.count >= 2,
               let inferred = Direction.from(from: points[points.count - 2], to: points[points.count - 1]) {
                headDir = inferred
            } else if points.count == 1, let dirName = arrowDTO.direction, let parsed = parseDirection(dirName) {
                headDir = parsed
            } else {
                return nil
            }

            let arrow = Arrow(
                id: deterministicUUID(level: dto.levelNumber, arrowIndex: index),
                cells: points,
                headDirection: headDir
            )
            arrows.append(arrow)
        }

        let localizedSubtitle = dto.subtitle.map {
            String(localized: String.LocalizationValue($0))
        }

        return PuzzleBoard(
            levelNumber: dto.levelNumber,
            width: dto.width,
            height: dto.height,
            arrows: arrows,
            shape: shape,
            activeCells: activeCells,
            subtitle: localizedSubtitle,
            isHandcrafted: true,
            isHardChallenge: dto.isHardChallenge ?? false
        )
    }

    private static func parseDirection(_ name: String) -> Direction? {
        switch name.lowercased() {
        case "up": return .up
        case "right": return .right
        case "down": return .down
        case "left": return .left
        default: return nil
        }
    }

    private static func deterministicUUID(level: Int, arrowIndex: Int) -> UUID {
        let hi = UInt64(level) &* 0x9E37_79B9_7F4A_7C15 ^ 0xCAFE_BABE_0000_0001
        let lo = UInt64(arrowIndex + 1) &* 0xBF58_476D_1CE4_E5B9 ^ 0xDEAD_BEEF_1234_5678
        var bytes: uuid_t = (
            UInt8((hi >> 56) & 0xFF), UInt8((hi >> 48) & 0xFF),
            UInt8((hi >> 40) & 0xFF), UInt8((hi >> 32) & 0xFF),
            UInt8((hi >> 24) & 0xFF), UInt8((hi >> 16) & 0xFF),
            UInt8(((hi >> 8) & 0x0F) | 0x40), UInt8(hi & 0xFF),
            UInt8(((lo >> 56) & 0x3F) | 0x80), UInt8((lo >> 48) & 0xFF),
            UInt8((lo >> 40) & 0xFF), UInt8((lo >> 32) & 0xFF),
            UInt8((lo >> 24) & 0xFF), UInt8((lo >> 16) & 0xFF),
            UInt8((lo >> 8) & 0xFF), UInt8(lo & 0xFF)
        )
        return withUnsafePointer(to: &bytes) { UUID(uuid: $0.pointee) }
    }
}
