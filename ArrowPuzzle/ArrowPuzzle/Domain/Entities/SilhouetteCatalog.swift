import Foundation

/// Composable 2D geometric primitives in normalized `[-1, 1] × [-1, 1]` space (`+y` = up).
public enum ShapePrimitive: Sendable {
    case circle(cx: Double, cy: Double, r: Double)
    case ellipse(cx: Double, cy: Double, rx: Double, ry: Double, angleDeg: Double = 0)
    case rect(minX: Double, minY: Double, maxX: Double, maxY: Double)
    case capsule(x1: Double, y1: Double, x2: Double, y2: Double, r: Double)
    case polygon([(Double, Double)])
    case analyticHeart

    func contains(x: Double, y: Double) -> Bool {
        switch self {
        case let .circle(cx, cy, r):
            let dx = x - cx
            let dy = y - cy
            return dx * dx + dy * dy <= r * r

        case let .ellipse(cx, cy, rx, ry, angleDeg):
            let dx = x - cx
            let dy = y - cy
            let rad = -angleDeg * .pi / 180.0
            let cosA = cos(rad)
            let sinA = sin(rad)
            let lx = dx * cosA - dy * sinA
            let ly = dx * sinA + dy * cosA
            let nx = lx / max(0.001, rx)
            let ny = ly / max(0.001, ry)
            return nx * nx + ny * ny <= 1.0

        case let .rect(minX, minY, maxX, maxY):
            return x >= minX && x <= maxX && y >= minY && y <= maxY

        case let .capsule(x1, y1, x2, y2, r):
            let vx = x2 - x1
            let vy = y2 - y1
            let wx = x - x1
            let wy = y - y1
            let lenSq = vx * vx + vy * vy
            let t = lenSq > 1e-9 ? max(0.0, min(1.0, (wx * vx + wy * vy) / lenSq)) : 0.0
            let px = x1 + t * vx
            let py = y1 + t * vy
            let dx = x - px
            let dy = y - py
            return dx * dx + dy * dy <= r * r

        case let .polygon(pts):
            guard pts.count >= 3 else { return false }
            var inside = false
            var j = pts.count - 1
            for i in 0..<pts.count {
                let xi = pts[i].0, yi = pts[i].1
                let xj = pts[j].0, yj = pts[j].1
                let intersect = ((yi > y) != (yj > y)) &&
                    (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi)
                if intersect { inside.toggle() }
                j = i
            }
            return inside

        case .analyticHeart:
            let nx = x * 1.28
            let ny = (y + 0.02) * 1.32
            let a = nx * nx + ny * ny - 1.0
            return a * a * a - nx * nx * ny * ny * ny <= 0.02
        }
    }
}

public enum ShapeOp: Sendable {
    case add(ShapePrimitive)
    case subtract(ShapePrimitive)
}

/// 52 distinct, single-connected silhouettes spanning A–Z (2 iconic themes per letter).
public enum SilhouetteID: String, Codable, Hashable, Sendable, CaseIterable {
    // A
    case apple, airplane
    // B
    case bee, butterfly
    // C
    case cat, crown
    // D
    case diamond, donut
    // E
    case egg, evergreen
    // F
    case fish, flower
    // G
    case ghost, gem
    // H
    case heart, house
    // I
    case iceCream, igloo
    // J
    case jellyfish, jug
    // K
    case key, kite
    // L
    case leaf, lamp
    // M
    case moon, mushroom
    // N
    case note, necktie
    // O
    case owl, octagonRing
    // P
    case pineTree, pear
    // Q
    case queenCrown, quill
    // R
    case rocket, ring
    // S
    case star, shield
    // T
    case tulip, trophy
    // U
    case umbrella, ufo
    // V
    case vase, volcano
    // W
    case whale, windmill
    // X
    case xCross, cross
    // Y
    case yacht, ySlingshot
    // Z
    case zap, zeppelin

    public var letter: String {
        switch self {
        case .apple, .airplane: return "A"
        case .bee, .butterfly: return "B"
        case .cat, .crown: return "C"
        case .diamond, .donut: return "D"
        case .egg, .evergreen: return "E"
        case .fish, .flower: return "F"
        case .ghost, .gem: return "G"
        case .heart, .house: return "H"
        case .iceCream, .igloo: return "I"
        case .jellyfish, .jug: return "J"
        case .key, .kite: return "K"
        case .leaf, .lamp: return "L"
        case .moon, .mushroom: return "M"
        case .note, .necktie: return "N"
        case .owl, .octagonRing: return "O"
        case .pineTree, .pear: return "P"
        case .queenCrown, .quill: return "Q"
        case .rocket, .ring: return "R"
        case .star, .shield: return "S"
        case .tulip, .trophy: return "T"
        case .umbrella, .ufo: return "U"
        case .vase, .volcano: return "V"
        case .whale, .windmill: return "W"
        case .xCross, .cross: return "X"
        case .yacht, .ySlingshot: return "Y"
        case .zap, .zeppelin: return "Z"
        }
    }

