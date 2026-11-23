import XCTest
@testable import ArrowPuzzle

final class ArrowPuzzleDomainTests: XCTestCase {
    private let solver = PuzzleSolver()
    private lazy var generator = ProceduralLevelGenerator(solver: solver)
    private lazy var generateLevelUseCase = GenerateLevelUseCase(generator: generator, solver: solver)
    private let evaluateMoveUseCase = EvaluateMoveUseCase()
    private let findHintUseCase = FindHintUseCase()

    func testProceduralGeneratorProducesSolvableFullLevelsWithoutOverusingSingleCellArrows() {
        for level in 1...60 {
            let (board, _) = generateLevelUseCase.execute(levelNumber: level)

            XCTAssertFalse(board.arrows.isEmpty, "Level \(level) should contain arrows")
            XCTAssertTrue(solver.isSolvable(board), "Level \(level) must be 100% solvable")

            var seenCells = Set<GridPoint>()
            var singleCellCount = 0
            for arrow in board.arrows {
                XCTAssertGreaterThanOrEqual(arrow.cells.count, 1, "Arrow in level \(level) must have >= 1 cell")
                if arrow.isSingleCell {
                    singleCellCount += 1
                }
                for i in 0..<arrow.cells.count {
                    let cell = arrow.cells[i]
                    XCTAssertTrue(board.isActiveCell(cell), "Cell \(cell) outside active mask in level \(level)")
                    XCTAssertTrue(seenCells.insert(cell).inserted, "Overlapping cell \(cell) in level \(level)")
                    if i > 0 {
                        XCTAssertEqual(
                            arrow.cells[i - 1].manhattanDistance(to: cell),
                            1,
                            "Non-adjacent cells in arrow in level \(level)"
                        )
                    }
                }
                if arrow.cells.count >= 2 {
                    let expectedHeadDir = Direction.from(
                        from: arrow.cells[arrow.cells.count - 2],
                        to: arrow.cells[arrow.cells.count - 1]
                    )
                    XCTAssertEqual(expectedHeadDir, arrow.headDirection, "Head direction mismatch in level \(level)")
                }
            }

            let fillRatio = Double(seenCells.count) / Double(max(1, board.activeCells.count))
            XCTAssertGreaterThanOrEqual(fillRatio, 0.98, "Level \(level) fill ratio too low: \(fillRatio)")

            XCTAssertLessThanOrEqual(singleCellCount, 4, "Too many 1-cell arrows on level \(level)")

            if level >= 11 {
                let metrics = try? XCTUnwrap(solver.analyzeDifficulty(of: board))
                XCTAssertGreaterThanOrEqual(metrics?.peelDepth ?? 0, 4, "Level \(level) peel depth too shallow")
                XCTAssertLessThanOrEqual(metrics?.initialFreeRatio ?? 1.0, 0.55, "Level \(level) too many initial openings")
            }
        }
    }

    func testDifficultyCurveHeartCountsAndHardMilestones() {
        for level in 1...3 {
            XCTAssertEqual(LevelConfig.forLevel(level).maxHearts, 5)
            XCTAssertFalse(LevelConfig.forLevel(level).isHardChallenge)
        }
        for level in 4...60 {
            let config = LevelConfig.forLevel(level)
            XCTAssertEqual(config.maxHearts, 3)
            XCTAssertEqual(config.isHardChallenge, level >= 10 && level % 5 == 0)
        }
        XCTAssertEqual(LevelConfig.forLevel(59).width, 22)
        XCTAssertEqual(LevelConfig.forLevel(60).width, 34)
        XCTAssertEqual(LevelConfig.forLevel(99).width, 60)
        XCTAssertEqual(LevelConfig.forLevel(100).width, 50)
        XCTAssertEqual(LevelConfig.forLevel(102).shape.isSpecialShape, true)
        XCTAssertEqual(LevelConfig.forLevel(103).shape, .rectangle)
        XCTAssertEqual(LevelConfig.forLevel(104).shape.isSpecialShape, true)
        XCTAssertEqual(LevelConfig.forLevel(199).width, 64)
        XCTAssertEqual(LevelConfig.forLevel(200).width, 100)
        XCTAssertEqual(LevelConfig.forLevel(200).shape.isSpecialShape, true)
        XCTAssertEqual(LevelConfig.forLevel(201).width, 64)
        XCTAssertEqual(LevelConfig.forLevel(202).width, 100)
        XCTAssertEqual(LevelConfig.forLevel(1100).width, 100)
    }

    func testBoardConceptsNeverRepeatConsecutivelyOrWithOneLevelGap() {
        for level in 5...100 {
            let current = BoardConcept.forLevel(level)
            let prev1 = BoardConcept.forLevel(level - 1)
            XCTAssertNotEqual(current, prev1, "Concept repeated consecutively at level \(level)")
            if level >= 6 {
                let prev2 = BoardConcept.forLevel(level - 2)
                XCTAssertNotEqual(current, prev2, "Concept repeated with 1-level gap at level \(level)")
            }
        }
    }

