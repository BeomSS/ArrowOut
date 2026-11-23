import SpriteKit
import UIKit

public protocol PuzzleBoardSceneDelegate: AnyObject {
    func puzzleScene(_ scene: PuzzleBoardScene, didTapArrowWithID arrowID: UUID)
}

public final class PuzzleBoardScene: SKScene {
    public weak var interactionDelegate: PuzzleBoardSceneDelegate?

    private let cameraNode = SKCameraNode()
    private let boardContainer = SKNode()
    /// Single batched SKShapeNode rendering all active grid dots in 1 draw call.
    private let gridDotsNode = SKShapeNode()
    private let arrowsLayer = SKNode()

    private let particlesFactory = ParticleEffectsFactory()
    private var arrowNodes: [UUID: ArrowNode] = [:]
    private var cellToArrowID: [GridPoint: UUID] = [:]

    private var currentBoard: PuzzleBoard?
    private var theme: AppTheme = AppTheme(isDark: false)

    private let cellSize: CGFloat = 54.0
    private var boardPixelSize: CGSize = .zero
    private var defaultCameraScale: CGFloat = 1.0
    private var minCameraScale: CGFloat = 0.45
    private var maxCameraScale: CGFloat = 2.2

    public override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        if camera == nil {
            addChild(cameraNode)
            camera = cameraNode

            addChild(boardContainer)
            gridDotsNode.strokeColor = .clear
            gridDotsNode.zPosition = 5
            boardContainer.addChild(gridDotsNode)
            boardContainer.addChild(arrowsLayer)
        }
        applyTheme(theme)
        if let board = currentBoard, arrowNodes.isEmpty {
            rebuildBoardNodes(for: board)
        }
        fitCameraToBoard(animated: false)
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if oldSize != size, currentBoard != nil {
            fitCameraToBoard(animated: false)
        }
    }

    // MARK: - Public Scene API

    public func loadBoard(_ board: PuzzleBoard, theme: AppTheme) {
        self.currentBoard = board
        self.theme = theme
        applyTheme(theme)
        rebuildBoardNodes(for: board)
        fitCameraToBoard(animated: false)

        boardContainer.setScale(0.94)
        boardContainer.alpha = 0.0
        boardContainer.run(.group([
            .fadeAlpha(to: 1.0, duration: 0.22),
            .scale(to: 1.0, duration: 0.26)
        ]))
    }

    public func applyTheme(_ newTheme: AppTheme) {
        self.theme = newTheme
        backgroundColor = newTheme.sceneBackgroundUIColor
        gridDotsNode.fillColor = newTheme.gridDotUIColor

        for (_, node) in arrowNodes {
            node.updateThemeColor(
                normalColor: newTheme.arrowInkUIColor,
                failedColor: newTheme.arrowFailedUIColor,
                isDark: newTheme.isDark
            )
        }
    }

    public func playEscapeAnimation(for arrowID: UUID, completion: (() -> Void)? = nil) {
        guard let node = arrowNodes[arrowID] else {
            completion?()
            return
        }
        clearAllHints()
        arrowNodes.removeValue(forKey: arrowID)
        for cell in node.arrow.cells {
            if cellToArrowID[cell] == arrowID {
                cellToArrowID.removeValue(forKey: cell)
            }
        }

        // Compute exact directional runway from arrowhead to board edge so escape speed feels
        // crisp and natural even on giant 100×100 boards
        let cellsToEdge: Int
        if let board = currentBoard {
            switch node.arrow.headDirection {
            case .right: cellsToEdge = board.width - node.arrow.head.x
            case .left: cellsToEdge = node.arrow.head.x + 1
            case .up: cellsToEdge = board.height - node.arrow.head.y
            case .down: cellsToEdge = node.arrow.head.y + 1
            }
        } else {
            cellsToEdge = 12
        }
        let exitDistance = CGFloat(cellsToEdge + 8) * cellSize
        node.animateEscape(
            exitDistance: exitDistance,
            particlesFactory: particlesFactory,
            parentScene: self
        ) {
            completion?()
        }
    }

    public func playBlockedAnimation(
        arrowID: UUID,
        blockerCell: GridPoint,
        blockerArrowID: UUID
    ) {
        guard let node = arrowNodes[arrowID], let board = currentBoard else { return }

        let gapInCells = node.arrow.head.manhattanDistance(to: blockerCell)
        let blockerPos = positionForGridPoint(blockerCell, in: board)
        let impactPoint = CGPoint(
            x: blockerPos.x - CGFloat(node.arrow.headDirection.dx) * (cellSize * 0.42),
            y: blockerPos.y - CGFloat(node.arrow.headDirection.dy) * (cellSize * 0.42)
        )

        node.animateBlocked(
            gapInCells: gapInCells,
            blockedColor: theme.arrowFailedUIColor,
            impactPoint: impactPoint,
            particlesFactory: particlesFactory,
            parentScene: self
        )

        if let blockerNode = arrowNodes[blockerArrowID], blockerArrowID != arrowID {
            blockerNode.pulseAsBlocker(highlightColor: theme.arrowFailedUIColor)
        }

        let joltX = CGFloat(node.arrow.headDirection.dx) * 4.5
        let joltY = CGFloat(node.arrow.headDirection.dy) * 4.5
        cameraNode.run(.sequence([
            .moveBy(x: joltX, y: joltY, duration: 0.045),
            .moveBy(x: -joltX, y: -joltY, duration: 0.09)
        ]))
    }

    /// Highlights the hinted arrow and smoothly pans the camera to it if it is outside the zoomed viewport.
    public func highlightHint(arrowID: UUID) {
        clearAllHints()
        guard let node = arrowNodes[arrowID] else { return }
        node.showHint(glowColor: theme.hintGlowUIColor)

        let target = node.focusPoint()
        let scale = cameraNode.xScale
        let visibleHalfW = (size.width * scale) * 0.36
        let visibleHalfH = (max(120, size.height - 260) * scale) * 0.36
        let camPos = cameraNode.position

        let isVisible = abs(target.x - camPos.x) <= visibleHalfW && abs(target.y - camPos.y) <= visibleHalfH
        if !isVisible {
            let clamped = clampedCameraPosition(target)
            let pan = SKAction.move(to: clamped, duration: 0.30)
            pan.timingMode = .easeInEaseOut
            cameraNode.removeAction(forKey: "hintPan")
            cameraNode.run(pan, withKey: "hintPan")
        }
    }

    public func clearAllHints() {
        for node in arrowNodes.values {
            node.clearHint()
        }
    }

    public func playLevelCompleteCelebration() {
        let emitters = particlesFactory.makeCelebrationConfetti(
            at: cameraNode.position,
            colors: theme.celebrationColors
        )
        for emitter in emitters {
            addChild(emitter)
            emitter.run(.sequence([.wait(forDuration: 1.8), .removeFromParent()]))
        }
    }

    public func fitCameraToBoard(animated: Bool = true) {
        guard boardPixelSize.width > 0, boardPixelSize.height > 0, size.width > 0, size.height > 0 else {
            return
        }

        let usableWidth = max(120, size.width - 36)
        let usableHeight = max(120, size.height - 270)

        let paddedBoardW = boardPixelSize.width + cellSize * 0.9
        let paddedBoardH = boardPixelSize.height + cellSize * 0.9

        let scaleX = paddedBoardW / usableWidth
        let scaleY = paddedBoardH / usableHeight
        let targetScale = max(scaleX, scaleY, 0.72)

        defaultCameraScale = targetScale
        // Always allow zooming in to comfortable tap scale (~0.50) even on giant 50×50 boards
        minCameraScale = min(0.50, max(0.32, targetScale * 0.25))
        maxCameraScale = max(2.2, targetScale * 1.35)

        let targetPos = CGPoint(x: 0, y: 18)
        if animated {
            let move = SKAction.move(to: targetPos, duration: 0.24)
            move.timingMode = .easeOut
            let scale = SKAction.scale(to: targetScale, duration: 0.24)
            scale.timingMode = .easeOut
            cameraNode.run(.group([move, scale]))
        } else {
            cameraNode.position = targetPos
            cameraNode.setScale(targetScale)
        }
    }

    // MARK: - Gesture Handling

    public func handleTap(atViewPoint viewPoint: CGPoint) {
        guard let board = currentBoard else { return }
        let scenePoint = convertPoint(fromView: viewPoint)

        // O(1) direct cell hit-test (instant even on 50×50 boards with 450+ arrows)
        if let gridPoint = gridPoint(forScenePoint: scenePoint, in: board),
           let hitID = cellToArrowID[gridPoint],
           let node = arrowNodes[hitID],
           !node.isAnimating {
            interactionDelegate?.puzzleScene(self, didTapArrowWithID: hitID)
            return
        }

        // O(1) 3×3 neighborhood proximity fallback
        let originX = -CGFloat(board.width) * cellSize / 2.0
        let originY = -CGFloat(board.height) * cellSize / 2.0
        let centerCol = Int(floor((scenePoint.x - originX) / cellSize))
        let centerRow = Int(floor((scenePoint.y - originY) / cellSize))

        let maxTouchRadius = cellSize * 0.52
        var bestID: UUID?
        var bestDistance = maxTouchRadius

        for dx in -1...1 {
            for dy in -1...1 {
                let candidateCell = GridPoint(x: centerCol + dx, y: centerRow + dy)
                guard let id = cellToArrowID[candidateCell],
                      let node = arrowNodes[id],
                      !node.isAnimating else {
                    continue
                }
                let cellCenter = positionForGridPoint(candidateCell, in: board)
                let dist = hypot(scenePoint.x - cellCenter.x, scenePoint.y - cellCenter.y)
                if dist < bestDistance {
                    bestDistance = dist
                    bestID = id
                }
            }
        }

        if let hitID = bestID {
            interactionDelegate?.puzzleScene(self, didTapArrowWithID: hitID)
        }
    }

    public func handlePan(translationInView delta: CGPoint) {
        cameraNode.removeAction(forKey: "hintPan")
        let scale = cameraNode.xScale
        let candidate = CGPoint(
            x: cameraNode.position.x - delta.x * scale,
            y: cameraNode.position.y + delta.y * scale
        )
        cameraNode.position = clampedCameraPosition(candidate)
    }

    /// Zooms smoothly anchored to the user's two-finger pinch centroid instead of always screen center.
    public func handlePinch(scaleDelta: CGFloat, anchorInView: CGPoint? = nil) {
        cameraNode.removeAction(forKey: "hintPan")
        let beforeAnchor = anchorInView.map { convertPoint(fromView: $0) }

        let newScale = cameraNode.xScale / scaleDelta
        let clamped = min(maxCameraScale, max(minCameraScale, newScale))
        cameraNode.setScale(clamped)

        if let before = beforeAnchor, let viewAnchor = anchorInView {
            let after = convertPoint(fromView: viewAnchor)
            let shifted = CGPoint(
                x: cameraNode.position.x + (before.x - after.x),
                y: cameraNode.position.y + (before.y - after.y)
            )
            cameraNode.position = clampedCameraPosition(shifted)
        }
    }

    private func clampedCameraPosition(_ point: CGPoint) -> CGPoint {
        let limitX = max(cellSize * 2, boardPixelSize.width * 0.58)
        let limitY = max(cellSize * 2, boardPixelSize.height * 0.58)
        return CGPoint(
            x: min(limitX, max(-limitX, point.x)),
            y: min(limitY, max(-limitY, point.y))
        )
    }

    // MARK: - Board Geometry & Node Construction

    private func rebuildBoardNodes(for board: PuzzleBoard) {
        arrowsLayer.removeAllChildren()
        arrowNodes.removeAll()
        cellToArrowID.removeAll(keepingCapacity: true)

        let boardW = CGFloat(board.width) * cellSize
        let boardH = CGFloat(board.height) * cellSize
        boardPixelSize = CGSize(width: boardW, height: boardH)

        // Batch ALL active grid alignment dots into a single CGPath (1 draw call even on 22×22!)
        let dotRadius = cellSize * 0.055
        let batchedDotsPath = CGMutablePath()
        for cell in board.activeCells {
            let pos = positionForGridPoint(cell, in: board)
            batchedDotsPath.addEllipse(in: CGRect(
                x: pos.x - dotRadius,
                y: pos.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
        }
        gridDotsNode.path = batchedDotsPath
        gridDotsNode.fillColor = theme.gridDotUIColor

        let runway = max(boardW, boardH) + cellSize * 10
        for arrow in board.arrows {
            let points = arrow.cells.map { positionForGridPoint($0, in: board) }
            let node = ArrowNode(
                arrow: arrow,
                cellPoints: points,
                cellSize: cellSize,
                normalColor: theme.arrowInkUIColor,
                failedColor: theme.arrowFailedUIColor,
                isInitiallyFailed: board.failedArrowIDs.contains(arrow.id),
                exitRunway: runway
            )
            arrowsLayer.addChild(node)
            arrowNodes[arrow.id] = node
            for cell in arrow.cells {
                cellToArrowID[cell] = arrow.id
            }
        }
    }

    private func positionForGridPoint(_ point: GridPoint, in board: PuzzleBoard) -> CGPoint {
        let originX = -CGFloat(board.width) * cellSize / 2.0 + cellSize / 2.0
        let originY = -CGFloat(board.height) * cellSize / 2.0 + cellSize / 2.0
        return CGPoint(
            x: originX + CGFloat(point.x) * cellSize,
            y: originY + CGFloat(point.y) * cellSize
        )
    }

    private func gridPoint(forScenePoint scenePoint: CGPoint, in board: PuzzleBoard) -> GridPoint? {
        let originX = -CGFloat(board.width) * cellSize / 2.0
        let originY = -CGFloat(board.height) * cellSize / 2.0
        let col = Int(floor((scenePoint.x - originX) / cellSize))
        let row = Int(floor((scenePoint.y - originY) / cellSize))
        let pt = GridPoint(x: col, y: row)
        return board.isInside(pt) ? pt : nil
    }
}