    public var koreanName: String {
        switch self {
        case .apple: return "사과"
        case .airplane: return "비행기"
        case .bee: return "꿀벌"
        case .butterfly: return "나비"
        case .cat: return "고양이"
        case .crown: return "왕관"
        case .diamond: return "다이아몬드"
        case .donut: return "도넛"
        case .egg: return "달걀"
        case .evergreen: return "전나무"
        case .fish: return "물고기"
        case .flower: return "꽃"
        case .ghost: return "유령"
        case .gem: return "보석"
        case .heart: return "하트"
        case .house: return "집"
        case .iceCream: return "아이스크림"
        case .igloo: return "이글루"
        case .jellyfish: return "해파리"
        case .jug: return "물병"
        case .key: return "열쇠"
        case .kite: return "연"
        case .leaf: return "나뭇잎"
        case .lamp: return "램프"
        case .moon: return "초승달"
        case .mushroom: return "버섯"
        case .note: return "음표"
        case .necktie: return "넥타이"
        case .owl: return "부엉이"
        case .octagonRing: return "팔각 링"
        case .pineTree: return "소나무"
        case .pear: return "배"
        case .queenCrown: return "여왕 왕관"
        case .quill: return "깃털 펜"
        case .rocket: return "로켓"
        case .ring: return "반지"
        case .star: return "별"
        case .shield: return "방패"
        case .tulip: return "튤립"
        case .trophy: return "트로피"
        case .umbrella: return "우산"
        case .ufo: return "비행접시"
        case .vase: return "꽃병"
        case .volcano: return "화산"
        case .whale: return "고래"
        case .windmill: return "풍차"
        case .xCross: return "X 크로스"
        case .cross: return "십자"
        case .yacht: return "요트"
        case .ySlingshot: return "새총"
        case .zap: return "번개"
        case .zeppelin: return "비행선"
        }
    }

    public var displayLabel: String {
        String(localized: String.LocalizationValue(koreanName))
    }

    public var symbolName: String {
        switch self {
        case .apple: return "apple.logo"
        case .airplane: return "airplane"
        case .bee: return "ant.fill"
        case .butterfly: return "ladybug.fill"
        case .cat: return "cat.fill"
        case .crown, .queenCrown: return "crown.fill"
        case .diamond, .gem: return "diamond.fill"
        case .donut, .octagonRing, .ring: return "circle.circle.fill"
        case .egg, .pear: return "oval.fill"
        case .evergreen, .pineTree: return "tree.fill"
        case .fish, .whale: return "fish.fill"
        case .flower, .tulip: return "camera.macro"
        case .ghost: return "theatermasks.fill"
        case .heart: return "heart.fill"
        case .house, .igloo: return "house.fill"
        case .iceCream: return "cone.fill"
        case .jellyfish: return "drop.fill"
        case .jug, .vase: return "mug.fill"
        case .key: return "key.fill"
        case .kite: return "wind"
        case .leaf, .quill: return "leaf.fill"
        case .lamp: return "lamp.table.fill"
        case .moon: return "moon.fill"
        case .mushroom: return "umbrella.fill"
        case .note: return "music.note"
        case .necktie: return "suit.diamond.fill"
        case .owl: return "bird.fill"
        case .rocket: return "paperplane.fill"
        case .star: return "star.fill"
        case .shield: return "shield.fill"
        case .trophy: return "trophy.fill"
        case .umbrella: return "umbrella.fill"
        case .ufo, .zeppelin: return "sparkles"
        case .volcano: return "mountain.2.fill"
        case .windmill: return "fanblades.fill"
        case .xCross: return "xmark"
        case .cross: return "cross.fill"
        case .yacht: return "sailboat.fill"
        case .ySlingshot: return "tuningfork"
        case .zap: return "bolt.fill"
        }
    }