    func testNoRedundantSameDirectionSingleCellTandemsAcross60Levels() {
        for level in 4...60 {
            let (board, _) = generateLevelUseCase.execute(levelNumber: level)
            let occupancy = board.occupancyMap()
            let arrowsByID = Dictionary(uniqueKeysWithValues: board.arrows.map { ($0.id, $0) })

            for arrow in board.arrows where arrow.isSingleCell {
                let cell = arrow.head
                let rearCell = cell.moved(by: arrow.headDirection.opposite)
                if let rearID = occupancy[rearCell], let rearArrow = arrowsByID[rearID] {
                    XCTAssertNotEqual(
                        rearArrow.headDirection,
                        arrow.headDirection,
                        "Redundant same-direction 1-cell tandem found at \(cell) on level \(level)"
                    )
                }
            }
        }
    }

    func testHybridGeneratorServesHandcraftedLevels1To3AndShapedLevelsAfter() {
        let provider = HandcraftedLevelProvider(bundle: Bundle(for: ArrowPuzzleDomainTests.self))
        let fallbackProvider = provider.availableLevelNumbers.isEmpty
            ? HandcraftedLevelProvider(bundle: .main)
            : provider
        let hybrid = HybridLevelGenerator(
            handcraftedProvider: fallbackProvider,
            proceduralGenerator: generator,
            solver: solver
        )
        let useCase = GenerateLevelUseCase(generator: hybrid, solver: solver)

        for level in 1...3 {
            let (board, _) = useCase.execute(levelNumber: level)
            XCTAssertTrue(board.isHandcrafted, "Level \(level) should be handcrafted")
            XCTAssertTrue(solver.isSolvable(board), "Handcrafted level \(level) must be solvable")
            for arrow in board.arrows {
                for cell in arrow.cells {
                    XCTAssertTrue(board.isActiveCell(cell), "Handcrafted level \(level) cell \(cell) outside mask")
                }
            }
        }

        let specialLevels = [5, 8, 10, 12, 15, 18, 21, 24]
        for level in specialLevels {
            let (board, _) = useCase.execute(levelNumber: level)
            XCTAssertFalse(board.isHandcrafted)
            XCTAssertTrue(board.shape.isSpecialShape, "Level \(level) should have an A–Z silhouette")
            XCTAssertTrue(solver.isSolvable(board))
        }
    }

    func testAll52AlphabetSilhouettesAreSolvableAndNonRepeating() {
        // Every letter A–Z must have at least 2 distinct word variants
        for letter in SilhouetteCatalog.alphabetOrder {
            let variants = SilhouetteCatalog.variantsByLetter[letter] ?? []
            XCTAssertGreaterThanOrEqual(variants.count, 2, "Letter \(letter) should have >= 2 silhouette variants")
        }

        // Verify non-repeating random letter appearance & variant rotation across 78 special occurrences (3 full A–Z cycles)
        for i in 1..<78 {
            let curr = SilhouetteCatalog.silhouette(forSpecialOccurrence: i)
            let prev1 = SilhouetteCatalog.silhouette(forSpecialOccurrence: i - 1)
            XCTAssertNotEqual(curr.letter, prev1.letter, "Same letter repeated consecutively at index \(i)")
            if i >= 2 {
                let prev2 = SilhouetteCatalog.silhouette(forSpecialOccurrence: i - 2)
                XCTAssertNotEqual(curr.letter, prev2.letter, "Same letter repeated within 1 step at index \(i)")
            }
        }

        // Verify every single one of the 52 silhouettes produces a 100% solvable, dense puzzle
        for (idx, silhouette) in SilhouetteID.allCases.enumerated() {
            let cfg = LevelConfig(
                levelNumber: 200 + idx,
                width: 17,
                height: 17,
                shape: .silhouette(silhouette),
                concept: BoardConcept.allCases[idx % BoardConcept.allCases.count],
                maxHearts: 3,
                minArrowLength: 3,
                maxArrowLength: 6,
                preferredTurnProbability: 0.76,
                candidateAttempts: 2,
                seed: UInt64(idx + 777)
            )
            let board = generator.generateBoard(config: cfg)
            XCTAssertTrue(solver.isSolvable(board), "Silhouette \(silhouette.rawValue) must be solvable")
            let filled = board.arrows.reduce(0) { $0 + $1.cells.count }
            let fillRatio = Double(filled) / Double(max(1, board.activeCells.count))
            XCTAssertGreaterThanOrEqual(fillRatio, 0.95, "Silhouette \(silhouette.rawValue) fill ratio too low: \(fillRatio)")
        }
    }

