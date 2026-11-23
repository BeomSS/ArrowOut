import SpriteKit
import UIKit

/// Renders a single straight, 1-cell, or bent/snaking arrow and animates it smoothly along its 1D track.
final class ArrowNode: SKNode {
    let arrow: Arrow
    private let cellSize: CGFloat
    private let trackPoints: [CGPoint]
    private let trackCumulativeLengths: [CGFloat]
    private let arrowLength: CGFloat

    private var normalColor: UIColor
    private var failedColor: UIColor
    private(set) var isMarkedFailed = false
    private(set) var isAnimating = false

    private let shadowShaftNode = SKShapeNode()
    private let glowShaftNode = SKShapeNode()
    private let shaftNode = SKShapeNode()
    private let headNode = SKShapeNode()
    private let headShadowNode = SKShapeNode()

    private var activeColor: UIColor {
        isMarkedFailed ? failedColor : normalColor
    }

    private var strokeWidth: CGFloat { cellSize * 0.28 }
    private var cornerRadius: CGFloat { cellSize * 0.24 }
    private var headTrim: CGFloat { cellSize * 0.16 }

    init(
        arrow: Arrow,
        cellPoints: [CGPoint],
        cellSize: CGFloat,
        normalColor: UIColor,
        failedColor: UIColor,
        isInitiallyFailed: Bool = false,
        exitRunway: CGFloat
    ) {
        self.arrow = arrow
        self.cellSize = cellSize
        self.normalColor = normalColor
        self.failedColor = failedColor
        self.isMarkedFailed = isInitiallyFailed

        let dirVector = CGVector(
            dx: CGFloat(arrow.headDirection.dx),
            dy: CGFloat(arrow.headDirection.dy)
        )

        // Build base polyline; for 1-cell arrows, create a compact centered stub leading into the arrowhead
        let visualPoints: [CGPoint]
        if cellPoints.count == 1, let center = cellPoints.first {
            let tailStub = CGPoint(
                x: center.x - dirVector.dx * (cellSize * 0.24),
                y: center.y - dirVector.dy * (cellSize * 0.24)
            )
            let headCenter = CGPoint(
                x: center.x + dirVector.dx * (cellSize * 0.14),
                y: center.y + dirVector.dy * (cellSize * 0.14)
            )
            visualPoints = [tailStub, headCenter]
        } else {
            visualPoints = cellPoints
        }

        // Build full 1D rail track: tail -> bends -> head -> extended exit ray
        var track = visualPoints
        if let headPoint = visualPoints.last {
            let exitEnd = CGPoint(
                x: headPoint.x + dirVector.dx * exitRunway,
                y: headPoint.y + dirVector.dy * exitRunway
            )
            track.append(exitEnd)
        }
        self.trackPoints = track

        // Precompute cumulative arc lengths along trackPoints
        var cumulative: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<track.count {
            let dist = hypot(track[i].x - track[i - 1].x, track[i].y - track[i - 1].y)
            total += dist
            cumulative.append(total)
        }
        self.trackCumulativeLengths = cumulative
        self.arrowLength = cumulative[visualPoints.count - 1]

        super.init()
        self.zPosition = 20
        setupNodes()
        render(atTrackOffset: 0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupNodes() {
        // Soft drop shadow
        shadowShaftNode.lineWidth = strokeWidth
        shadowShaftNode.lineCap = .round
        shadowShaftNode.lineJoin = .round
        shadowShaftNode.strokeColor = UIColor.black.withAlphaComponent(0.10)
        shadowShaftNode.fillColor = .clear
        shadowShaftNode.position = CGPoint(x: 0, y: -cellSize * 0.05)
        shadowShaftNode.zPosition = 0
        addChild(shadowShaftNode)

        // Hint / Highlight glow layer (hidden by default)
        glowShaftNode.lineWidth = strokeWidth * 1.65
        glowShaftNode.lineCap = .round
        glowShaftNode.lineJoin = .round
        glowShaftNode.strokeColor = .clear
        glowShaftNode.fillColor = .clear
        glowShaftNode.alpha = 0
        glowShaftNode.zPosition = 1
        addChild(glowShaftNode)

        // Main arrow shaft
        shaftNode.lineWidth = strokeWidth
        shaftNode.lineCap = .round
        shaftNode.lineJoin = .round
        shaftNode.strokeColor = activeColor
        shaftNode.fillColor = .clear
        shaftNode.zPosition = 2
        addChild(shaftNode)

        // Arrowhead geometry (pointing right at angle 0)
        let headPath = makeArrowHeadPath()
        headShadowNode.path = headPath
        headShadowNode.fillColor = UIColor.black.withAlphaComponent(0.10)
        headShadowNode.strokeColor = .clear
        headShadowNode.zRotation = CGFloat(arrow.headDirection.radians)
        headShadowNode.zPosition = 1
        addChild(headShadowNode)

        headNode.path = headPath
        headNode.fillColor = activeColor
        headNode.strokeColor = activeColor
        headNode.lineWidth = max(1.5, cellSize * 0.04)
        headNode.lineJoin = .round
        headNode.zRotation = CGFloat(arrow.headDirection.radians)
        headNode.zPosition = 4
        addChild(headNode)
    }

    private func makeArrowHeadPath() -> CGPath {
        let tipX = cellSize * 0.34
        let backX = -cellSize * 0.20
        let wingY = cellSize * 0.28
        let notchX = -cellSize * 0.10

        let path = CGMutablePath()
        path.move(to: CGPoint(x: tipX, y: 0))
        path.addLine(to: CGPoint(x: backX, y: wingY))
        path.addLine(to: CGPoint(x: notchX, y: 0))
        path.addLine(to: CGPoint(x: backX, y: -wingY))
        path.closeSubpath()
        return path
    }

    private func applyActiveColor() {
        let color = activeColor
        shaftNode.strokeColor = color
        headNode.fillColor = color
        headNode.strokeColor = color
    }

    func updateThemeColor(normalColor: UIColor, failedColor: UIColor, isDark: Bool) {
        self.normalColor = normalColor
        self.failedColor = failedColor
        applyActiveColor()

        let shadowAlpha: CGFloat = isDark ? 0.28 : 0.10
        shadowShaftNode.strokeColor = UIColor.black.withAlphaComponent(shadowAlpha)
        headShadowNode.fillColor = UIColor.black.withAlphaComponent(shadowAlpha)
    }

    // MARK: - Track Slicing & Smooth Rounded Polyline Rendering

    /// Updates the shaft and head geometry for an arc-length offset `s` along the arrow's rail.
    func render(atTrackOffset s: CGFloat) {
        let startDist = max(0, s)
        let tipDist = s + arrowLength
        let shaftEndDist = max(startDist + 2, tipDist - headTrim)

        let shaftSlice = sliceTrack(from: startDist, to: shaftEndDist)
        let roundedPath = Self.buildRoundedPath(from: shaftSlice, cornerRadius: cornerRadius)

        shaftNode.path = roundedPath
        shadowShaftNode.path = roundedPath
        glowShaftNode.path = roundedPath

        let tipPos = pointOnTrack(at: tipDist)
        headNode.position = tipPos
        headShadowNode.position = CGPoint(x: tipPos.x, y: tipPos.y - cellSize * 0.05)
    }

    private func sliceTrack(from startDist: CGFloat, to endDist: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        result.append(pointOnTrack(at: startDist))

        for i in 1..<(trackPoints.count - 1) {
            let d = trackCumulativeLengths[i]
            if d > startDist + 0.5 && d < endDist - 0.5 {
                result.append(trackPoints[i])
            }
        }

        result.append(pointOnTrack(at: endDist))
        return result
    }

    private func pointOnTrack(at distance: CGFloat) -> CGPoint {
        guard trackPoints.count >= 2 else { return .zero }
        if distance <= 0 {
            return trackPoints[0]
        }
        let maxDist = trackCumulativeLengths.last ?? 0
        if distance >= maxDist {
            return trackPoints.last ?? .zero
        }

        for i in 1..<trackPoints.count {
            let segStart = trackCumulativeLengths[i - 1]
            let segEnd = trackCumulativeLengths[i]
            if distance <= segEnd {
                let segLen = max(0.0001, segEnd - segStart)
                let t = (distance - segStart) / segLen
                let p0 = trackPoints[i - 1]
                let p1 = trackPoints[i]
                return CGPoint(
                    x: p0.x + (p1.x - p0.x) * t,
                    y: p0.y + (p1.y - p0.y) * t
                )
            }
        }
        return trackPoints.last ?? .zero
    }

    /// Removes near-duplicate and collinear intermediate points so straight segments
    /// become single clean lines without degenerate intermediate vertices.
    static func simplifyPoints(_ points: [CGPoint]) -> [CGPoint] {
        var deduped: [CGPoint] = []
        deduped.reserveCapacity(points.count)
        for point in points {
            if let last = deduped.last, hypot(point.x - last.x, point.y - last.y) < 0.5 {
                continue
            }
            deduped.append(point)
        }
        guard deduped.count >= 3 else { return deduped }

        var simplified: [CGPoint] = [deduped[0]]
        for i in 1..<(deduped.count - 1) {
            let prev = simplified[simplified.count - 1]
            let curr = deduped[i]
            let next = deduped[i + 1]

            let v1x = curr.x - prev.x
            let v1y = curr.y - prev.y
            let v2x = next.x - curr.x
            let v2y = next.y - curr.y
            let len1 = hypot(v1x, v1y)
            let len2 = hypot(v2x, v2y)
            guard len1 > 0.001, len2 > 0.001 else { continue }

            let cross = abs((v1x * v2y - v1y * v2x) / (len1 * len2))
            if cross > 0.01 {
                simplified.append(curr)
            }
        }
        if let last = deduped.last {
            simplified.append(last)
        }
        return simplified
    }

    /// Builds a smooth rounded polyline using explicitly sampled circular quarter-arcs (`addLine`)
    /// instead of Bézier curves to avoid SpriteKit `SKShapeNode` stroke tessellation artifacts.
    static func buildRoundedPath(from rawPoints: [CGPoint], cornerRadius: CGFloat) -> CGPath {
        let points = simplifyPoints(rawPoints)
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)

        guard points.count >= 3 else {
            if points.count == 2 {
                path.addLine(to: points[1])
            }
            return path
        }

        let arcSegments = 8

        for i in 1..<(points.count - 1) {
            let prev = points[i - 1]
            let curr = points[i]
            let next = points[i + 1]

            let v1x = prev.x - curr.x
            let v1y = prev.y - curr.y
            let v2x = next.x - curr.x
            let v2y = next.y - curr.y
            let len1 = hypot(v1x, v1y)
            let len2 = hypot(v2x, v2y)
            guard len1 > 0.001, len2 > 0.001 else { continue }

            let u1x = v1x / len1
            let u1y = v1y / len1
            let u2x = v2x / len2
            let u2y = v2y / len2

            let radius = min(cornerRadius, len1 * 0.48, len2 * 0.48)
            if radius > 1.0 {
                let pStart = CGPoint(x: curr.x + u1x * radius, y: curr.y + u1y * radius)
                path.addLine(to: pStart)

                let centerX = curr.x + (u1x + u2x) * radius
                let centerY = curr.y + (u1y + u2y) * radius

                for step in 1...arcSegments {
                    let theta = (CGFloat(step) / CGFloat(arcSegments)) * (.pi / 2.0)
                    let cosT = cos(theta)
                    let sinT = sin(theta)
                    let arcPt = CGPoint(
                        x: centerX - u2x * (radius * cosT) - u1x * (radius * sinT),
                        y: centerY - u2y * (radius * cosT) - u1y * (radius * sinT)
                    )
                    path.addLine(to: arcPt)
                }
            } else {
                path.addLine(to: curr)
            }
        }

        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }

    // MARK: - Animations

    /// Smoothly slithers the arrow along its track and off the board (keeping red color if previously failed).
    func animateEscape(
        exitDistance: CGFloat,
        particlesFactory: ParticleEffectsFactory,
        parentScene: SKScene,
        completion: @escaping () -> Void
    ) {
        guard !isAnimating else { return }
        isAnimating = true
        clearHint()
        zPosition = 35

        let effectColor = activeColor
        let totalTravel = arrowLength + exitDistance
        let duration: TimeInterval = min(0.55, max(0.30, Double(totalTravel / (cellSize * 24.0))))

        let trail = particlesFactory.makeEscapeTrail(color: effectColor)
        trail.targetNode = parentScene
        headNode.addChild(trail)

        let burst = particlesFactory.makeEscapeBurst(
            at: headNode.position,
            color: effectColor,
            direction: arrow.headDirection
        )
        parentScene.addChild(burst)
        burst.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))