    /// Declarative vector silhouette recipe in normalized `[-1, 1] × [-1, 1]`.
    public var recipe: [ShapeOp] {
        switch self {
        // MARK: A
        case .apple:
            return [
                .add(.ellipse(cx: -0.28, cy: -0.14, rx: 0.56, ry: 0.68)),
                .add(.ellipse(cx: 0.28, cy: -0.14, rx: 0.56, ry: 0.68)),
                .add(.capsule(x1: 0.0, y1: 0.35, x2: 0.06, y2: 0.86, r: 0.11)),
                .add(.ellipse(cx: 0.34, cy: 0.72, rx: 0.28, ry: 0.15, angleDeg: 28)),
                .subtract(.circle(cx: 0.0, cy: -0.84, r: 0.18))
            ]
        case .airplane:
            return [
                .add(.capsule(x1: 0.0, y1: -0.82, x2: 0.0, y2: 0.82, r: 0.18)),
                .add(.polygon([(-0.92, -0.08), (-0.12, 0.34), (0.12, 0.34), (0.92, -0.08), (0.86, -0.26), (0.12, -0.02), (-0.12, -0.02), (-0.86, -0.26)])),
                .add(.polygon([(-0.46, -0.86), (-0.08, -0.52), (0.08, -0.52), (0.46, -0.86), (0.42, -0.94), (-0.42, -0.94)]))
            ]

        // MARK: B
        case .bee:
            return [
                .add(.ellipse(cx: -0.34, cy: 0.44, rx: 0.34, ry: 0.44, angleDeg: 26)),
                .add(.ellipse(cx: 0.34, cy: 0.44, rx: 0.34, ry: 0.44, angleDeg: -26)),
                .add(.ellipse(cx: 0.0, cy: -0.20, rx: 0.62, ry: 0.52)),
                .add(.polygon([(-0.22, -0.66), (0.22, -0.66), (0.0, -0.95)]))
            ]
        case .butterfly:
            return [
                .add(.ellipse(cx: -0.56, cy: 0.42, rx: 0.40, ry: 0.36, angleDeg: -24)),
                .add(.ellipse(cx: 0.56, cy: 0.42, rx: 0.40, ry: 0.36, angleDeg: 24)),
                .add(.ellipse(cx: -0.44, cy: -0.42, rx: 0.32, ry: 0.34, angleDeg: 22)),
                .add(.ellipse(cx: 0.44, cy: -0.42, rx: 0.32, ry: 0.34, angleDeg: -22)),
                .add(.capsule(x1: 0.0, y1: -0.68, x2: 0.0, y2: 0.72, r: 0.16)),
                .subtract(.circle(cx: -0.82, cy: -0.02, r: 0.24)),
                .subtract(.circle(cx: 0.82, cy: -0.02, r: 0.24))
            ]

        // MARK: C
        case .cat:
            return [
                .add(.ellipse(cx: 0.0, cy: -0.14, rx: 0.80, ry: 0.68)),
                .add(.polygon([(-0.74, 0.14), (-0.70, 0.90), (-0.16, 0.44)])),
                .add(.polygon([(0.74, 0.14), (0.70, 0.90), (0.16, 0.44)]))
            ]
        case .crown:
            return [
                .add(.rect(minX: -0.82, minY: -0.70, maxX: 0.82, maxY: -0.18)),
                .add(.polygon([
                    (-0.82, -0.22), (-0.90, 0.62), (-0.36, 0.10),
                    (0.0, 0.82),
                    (0.36, 0.10), (0.90, 0.62), (0.82, -0.22)
                ]))
            ]

        // MARK: D
        case .diamond:
            return [
                .add(.polygon([(0.0, 0.96), (0.96, 0.0), (0.0, -0.96), (-0.96, 0.0)]))
            ]
        case .donut:
            return [
                .add(.circle(cx: 0.0, cy: 0.0, r: 0.94)),
                .subtract(.circle(cx: 0.0, cy: 0.0, r: 0.38))
            ]

        // MARK: E
        case .egg:
            return [
                .add(.ellipse(cx: 0.0, cy: -0.18, rx: 0.72, ry: 0.74)),
                .add(.ellipse(cx: 0.0, cy: 0.24, rx: 0.56, ry: 0.68))
            ]
        case .evergreen:
            return [
                .add(.polygon([(0.0, 0.96), (-0.52, 0.26), (0.52, 0.26)])),
                .add(.polygon([(0.0, 0.54), (-0.72, -0.18), (0.72, -0.18)])),
                .add(.polygon([(0.0, 0.10), (-0.88, -0.62), (0.88, -0.62)])),
                .add(.rect(minX: -0.22, minY: -0.94, maxX: 0.22, maxY: -0.58))
            ]

        // MARK: F
        case .fish:
            return [
                .add(.ellipse(cx: -0.14, cy: 0.0, rx: 0.74, ry: 0.54)),
                .add(.polygon([(0.40, 0.0), (0.94, 0.56), (0.94, -0.56)])),
                .add(.polygon([(-0.22, 0.44), (0.08, 0.80), (0.24, 0.38)]))
            ]
        case .flower:
            return [
                .add(.circle(cx: 0.0, cy: 0.0, r: 0.46)),
                .add(.circle(cx: 0.0, cy: 0.56, r: 0.36)),
                .add(.circle(cx: 0.53, cy: 0.17, r: 0.36)),
                .add(.circle(cx: 0.33, cy: -0.46, r: 0.36)),
                .add(.circle(cx: -0.33, cy: -0.46, r: 0.36)),
                .add(.circle(cx: -0.53, cy: 0.17, r: 0.36))
            ]

        // MARK: G
        case .ghost:
            return [
                .add(.circle(cx: 0.0, cy: 0.20, r: 0.74)),
                .add(.rect(minX: -0.74, minY: -0.64, maxX: 0.74, maxY: 0.22)),
                .add(.circle(cx: -0.49, cy: -0.64, r: 0.25)),
                .add(.circle(cx: 0.0, cy: -0.64, r: 0.25)),
                .add(.circle(cx: 0.49, cy: -0.64, r: 0.25)),
                .subtract(.circle(cx: -0.28, cy: 0.22, r: 0.16)),
                .subtract(.circle(cx: 0.28, cy: 0.22, r: 0.16))
            ]
        case .gem:
            return [
                .add(.polygon([(-0.56, 0.78), (0.56, 0.78), (0.94, 0.22), (0.0, -0.90), (-0.94, 0.22)]))
            ]

        // MARK: H
        case .heart:
            return [
                .add(.analyticHeart)
            ]
        case .house:
            return [
                .add(.polygon([(0.0, 0.92), (-0.94, 0.08), (0.94, 0.08)])),
                .add(.rect(minX: -0.70, minY: -0.88, maxX: 0.70, maxY: 0.12)),
                .add(.rect(minX: 0.34, minY: 0.26, maxX: 0.62, maxY: 0.80))
            ]

        // MARK: I
        case .iceCream:
            return [
                .add(.polygon([(-0.46, 0.02), (0.46, 0.02), (0.0, -0.94)])),
                .add(.circle(cx: 0.0, cy: 0.46, r: 0.48)),
                .add(.circle(cx: -0.42, cy: 0.16, r: 0.30)),
                .add(.circle(cx: 0.42, cy: 0.16, r: 0.30))
            ]
        case .igloo:
            return [
                .add(.circle(cx: 0.0, cy: -0.22, r: 0.88)),
                .subtract(.rect(minX: -1.1, minY: -1.2, maxX: 1.1, maxY: -0.58)),
                .subtract(.circle(cx: 0.0, cy: -0.58, r: 0.32))
            ]

        // MARK: J
        case .jellyfish:
            return [
                .add(.ellipse(cx: 0.0, cy: 0.22, rx: 0.82, ry: 0.62)),
                .subtract(.rect(minX: -1.0, minY: -0.60, maxX: 1.0, maxY: -0.04)),
                .add(.capsule(x1: -0.46, y1: 0.04, x2: -0.52, y2: -0.82, r: 0.15)),
                .add(.capsule(x1: 0.0, y1: 0.04, x2: 0.0, y2: -0.88, r: 0.16)),
                .add(.capsule(x1: 0.46, y1: 0.04, x2: 0.52, y2: -0.82, r: 0.15))
            ]
        case .jug:
            return [
                .add(.ellipse(cx: -0.10, cy: -0.28, rx: 0.66, ry: 0.60)),
                .add(.rect(minX: -0.38, minY: 0.18, maxX: 0.18, maxY: 0.84)),
                .add(.rect(minX: -0.48, minY: 0.72, maxX: 0.28, maxY: 0.90)),
                .add(.circle(cx: 0.52, cy: 0.16, r: 0.36)),
                .subtract(.circle(cx: 0.48, cy: 0.16, r: 0.16))
            ]

        // MARK: K
        case .key:
            return [
                .add(.circle(cx: -0.48, cy: 0.0, r: 0.46)),
                .subtract(.circle(cx: -0.48, cy: 0.0, r: 0.18)),
                .add(.rect(minX: -0.10, minY: -0.16, maxX: 0.92, maxY: 0.16)),
                .add(.rect(minX: 0.34, minY: -0.50, maxX: 0.56, maxY: -0.10)),
                .add(.rect(minX: 0.68, minY: -0.56, maxX: 0.92, maxY: -0.10))
            ]
        case .kite:
            return [
                .add(.polygon([(0.0, 0.94), (0.76, 0.20), (0.0, -0.78), (-0.76, 0.20)])),
                .add(.polygon([(0.0, -0.68), (-0.28, -0.96), (0.28, -0.96)]))
            ]

        // MARK: L
        case .leaf:
            return [
                .add(.ellipse(cx: 0.04, cy: 0.12, rx: 0.74, ry: 0.52, angleDeg: 42)),
                .add(.capsule(x1: -0.78, y1: -0.78, x2: -0.20, y2: -0.20, r: 0.14))
            ]
        case .lamp:
            return [
                .add(.polygon([(-0.46, 0.88), (0.46, 0.88), (0.86, 0.02), (-0.86, 0.02)])),
                .add(.rect(minX: -0.16, minY: -0.70, maxX: 0.16, maxY: 0.08)),
                .add(.rect(minX: -0.56, minY: -0.90, maxX: 0.56, maxY: -0.62))
            ]

        // MARK: M
        case .moon:
            return [
                .add(.circle(cx: -0.06, cy: 0.0, r: 0.88)),
                .subtract(.circle(cx: 0.42, cy: 0.20, r: 0.68))
            ]
        case .mushroom:
            return [
                .add(.ellipse(cx: 0.0, cy: 0.18, rx: 0.90, ry: 0.68)),
                .subtract(.rect(minX: -1.0, minY: -0.80, maxX: 1.0, maxY: -0.06)),
                .add(.rect(minX: -0.34, minY: -0.88, maxX: 0.34, maxY: 0.02))
            ]

        // MARK: N
        case .note:
            return [
                .add(.ellipse(cx: -0.28, cy: -0.54, rx: 0.42, ry: 0.32, angleDeg: 18)),
                .add(.rect(minX: -0.02, minY: -0.54, maxX: 0.28, maxY: 0.86)),
                .add(.polygon([(0.16, 0.88), (0.78, 0.42), (0.72, 0.06), (0.16, 0.44)]))
            ]
        case .necktie:
            return [
                .add(.polygon([(-0.42, 0.92), (0.42, 0.92), (0.20, 0.48), (-0.20, 0.48)])),
                .add(.polygon([(-0.20, 0.50), (0.20, 0.50), (0.48, -0.46), (0.0, -0.94), (-0.48, -0.46)]))
            ]

        // MARK: O
        case .owl:
            return [
                .add(.ellipse(cx: 0.0, cy: -0.08, rx: 0.72, ry: 0.82)),
                .add(.polygon([(-0.64, 0.40), (-0.70, 0.92), (-0.20, 0.62)])),
                .add(.polygon([(0.64, 0.40), (0.70, 0.92), (0.20, 0.62)])),
                .subtract(.circle(cx: -0.28, cy: 0.28, r: 0.16)),
                .subtract(.circle(cx: 0.28, cy: 0.28, r: 0.16))
            ]
        case .octagonRing:
            return [
                .add(.polygon([
                    (-0.42, 0.94), (0.42, 0.94), (0.94, 0.42), (0.94, -0.42),
                    (0.42, -0.94), (-0.42, -0.94), (-0.94, -0.42), (-0.94, 0.42)
                ])),
                .subtract(.polygon([
                    (-0.18, 0.42), (0.18, 0.42), (0.42, 0.18), (0.42, -0.18),
                    (0.18, -0.42), (-0.18, -0.42), (-0.42, -0.18), (-0.42, 0.18)
                ]))
            ]

        // MARK: P
        case .pineTree:
            return [
                .add(.polygon([(0.0, 0.94), (-0.78, -0.52), (0.78, -0.52)])),
                .add(.rect(minX: -0.24, minY: -0.92, maxX: 0.24, maxY: -0.48))
            ]
        case .pear:
            return [
                .add(.circle(cx: 0.0, cy: -0.32, r: 0.58)),
                .add(.ellipse(cx: 0.0, cy: 0.24, rx: 0.36, ry: 0.48)),
                .add(.capsule(x1: 0.0, y1: 0.64, x2: 0.14, y2: 0.92, r: 0.10))
            ]

        // MARK: Q
        case .queenCrown:
            return [
                .add(.rect(minX: -0.84, minY: -0.78, maxX: 0.84, maxY: -0.26)),
                .add(.polygon([
                    (-0.84, -0.28), (-0.92, 0.42), (-0.54, 0.02),
                    (-0.36, 0.64), (-0.16, 0.14), (0.0, 0.92),
                    (0.16, 0.14), (0.36, 0.64), (0.54, 0.02),
                    (0.92, 0.42), (0.84, -0.28)
                ]))
            ]
        case .quill:
            return [
                .add(.ellipse(cx: 0.18, cy: 0.20, rx: 0.82, ry: 0.34, angleDeg: 45)),
                .add(.capsule(x1: -0.84, y1: -0.84, x2: 0.44, y2: 0.44, r: 0.14)),
                .subtract(.polygon([(0.24, 0.62), (0.52, 0.34), (0.14, 0.34)]))
            ]

        // MARK: R
        case .rocket:
            return [
                .add(.ellipse(cx: 0.0, cy: 0.08, rx: 0.38, ry: 0.84)),
                .add(.polygon([(-0.34, -0.14), (-0.82, -0.76), (-0.28, -0.66)])),
                .add(.polygon([(0.34, -0.14), (0.82, -0.76), (0.28, -0.66)])),
                .add(.rect(minX: -0.24, minY: -0.88, maxX: 0.24, maxY: -0.56))
            ]
        case .ring:
            return [
                .add(.circle(cx: 0.0, cy: -0.22, r: 0.68)),
                .subtract(.circle(cx: 0.0, cy: -0.22, r: 0.34)),
                .add(.polygon([(0.0, 0.94), (0.38, 0.56), (0.0, 0.26), (-0.38, 0.56)]))
            ]

        // MARK: S
        case .star:
            var pts: [(Double, Double)] = []
            for i in 0..<10 {
                let angle = .pi / 2.0 + Double(i) * (.pi / 5.0)
                let r = i.isMultiple(of: 2) ? 0.96 : 0.46
                pts.append((cos(angle) * r, sin(angle) * r))
            }
            return [.add(.polygon(pts))]
        case .shield:
            return [
                .add(.polygon([
                    (-0.78, 0.82), (0.0, 0.94), (0.78, 0.82),
                    (0.78, -0.02), (0.46, -0.58), (0.0, -0.94),
                    (-0.46, -0.58), (-0.78, -0.02)
                ]))
            ]

        // MARK: T
        case .tulip:
            return [
                .add(.ellipse(cx: 0.0, cy: 0.26, rx: 0.54, ry: 0.50)),
                .add(.polygon([(-0.54, 0.28), (-0.54, 0.88), (-0.14, 0.56), (0.0, 0.92), (0.14, 0.56), (0.54, 0.88), (0.54, 0.28)])),
                .add(.rect(minX: -0.16, minY: -0.90, maxX: 0.16, maxY: -0.10)),
                .add(.ellipse(cx: -0.44, cy: -0.52, rx: 0.36, ry: 0.18, angleDeg: -32)),
                .add(.ellipse(cx: 0.44, cy: -0.52, rx: 0.36, ry: 0.18, angleDeg: 32))
            ]
        case .trophy:
            return [
                .add(.polygon([(-0.62, 0.86), (0.62, 0.86), (0.46, -0.10), (-0.46, -0.10)])),
                .add(.circle(cx: -0.62, cy: 0.46, r: 0.32)),
                .subtract(.circle(cx: -0.62, cy: 0.46, r: 0.14)),
                .add(.circle(cx: 0.62, cy: 0.46, r: 0.32)),
                .subtract(.circle(cx: 0.62, cy: 0.46, r: 0.14)),
                .add(.rect(minX: -0.18, minY: -0.66, maxX: 0.18, maxY: -0.04)),
                .add(.rect(minX: -0.54, minY: -0.90, maxX: 0.54, maxY: -0.60))
            ]

        // MARK: U
        case .umbrella:
            return [
                .add(.circle(cx: 0.0, cy: 0.02, r: 0.90)),
                .subtract(.rect(minX: -1.1, minY: -1.1, maxX: 1.1, maxY: 0.06)),
                .add(.rect(minX: -0.14, minY: -0.74, maxX: 0.14, maxY: 0.12)),
                .add(.capsule(x1: 0.0, y1: -0.74, x2: 0.36, y2: -0.74, r: 0.14)),
                .add(.capsule(x1: 0.36, y1: -0.74, x2: 0.36, y2: -0.52, r: 0.14))
            ]
        case .ufo:
            return [
                .add(.ellipse(cx: 0.0, cy: 0.28, rx: 0.48, ry: 0.44)),
                .add(.ellipse(cx: 0.0, cy: -0.12, rx: 0.94, ry: 0.34)),
                .add(.polygon([(-0.34, -0.38), (0.34, -0.38), (0.58, -0.84), (-0.58, -0.84)]))
            ]

        // MARK: V
        case .vase:
            return [
                .add(.ellipse(cx: 0.0, cy: -0.26, rx: 0.68, ry: 0.64)),
                .add(.rect(minX: -0.32, minY: 0.22, maxX: 0.32, maxY: 0.72)),
                .add(.polygon([(-0.56, 0.92), (0.56, 0.92), (0.36, 0.64), (-0.36, 0.64)]))
            ]
        case .volcano:
            return [
                .add(.polygon([(-0.92, -0.88), (0.92, -0.88), (0.38, 0.16), (-0.38, 0.16)])),
                .add(.circle(cx: 0.0, cy: 0.42, r: 0.32)),
                .add(.circle(cx: -0.30, cy: 0.60, r: 0.26)),
                .add(.circle(cx: 0.30, cy: 0.60, r: 0.26)),
                .add(.circle(cx: 0.0, cy: 0.72, r: 0.24))
            ]

        // MARK: W
        case .whale:
            return [
                .add(.ellipse(cx: -0.16, cy: -0.14, rx: 0.74, ry: 0.54)),
                .add(.capsule(x1: 0.38, y1: -0.22, x2: 0.76, y2: 0.22, r: 0.18)),
                .add(.polygon([(0.66, 0.18), (0.96, 0.56), (0.42, 0.46)])),
                .add(.capsule(x1: -0.22, y1: 0.32, x2: -0.22, y2: 0.76, r: 0.12)),
                .add(.circle(cx: -0.40, cy: 0.76, r: 0.14)),
                .add(.circle(cx: -0.04, cy: 0.76, r: 0.14))
            ]
        case .windmill:
            return [
                .add(.circle(cx: 0.0, cy: 0.0, r: 0.28)),
                .add(.polygon([(0.0, 0.0), (0.0, 0.92), (0.52, 0.48)])),
                .add(.polygon([(0.0, 0.0), (0.92, 0.0), (0.48, -0.52)])),
                .add(.polygon([(0.0, 0.0), (0.0, -0.92), (-0.52, -0.48)])),
                .add(.polygon([(0.0, 0.0), (-0.92, 0.0), (-0.48, 0.52)]))
            ]

        // MARK: X
        case .xCross:
            return [
                .add(.capsule(x1: -0.74, y1: -0.74, x2: 0.74, y2: 0.74, r: 0.26)),
                .add(.capsule(x1: -0.74, y1: 0.74, x2: 0.74, y2: -0.74, r: 0.26))
            ]
        case .cross:
            return [
                .add(.rect(minX: -0.34, minY: -0.92, maxX: 0.34, maxY: 0.92)),
                .add(.rect(minX: -0.92, minY: -0.34, maxX: 0.92, maxY: 0.34))
            ]

        // MARK: Y
        case .yacht:
            return [
                .add(.polygon([(-0.88, -0.36), (0.88, -0.36), (0.60, -0.86), (-0.60, -0.86)])),
                .add(.rect(minX: -0.10, minY: -0.40, maxX: 0.10, maxY: 0.88)),
                .add(.polygon([(0.06, 0.88), (0.78, -0.22), (0.06, -0.22)])),
                .add(.polygon([(-0.08, 0.64), (-0.66, -0.22), (-0.08, -0.22)]))
            ]
        case .ySlingshot:
            return [
                .add(.capsule(x1: 0.0, y1: -0.84, x2: 0.0, y2: 0.02, r: 0.22)),
                .add(.capsule(x1: 0.0, y1: 0.0, x2: -0.66, y2: 0.78, r: 0.20)),
                .add(.capsule(x1: 0.0, y1: 0.0, x2: 0.66, y2: 0.78, r: 0.20))
            ]

        // MARK: Z
        case .zap:
            return [
                .add(.polygon([
                    (0.36, 0.94), (-0.72, -0.06), (-0.06, -0.06),
                    (-0.36, -0.94), (0.72, 0.10), (0.06, 0.10)
                ]))
            ]
        case .zeppelin:
            return [
                .add(.ellipse(cx: -0.06, cy: 0.12, rx: 0.86, ry: 0.44)),
                .add(.polygon([(0.50, 0.34), (0.90, 0.72), (0.88, 0.22)])),
                .add(.polygon([(0.50, -0.10), (0.90, -0.48), (0.88, 0.02)])),
                .add(.rect(minX: -0.34, minY: -0.58, maxX: 0.22, maxY: -0.24))
            ]
        }
    }
}

