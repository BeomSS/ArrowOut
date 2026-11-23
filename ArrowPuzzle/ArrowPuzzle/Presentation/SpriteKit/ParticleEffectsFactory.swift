import SpriteKit
import UIKit

/// Procedurally generates soft particle textures and reusable SpriteKit particle bursts
/// without requiring external `.sks` or `.png` resources.
final class ParticleEffectsFactory {
    private let softCircleTexture: SKTexture
    private let diamondTexture: SKTexture

    init() {
        self.softCircleTexture = Self.makeSoftCircleTexture(diameter: 32)
        self.diamondTexture = Self.makeDiamondTexture(size: 28)
    }

    /// Burst emitted when an arrow escapes the board.
    func makeEscapeBurst(at position: CGPoint, color: UIColor, direction: Direction) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = softCircleTexture
        emitter.position = position
        emitter.particleBirthRate = 180
        emitter.numParticlesToEmit = 18
        emitter.particleLifetime = 0.42
        emitter.particleLifetimeRange = 0.15
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 75
        emitter.emissionAngle = CGFloat(direction.radians)
        emitter.emissionAngleRange = .pi * 0.65
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -2.2
        emitter.particleScale = 0.36
        emitter.particleScaleRange = 0.18
        emitter.particleScaleSpeed = -0.65
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 50
        return emitter
    }

    /// Crisp trailing sparkles while an arrow glides out along its track.
    func makeEscapeTrail(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = softCircleTexture
        emitter.particleBirthRate = 95
        emitter.particleLifetime = 0.28
        emitter.particleLifetimeRange = 0.08
        emitter.particleSpeed = 24
        emitter.particleSpeedRange = 20
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.72
        emitter.particleAlphaSpeed = -2.6
        emitter.particleScale = 0.30
        emitter.particleScaleRange = 0.12
        emitter.particleScaleSpeed = -0.75
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 18
        return emitter
    }

    /// Red/orange collision sparks when a tapped arrow slams into a blocker.
    func makeBlockedSparks(at position: CGPoint, color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = diamondTexture
        emitter.position = position
        emitter.particleBirthRate = 240
        emitter.numParticlesToEmit = 16
        emitter.particleLifetime = 0.32
        emitter.particleLifetimeRange = 0.12
        emitter.particleSpeed = 155
        emitter.particleSpeedRange = 85
        emitter.emissionAngleRange = .pi * 2
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 6.0
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -3.1
        emitter.particleScale = 0.34
        emitter.particleScaleRange = 0.14
        emitter.particleScaleSpeed = -0.75
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 60
        return emitter
    }

    /// Celebratory multi-color confetti burst on level clear.
    func makeCelebrationConfetti(at position: CGPoint, colors: [UIColor]) -> [SKEmitterNode] {
        colors.prefix(4).enumerated().map { index, color in
            let emitter = SKEmitterNode()
            emitter.particleTexture = index.isMultiple(of: 2) ? diamondTexture : softCircleTexture
            emitter.position = position
            emitter.particleBirthRate = 120
            emitter.numParticlesToEmit = 22
            emitter.particleLifetime = 1.35
            emitter.particleLifetimeRange = 0.45
            emitter.particleSpeed = 260
            emitter.particleSpeedRange = 140
            emitter.emissionAngle = .pi / 2
            emitter.emissionAngleRange = .pi * 1.4
            emitter.yAcceleration = -360
            emitter.particleRotationRange = .pi * 2
            emitter.particleRotationSpeed = 4.5
            emitter.particleAlpha = 1.0
            emitter.particleAlphaSpeed = -0.75
            emitter.particleScale = 0.45
            emitter.particleScaleRange = 0.22
            emitter.particleColor = color
            emitter.particleColorBlendFactor = 1.0
            emitter.zPosition = 90
            return emitter
        }
    }

    private static func makeSoftCircleTexture(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0.65).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.55, 1.0]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) {
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: diameter / 2,
                    options: []
                )
            }
        }
        return SKTexture(image: image)
    }

    private static func makeDiamondTexture(size side: CGFloat) -> SKTexture {
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            cgCtx.setFillColor(UIColor.white.cgColor)
            let mid = side / 2
            cgCtx.move(to: CGPoint(x: mid, y: 2))
            cgCtx.addLine(to: CGPoint(x: side - 2, y: mid))
            cgCtx.addLine(to: CGPoint(x: mid, y: side - 2))
            cgCtx.addLine(to: CGPoint(x: 2, y: mid))
            cgCtx.closePath()
            cgCtx.fillPath()
        }
        return SKTexture(image: image)
    }
}