        let slideAction = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let rawT = min(1.0, max(0.0, elapsed / CGFloat(duration)))
            let easedT = rawT < 0.12
                ? (rawT / 0.12) * 0.04
                : 0.04 + 0.96 * pow((rawT - 0.12) / 0.88, 2.05)

            self.render(atTrackOffset: totalTravel * easedT)

            if rawT > 0.72 {
                let fadeProgress = (rawT - 0.72) / 0.28
                self.alpha = max(0, 1.0 - fadeProgress)
            }
        }

        run(.sequence([
            slideAction,
            .run { [weak self] in
                trail.particleBirthRate = 0
                self?.removeFromParent()
                completion()
            }
        ]))
    }

    /// Lunges toward the blocking cell, turns persistently red until it eventually escapes,
    /// spawns impact sparks, and recoils back to its resting position.
    func animateBlocked(
        gapInCells: Int,
        blockedColor: UIColor,
        impactPoint: CGPoint,
        particlesFactory: ParticleEffectsFactory,
        parentScene: SKScene
    ) {
        guard !isAnimating else { return }
        isAnimating = true
        isMarkedFailed = true
        failedColor = blockedColor
        zPosition = 32

        let maxLunge = max(cellSize * 0.24, (CGFloat(gapInCells) - 0.62) * cellSize)
        let lungeDuration: TimeInterval = min(0.14, 0.065 + Double(gapInCells) * 0.018)
        let returnDuration: TimeInterval = min(0.22, lungeDuration * 1.45)

        let lungeForward = SKAction.customAction(withDuration: lungeDuration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = min(1.0, elapsed / CGFloat(lungeDuration))
            let eased = t * t
            self.render(atTrackOffset: maxLunge * eased)
        }

        let impactEffects = SKAction.run { [weak self] in
            guard let self else { return }
            self.applyActiveColor()

            let sparks = particlesFactory.makeBlockedSparks(at: impactPoint, color: blockedColor)
            parentScene.addChild(sparks)
            sparks.run(.sequence([.wait(forDuration: 0.5), .removeFromParent()]))
        }

        let recoilBack = SKAction.customAction(withDuration: returnDuration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = min(1.0, elapsed / CGFloat(returnDuration))
            let remaining = pow(1.0 - t, 2.2)
            self.render(atTrackOffset: maxLunge * remaining)
        }

        let perpX: CGFloat = arrow.headDirection.dx == 0 ? 5.0 : 0.0
        let perpY: CGFloat = arrow.headDirection.dy == 0 ? 5.0 : 0.0
        let microShake = SKAction.sequence([
            .moveBy(x: perpX, y: perpY, duration: 0.03),
            .moveBy(x: -perpX * 2, y: -perpY * 2, duration: 0.045),
            .moveBy(x: perpX, y: perpY, duration: 0.03)
        ])

        let finishAnimation = SKAction.run { [weak self] in
            guard let self else { return }
            // Keep failed red color persistently until this arrow escapes!
            self.applyActiveColor()
            self.render(atTrackOffset: 0)
            self.zPosition = 20
            self.isAnimating = false
        }

        run(.sequence([
            lungeForward,
            impactEffects,
            .group([recoilBack, microShake]),
            finishAnimation
        ]))
    }

    /// Brief subtle visual pulse on the blocking arrow so the player sees what stopped the move.
    func pulseAsBlocker(highlightColor: UIColor) {
        guard !isAnimating else { return }
        glowShaftNode.strokeColor = highlightColor.withAlphaComponent(0.45)
        glowShaftNode.removeAllActions()
        glowShaftNode.run(.sequence([
            .fadeAlpha(to: 0.75, duration: 0.06),
            .fadeAlpha(to: 0.0, duration: 0.26)
        ]))
    }

    /// Highlights this arrow as the suggested Hint.
    func showHint(glowColor: UIColor) {
        glowShaftNode.strokeColor = glowColor.withAlphaComponent(0.75)
        glowShaftNode.removeAllActions()
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.95, duration: 0.42),
            .fadeAlpha(to: 0.25, duration: 0.42)
        ])
        glowShaftNode.run(.repeatForever(pulse), withKey: "hintPulse")
    }

    func clearHint() {
        glowShaftNode.removeAction(forKey: "hintPulse")
        glowShaftNode.alpha = 0
    }

    /// Returns the visual midpoint of the arrow in parent coordinates for Pan-to-Hint camera focus.
    func focusPoint() -> CGPoint {
        pointOnTrack(at: arrowLength * 0.65)
    }
}