/// Manages A–Z grouping and deterministic non-repeating random selection across all 52 silhouettes.
public enum SilhouetteCatalog {
    public static let alphabetOrder: [String] = (65...90).map { String(UnicodeScalar($0)!) }

    public static let variantsByLetter: [String: [SilhouetteID]] = {
        var map: [String: [SilhouetteID]] = [:]
        for id in SilhouetteID.allCases {
            map[id.letter, default: []].append(id)
        }
        return map
    }()

    /// Deterministically picks a random silhouette for the `occurrenceIndex`-th special board (0, 1, 2, ...):
    /// - Uses non-repeating shuffled bags of all 26 letters (never repeats consecutively or within 1 step).
    /// - Rotates through each letter's multiple word variants without back-to-back repeats across cycles!
    public static func silhouette(forSpecialOccurrence occurrenceIndex: Int) -> SilhouetteID {
        let idx = max(0, occurrenceIndex)
        let bagSize = alphabetOrder.count // 26 letters
        let bagIndex = idx / bagSize
        let posInBag = idx % bagSize

        let letterBag = shuffledLetterBag(bagIndex: bagIndex)
        let chosenLetter = letterBag[posInBag]
        let variants = variantsByLetter[chosenLetter] ?? [.heart]

        if variants.count == 1 {
            return variants[0]
        }

        // Deterministic per-letter variant permutation so cycle 0, 1, 2... visits all variants before repeating
        let letterHash = UInt64(chosenLetter.utf8.first ?? 65) &* 0x9E37_79B9_7F4A_7C15
        let startOffset = Int((letterHash >> 17) % UInt64(variants.count))
        let variantIdx = (startOffset + bagIndex) % variants.count
        return variants[variantIdx]
    }