    func testEvaluateMoveEscapesAndSupportsSingleCellArrows() {
        let singleArrow = Arrow(
            cells: [GridPoint(x: 0, y: 1)],
            headDirection: .right
        )
        let blockerArrow = Arrow(
            cells: [GridPoint(x: 2, y: 0), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2)],
            headDirection: .up
        )
        var board = PuzzleBoard(levelNumber: 1, width: 4, height: 4, arrows: [singleArrow, blockerArrow])
        var hearts = 5

        let blockedOutcome = evaluateMoveUseCase.execute(arrowID: singleArrow.id, board: &board, currentHearts: &hearts)
        XCTAssertEqual(
            blockedOutcome,
            .blocked(
                arrow: singleArrow,
                blockerCell: GridPoint(x: 2, y: 1),
                blockerArrowID: blockerArrow.id,
                remainingHearts: 4,
                isGameOver: false
            )
        )
        XCTAssertTrue(board.failedArrowIDs.contains(singleArrow.id))

        let escapeB = evaluateMoveUseCase.execute(arrowID: blockerArrow.id, board: &board, currentHearts: &hearts)
        XCTAssertEqual(escapeB, .escaped(arrow: blockerArrow, remainingCount: 1, isLevelCleared: false))

        let escapeSingle = evaluateMoveUseCase.execute(arrowID: singleArrow.id, board: &board, currentHearts: &hearts)
        XCTAssertEqual(escapeSingle, .escaped(arrow: singleArrow, remainingCount: 0, isLevelCleared: true))
        XCTAssertFalse(board.failedArrowIDs.contains(singleArrow.id))
    }

    func testSavedGameSessionRoundTripPreservesFailedArrows() throws {
        let arrowA = Arrow(cells: [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0)], headDirection: .right)
        var board = PuzzleBoard(levelNumber: 12, width: 4, height: 4, arrows: [arrowA], shape: .diamond, concept: .spiralVortex)
        board.markFailed(arrowID: arrowA.id)

        let session = SavedGameSession(
            board: board,
            hearts: 2,
            maxHearts: 3,
            mistakesCount: 1,
            hintsUsedCount: 1,
            elapsedSeconds: 47
        )
        let encoded = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(SavedGameSession.self, from: encoded)
        XCTAssertEqual(decoded, session)
        XCTAssertTrue(decoded.board.failedArrowIDs.contains(arrowA.id))
    }

    func testFindHintPrioritizesUnblockingArrow() {
        let blockedArrow = Arrow(
            cells: [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)],
            headDirection: .right
        )
        let unblockerArrow = Arrow(
            cells: [GridPoint(x: 2, y: 0), GridPoint(x: 2, y: 1)],
            headDirection: .up
        )
        let unrelatedArrow = Arrow(
            cells: [GridPoint(x: 0, y: 3), GridPoint(x: 1, y: 3)],
            headDirection: .up
        )
        let board = PuzzleBoard(
            levelNumber: 1,
            width: 4,
            height: 4,
            arrows: [blockedArrow, unrelatedArrow, unblockerArrow]
        )

        let hint = findHintUseCase.execute(in: board)
        XCTAssertEqual(hint?.id, unblockerArrow.id)
    }

    func testSolverDetectsDeadlockCycle() {
        let leftArrow = Arrow(
            cells: [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)],
            headDirection: .right
        )
        let rightArrow = Arrow(
            cells: [GridPoint(x: 3, y: 1), GridPoint(x: 2, y: 1)],
            headDirection: .left
        )
        let deadlockedBoard = PuzzleBoard(levelNumber: 1, width: 4, height: 4, arrows: [leftArrow, rightArrow])
        XCTAssertFalse(solver.isSolvable(deadlockedBoard))
    }

    func testArrowPathSimplificationAndBezierFreeCorners() {
        let points: [CGPoint] = [
            CGPoint(x: 108, y: 54),
            CGPoint(x: 108, y: 0),
            CGPoint(x: 54, y: 0),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0, y: 54),
            CGPoint(x: 0, y: 108)
        ]

        let simplified = ArrowNode.simplifyPoints(points)
        XCTAssertEqual(simplified, [
            CGPoint(x: 108, y: 54),
            CGPoint(x: 108, y: 0),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0, y: 108)
        ])

        let path = ArrowNode.buildRoundedPath(from: points, cornerRadius: 13.0)
        var hasCurveElement = false
        var lineCount = 0
        path.applyWithBlock { elementPtr in
            switch elementPtr.pointee.type {
            case .addQuadCurveToPoint, .addCurveToPoint:
                hasCurveElement = true
            case .addLineToPoint:
                lineCount += 1
            default:
                break
            }
        }
        XCTAssertFalse(hasCurveElement, "Arrow CGPath must not contain Bézier curve elements")
        XCTAssertGreaterThan(lineCount, 10, "Rounded corners should be sampled with multiple line segments")
    }
}