    private static func shuffledLetterBag(bagIndex: Int) -> [String] {
        var prevLast: String?
        var prevSecondLast: String?
        var bag = alphabetOrder

        for b in 0...bagIndex {
            var state = UInt64(b + 1) &* 0x9E37_79B9_7F4A_7C15 ^ 0xA24B_AED4_963E_E407
            var candidate = alphabetOrder

            func nextRand() -> UInt64 {
                state &+= 0x9E37_79B9_7F4A_7C15
                var z = state
                z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                return z ^ (z >> 31)
            }

            for i in stride(from: candidate.count - 1, through: 1, by: -1) {
                let j = Int(nextRand() % UInt64(i + 1))
                candidate.swapAt(i, j)
            }

            if let last = prevLast, candidate[0] == last || candidate[0] == prevSecondLast {
                if let swapIdx = candidate.firstIndex(where: { $0 != last && $0 != prevSecondLast }) {
                    candidate.swapAt(0, swapIdx)
                }
            }
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

    /// Rasterizes a silhouette recipe onto a `width × height` grid, keeping the largest
    /// orthogonally-connected component so zero disconnected stray cells occur.
    public static func rasterize(
        _ id: SilhouetteID,
        width: Int,
        height: Int
    ) -> Set<GridPoint> {
        let ops = id.recipe
        var cells = Set<GridPoint>()
        cells.reserveCapacity(width * height)

        for x in 0..<width {
            let nx = width > 1 ? (Double(x) / Double(width - 1)) * 2.0 - 1.0 : 0.0
            for y in 0..<height {
                let ny = height > 1 ? (Double(y) / Double(height - 1)) * 2.0 - 1.0 : 0.0
                var inside = false
                for op in ops {
                    switch op {
                    case .add(let prim):
                        if !inside && prim.contains(x: nx, y: ny) {
                            inside = true
                        }
                    case .subtract(let prim):
                        if inside && prim.contains(x: nx, y: ny) {
                            inside = false
                        }
                    }
                }
                if inside {
                    cells.insert(GridPoint(x: x, y: y))
                }
            }
        }

        return largestConnectedComponent(in: cells, width: width, height: height)
    }

    private static func largestConnectedComponent(
        in cells: Set<GridPoint>,
        width: Int,
        height: Int
    ) -> Set<GridPoint> {
        guard !cells.isEmpty else {
            var full = Set<GridPoint>()
            for x in 0..<width {
                for y in 0..<height {
                    full.insert(GridPoint(x: x, y: y))
                }
            }
            return full
        }

        var visited = Set<GridPoint>()
        var best = Set<GridPoint>()
        for start in cells where !visited.contains(start) {
            var component = Set<GridPoint>()
            var queue: [GridPoint] = [start]
            visited.insert(start)
            var head = 0
            while head < queue.count {
                let curr = queue[head]
                head += 1
                component.insert(curr)
                for dir in Direction.allCases {
                    let nxt = curr.moved(by: dir)
                    if cells.contains(nxt) && !visited.contains(nxt) {
                        visited.insert(nxt)
                        queue.append(nxt)
                    }
                }
            }
            if component.count > best.count {
                best = component
            }
        }
        return best
    }
}
