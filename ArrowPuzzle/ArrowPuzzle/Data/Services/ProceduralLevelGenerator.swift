import Foundation

/// Deterministic SplitMix64 PRNG for reproducible level layouts.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) * (1.0 / Double(1 << 53))
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }
}

/// Generates 100% solvable, full-coverage, concept-driven puzzles via a 3-stage
/// **Partition-then-DAG-Orient** architecture:
///
/// - **Stage A (Concept-Driven 100% Partition)**: Tiles the entire active silhouette with
///   undirected self-avoiding paths — starting with dramatic concept heroes (coiled spirals,
///   serpentine ribbons, concentric fortresses, or hooked knots) and Warnsdorff-filling every
///   remaining corridor so no dead pockets remain inside enclosing shapes.
/// - **Stage B (Peeling-Driven DAG Orientation & Local Cycle Resolution)**: Peels paths from
///   outside-in, assigning each path an exit orientation that preferentially crosses recently-peeled
///   cells (creating deep multi-wave dependency chains and tiny initial openings). Any local cycle
///   is cleanly broken via minimal splitting while keeping 100% coverage.
/// - **Stage C (Tandem Merge & Meaningfulness Cleanup)**: Merges or removes any redundant
///   same-direction 1-cell tandems (`──→ →` → `───→`) while preserving 100% solvability.
public struct ProceduralLevelGenerator: LevelGeneratorProtocol, Sendable {
    private let solver: PuzzleSolver

    public init(solver: PuzzleSolver = PuzzleSolver()) {
        self.solver = solver
    }

    public func generateBoard(config: LevelConfig) -> PuzzleBoard {
        let attempts = max(1, config.candidateAttempts)
        var bestBoard: PuzzleBoard?
        var bestQuality = -Double.infinity

        for attempt in 0..<attempts {
            let attemptSeed = config.seed &+ UInt64(attempt) &* 0x517C_C1B7_2722_0A95
            let candidate = buildSingleCandidate(config: config, seed: attemptSeed)
            let quality = evaluateQuality(candidate, config: config)
            if quality > bestQuality {
                bestQuality = quality
                bestBoard = candidate
            }
        }

        return bestBoard ?? buildSingleCandidate(config: config, seed: config.seed)
    }

    private func buildSingleCandidate(config: LevelConfig, seed: UInt64) -> PuzzleBoard {
        var rng = SplitMix64(seed: seed)
        let width = config.width
        let height = config.height
        let gridCount = width * height
        let activeCells = config.shape.activeCells(width: width, height: height)
        let totalActiveCells = max(1, activeCells.count)

        var activeGrid = Array(repeating: false, count: gridCount)
        var boundaryExposure = Array(repeating: 0, count: gridCount)
        for p in activeCells {
            activeGrid[p.y * width + p.x] = true
        }
        for p in activeCells {
            var exp = 0
            for dir in Direction.allCases {
                let nx = p.x + dir.dx
                let ny = p.y + dir.dy
                if nx < 0 || nx >= width || ny < 0 || ny >= height || !activeGrid[ny * width + nx] {
                    exp += 1
                }
            }
            boundaryExposure[p.y * width + p.x] = exp
        }

        @inline(__always)
        func toPoint(_ index: Int) -> GridPoint {
            GridPoint(x: index % width, y: index / width)
        }

        @inline(__always)
        func stepIndex(from cellIdx: Int, by dir: Direction) -> Int? {
            let nx = (cellIdx % width) + dir.dx
            let ny = (cellIdx / width) + dir.dy
            guard nx >= 0 && nx < width && ny >= 0 && ny < height else { return nil }
            return ny * width + nx
        }

        @inline(__always)
        func directionBetween(_ fromIdx: Int, _ toIdx: Int) -> Direction? {
            let dx = (toIdx % width) - (fromIdx % width)
            let dy = (toIdx / width) - (fromIdx / width)
            switch (dx, dy) {
            case (0, 1): return .up
            case (0, -1): return .down
            case (1, 0): return .right
            case (-1, 0): return .left
            default: return nil
            }
        }

        // Zero-allocation reusable stamp array for fast O(length) self-clearance checks up to 100×100
        var selfStampGrid = Array(repeating: 0, count: gridCount)
        var currentSelfStamp = 0

        /// Checks if casting a ray from `headIdx` along `dir` avoids every cell marked with `stamp`.
        func isRaySelfClear(from headIdx: Int, direction dir: Direction, stamp: Int) -> Bool {
            var cx = (headIdx % width) + dir.dx
            var cy = (headIdx / width) + dir.dy
            while cx >= 0 && cx < width && cy >= 0 && cy < height {
                if selfStampGrid[cy * width + cx] == stamp {
                    return false
                }
                cx += dir.dx
                cy += dir.dy
            }
            return true
        }

        /// Returns true iff at least one endpoint of `cells` (plus optional `extraCell`) can exit without hitting itself.
        func hasSelfClearEnd(_ cells: [Int], appending extraCell: Int? = nil) -> Bool {
            let totalCount = cells.count + (extraCell == nil ? 0 : 1)
            guard totalCount >= 2 else { return true }

            currentSelfStamp += 1
            let stamp = currentSelfStamp
            for c in cells { selfStampGrid[c] = stamp }
            if let extra = extraCell { selfStampGrid[extra] = stamp }

            let lastCell = extraCell ?? cells[cells.count - 1]
            let prevLast = extraCell != nil ? cells[cells.count - 1] : cells[cells.count - 2]
            if let fwdDir = directionBetween(prevLast, lastCell),
               isRaySelfClear(from: lastCell, direction: fwdDir, stamp: stamp) {
                return true
            }

            let firstCell = cells[0]
            let secondCell = cells.count >= 2 ? cells[1] : lastCell
            if let bwdDir = directionBetween(secondCell, firstCell),
               isRaySelfClear(from: firstCell, direction: bwdDir, stamp: stamp) {
                return true
            }
            return false
        }

        // =====================================================================
        // STAGE A: Concept-Driven 100% Grid Partitioning (Undirected Paths)
        // =====================================================================

        var assignedGrid = Array(repeating: false, count: gridCount)
        var assignedCount = 0
        var partitionedPaths: [[Int]] = []
        let maxMergedLength = min(28, max(14, config.maxArrowLength * 2 + 4))

        func freeDegree(of cellIdx: Int) -> Int {
            var deg = 0
            for dir in Direction.allCases {
                if let nxt = stepIndex(from: cellIdx, by: dir), activeGrid[nxt], !assignedGrid[nxt] {
                    deg += 1
                }
            }
            return deg
        }

        func selfNeighborCount(_ cellIdx: Int, in set: Set<Int>) -> Int {
            var c = 0
            for dir in Direction.allCases {
                if let nxt = stepIndex(from: cellIdx, by: dir), set.contains(nxt) {
                    c += 1
                }
            }
            return c
        }

        func commitPartitionPath(_ cells: [Int]) {
            for c in cells {
                assignedGrid[c] = true
            }
            assignedCount += cells.count
            partitionedPaths.append(cells)
        }

        func pickHeroStart(preferRim: Bool, preferCenter: Bool) -> Int? {
            let cx = Double(width - 1) / 2.0
            let cy = Double(height - 1) / 2.0
            var candidates: [(cell: Int, score: Double)] = []
            candidates.reserveCapacity(totalActiveCells)

            for ci in 0..<gridCount where activeGrid[ci] && !assignedGrid[ci] {
                guard freeDegree(of: ci) >= 1 else { continue }
                let dist = abs(Double(ci % width) - cx) + abs(Double(ci / width) - cy)
                var s = rng.nextDouble() * 2.5
                if preferRim {
                    s += Double(boundaryExposure[ci]) * 4.0 + dist * 0.65
                } else if preferCenter {
                    s -= dist * 0.85
                }
                candidates.append((ci, s))
            }
            guard !candidates.isEmpty else { return nil }
            candidates.sort { $0.score > $1.score }
            let pool = min(candidates.count, 6)
            return candidates[rng.nextInt(in: 0...(pool - 1))].cell
        }

        /// Spiral hero: coils inward with a 1-cell corridor between windings (which Stage A2 fills 100%!).
        func partitionSpiralHero(targetLen: Int, clockwise: Bool) {
            guard let start = pickHeroStart(preferRim: true, preferCenter: false) else { return }
            var cells = [start]
            var body: Set<Int> = [start]

            // Pick an initial direction hugging the rim or moving inward cleanly
            let initialDirs = Direction.allCases.filter { dir in
                if let n = stepIndex(from: start, by: dir), activeGrid[n], !assignedGrid[n] { return true }
                return false
            }
            guard !initialDirs.isEmpty else { return }
            var moveDir = initialDirs[rng.nextInt(in: 0...(initialDirs.count - 1))]

            func spin(_ d: Direction) -> Direction {
                clockwise ? d.turnedClockwise : d.turnedCounterClockwise
            }

            while cells.count < targetLen {
                let curr = cells[cells.count - 1]
                let turnDir = spin(moveDir)
                let altDir = clockwise ? moveDir.turnedCounterClockwise : moveDir.turnedClockwise

                var chosen: (cell: Int, dir: Direction)?

                if let ahead = stepIndex(from: curr, by: moveDir),
                   activeGrid[ahead], !assignedGrid[ahead], !body.contains(ahead),
                   selfNeighborCount(ahead, in: body) == 1 {
                    let twoAheadIsSelf: Bool
                    if let ahead2 = stepIndex(from: ahead, by: moveDir) {
                        twoAheadIsSelf = body.contains(ahead2)
                    } else {
                        twoAheadIsSelf = false
                    }
                    if !twoAheadIsSelf && hasSelfClearEnd(cells, appending: ahead) {
                        chosen = (ahead, moveDir)
                    }
                }

                if chosen == nil,
                   let turned = stepIndex(from: curr, by: turnDir),
                   activeGrid[turned], !assignedGrid[turned], !body.contains(turned),
                   selfNeighborCount(turned, in: body) == 1,
                   hasSelfClearEnd(cells, appending: turned) {
                    chosen = (turned, turnDir)
                }

                if chosen == nil {
                    for fb in [turnDir, moveDir, altDir] {
                        if let nxt = stepIndex(from: curr, by: fb),
                           activeGrid[nxt], !assignedGrid[nxt], !body.contains(nxt),
                           selfNeighborCount(nxt, in: body) <= 2,
                           hasSelfClearEnd(cells, appending: nxt) {
                            chosen = (nxt, fb)
                            break
                        }
                    }
                }

                guard let step = chosen else { break }
                cells.append(step.cell)
                body.insert(step.cell)
                moveDir = step.dir
            }

            if cells.count >= 8 {
                commitPartitionPath(cells)
            }
        }

        /// Serpentine hero: winds in dramatic S / ㄹ switchbacks across the board.
        func partitionSerpentineHero(targetLen: Int) {
            guard let start = pickHeroStart(preferRim: false, preferCenter: true) else { return }
            var cells = [start]
            var body: Set<Int> = [start]

            let initialDirs = Direction.allCases.filter { dir in
                if let n = stepIndex(from: start, by: dir), activeGrid[n], !assignedGrid[n] { return true }
                return false
            }
            guard !initialDirs.isEmpty else { return }
            var moveDir = initialDirs[rng.nextInt(in: 0...(initialDirs.count - 1))]
            var turnCW = rng.nextDouble() < 0.5
            var run = 0
            var targetRun = rng.nextInt(in: 2...3)

            while cells.count < targetLen {
                let curr = cells[cells.count - 1]
                let prefTurn = turnCW ? moveDir.turnedClockwise : moveDir.turnedCounterClockwise
                let otherTurn = turnCW ? moveDir.turnedCounterClockwise : moveDir.turnedClockwise
                let order = run >= targetRun ? [prefTurn, otherTurn, moveDir] : [moveDir, prefTurn, otherTurn]

                var chosen: (cell: Int, dir: Direction)?
                for d in order {
                    if let nxt = stepIndex(from: curr, by: d),
                       activeGrid[nxt], !assignedGrid[nxt], !body.contains(nxt),
                       selfNeighborCount(nxt, in: body) == 1,
                       hasSelfClearEnd(cells + [nxt]) {
                        chosen = (nxt, d)
                        break
                    }
                }
                guard let step = chosen else { break }
                if step.dir != moveDir {
                    turnCW.toggle()
                    run = 1
                    targetRun = rng.nextInt(in: 2...4)
                } else {
                    run += 1
                }
                cells.append(step.cell)
                body.insert(step.cell)
                moveDir = step.dir
            }

            if cells.count >= 7 {
                commitPartitionPath(cells)
            }
        }

        /// Concentric fortress hero: hugs outer and inner perimeter walls in long L/U/C frames.
        func partitionFortressHero(targetLen: Int) {
            guard let start = pickHeroStart(preferRim: true, preferCenter: false) else { return }
            var cells = [start]
            var body: Set<Int> = [start]
            var moveDir: Direction?

            while cells.count < targetLen {
                let curr = cells[cells.count - 1]
                var best: (cell: Int, dir: Direction, score: Double)?
                for d in Direction.allCases {
                    guard let nxt = stepIndex(from: curr, by: d),
                          activeGrid[nxt], !assignedGrid[nxt], !body.contains(nxt),
                          selfNeighborCount(nxt, in: body) == 1,
                          hasSelfClearEnd(cells + [nxt]) else {
                        continue
                    }
                    var score = Double(boundaryExposure[nxt]) * 4.5 + rng.nextDouble()
                    for adjDir in Direction.allCases {
                        if let adj = stepIndex(from: nxt, by: adjDir), assignedGrid[adj] {
                            score += 3.0
                        }
                    }
                    if d == moveDir { score += 3.0 }
                    if best == nil || score > best!.score {
                        best = (nxt, d, score)
                    }
                }
                guard let step = best else { break }
                cells.append(step.cell)
                body.insert(step.cell)
                moveDir = step.dir
            }

            if cells.count >= 7 {
                commitPartitionPath(cells)
            }
        }

        /// Hooked knot hero: tightly curled U/G hooks weaving around each other.
        func partitionHookHero(targetLen: Int, clockwise: Bool) {
            guard let start = pickHeroStart(preferRim: false, preferCenter: true) else { return }
            var cells = [start]
            var body: Set<Int> = [start]

            let initialDirs = Direction.allCases.filter { dir in
                if let n = stepIndex(from: start, by: dir), activeGrid[n], !assignedGrid[n] { return true }
                return false
            }
            guard !initialDirs.isEmpty else { return }
            var moveDir = initialDirs[rng.nextInt(in: 0...(initialDirs.count - 1))]
            var run = 0
            var leg = rng.nextInt(in: 2...3)

            while cells.count < targetLen {
                let curr = cells[cells.count - 1]
                let curlDir = clockwise ? moveDir.turnedClockwise : moveDir.turnedCounterClockwise
                let otherDir = clockwise ? moveDir.turnedCounterClockwise : moveDir.turnedClockwise
                let order = run >= leg ? [curlDir, moveDir, otherDir] : [moveDir, curlDir, otherDir]

                var chosen: (cell: Int, dir: Direction)?
                for d in order {
                    if let nxt = stepIndex(from: curr, by: d),
                       activeGrid[nxt], !assignedGrid[nxt], !body.contains(nxt),
                       selfNeighborCount(nxt, in: body) == 1,
                       hasSelfClearEnd(cells + [nxt]) {
                        chosen = (nxt, d)
                        break
                    }
                }
                guard let step = chosen else { break }
                if step.dir != moveDir {
                    run = 1
                    leg = rng.nextInt(in: 2...3)
                } else {
                    run += 1
                }
                cells.append(step.cell)
                body.insert(step.cell)
                moveDir = step.dir
            }

            if cells.count >= 6 {
                commitPartitionPath(cells)
            }
        }

        // Step A1: Place Concept Heroes scaled up to 100×100 silhouettes
        let scale = min(width, height)
        switch config.concept {
        case .spiralVortex:
            let count = scale >= 65 ? 6 : (scale >= 36 ? 4 : (scale >= 24 ? 3 : (scale >= 15 ? 2 : 1)))
            let len = min(64, max(12, scale * 2 - 2))
            for i in 0..<count {
                partitionSpiralHero(targetLen: len, clockwise: i.isMultiple(of: 2))
            }
        case .serpentineMaze:
            let count = scale >= 65 ? 9 : (scale >= 36 ? 6 : (scale >= 24 ? 4 : (scale >= 15 ? 3 : 2)))
            let len = min(54, max(10, scale + 4))
            for _ in 0..<count {
                partitionSerpentineHero(targetLen: len)
            }
        case .concentricFortress:
            let count = scale >= 65 ? 9 : (scale >= 36 ? 6 : (scale >= 24 ? 5 : (scale >= 15 ? 4 : 3)))
            let len = min(56, max(9, scale + 4))
            for _ in 0..<count {
                partitionFortressHero(targetLen: len)
            }
        case .hookedKnots:
            let count = scale >= 65 ? 12 : (scale >= 36 ? 8 : (scale >= 24 ? 6 : (scale >= 15 ? 5 : 3)))
            let len = min(28, max(8, scale - 1))
            for i in 0..<count {
                partitionHookHero(targetLen: len, clockwise: i.isMultiple(of: 2))
            }
        case .denseLabyrinth:
            let count = scale >= 65 ? 6 : (scale >= 36 ? 4 : (scale >= 24 ? 3 : (scale >= 14 ? 2 : 1)))
            for _ in 0..<count {
                partitionSerpentineHero(targetLen: min(28, max(8, scale - 1)))
            }
        }

        // Step A2: Warnsdorff 100% Space-Filling Partition of all remaining cells
        while assignedCount < totalActiveCells {
            // Pick unassigned cell with lowest free degree (enters spiral corridors & tight corners first!)
            var bestStart = -1
            var bestDeg = Int.max
            var tieScore = -Double.infinity

            for ci in 0..<gridCount where activeGrid[ci] && !assignedGrid[ci] {
                let d = freeDegree(of: ci)
                let score = Double(boundaryExposure[ci]) * 0.5 + rng.nextDouble()
                if d < bestDeg || (d == bestDeg && score > tieScore) {
                    bestDeg = d
                    tieScore = score
                    bestStart = ci
                }
            }
            guard bestStart >= 0 else { break }

            let effectiveMax = rng.nextDouble() < 0.20 ? min(config.maxArrowLength + 3, scale) : config.maxArrowLength
            let targetLen = rng.nextInt(in: config.minArrowLength...max(config.minArrowLength, effectiveMax))

            var cells = [bestStart]
            var body: Set<Int> = [bestStart]
            var lastDir: Direction?

            while cells.count < targetLen {
                let curr = cells[cells.count - 1]
                var neighbors: [(cell: Int, dir: Direction, score: Double)] = []

                for d in Direction.allCases {
                    guard let nxt = stepIndex(from: curr, by: d),
                          activeGrid[nxt], !assignedGrid[nxt], !body.contains(nxt) else {
                        continue
                    }
                    guard hasSelfClearEnd(cells, appending: nxt) else { continue }

                    // Warnsdorff: strongly prefer stepping into low-degree cells so we never strand 1-cell holes!
                    let nxtFreeDeg = freeDegree(of: nxt) - 1 // excluding curr
                    var s = Double(4 - max(0, nxtFreeDeg)) * 3.8 + rng.nextDouble() * 1.4
                    if let prevD = lastDir {
                        if d != prevD {
                            s += (rng.nextDouble() < config.preferredTurnProbability) ? 2.4 : -0.2
                        } else {
                            s += 0.4
                        }
                    }
                    // Penalize leaving behind an unvisited neighbor of degree 0 (stranded 1-cell hole)
                    if nxtFreeDeg == 0 && cells.count + 1 < targetLen {
                        s += 1.5 // actually absorb dead-end cell cleanly!
                    }
                    neighbors.append((nxt, d, s))
                }

                guard !neighbors.isEmpty else { break }
                neighbors.sort { $0.score > $1.score }
                let pickIdx = (neighbors.count > 1 && rng.nextDouble() < 0.18) ? 1 : 0
                let chosen = neighbors[pickIdx]
                cells.append(chosen.cell)
                body.insert(chosen.cell)
                lastDir = chosen.dir
            }

            commitPartitionPath(cells)
        }

        // Step A3: Absorb any stranded 1-cell partition seeds into adjacent path endpoints
        var mergedSeed = true
        while mergedSeed {
            mergedSeed = false
            var seedIdx = 0
            while seedIdx < partitionedPaths.count {
                guard partitionedPaths[seedIdx].count == 1 else {
                    seedIdx += 1
                    continue
                }
                let cell = partitionedPaths[seedIdx][0]
                var absorbed = false

                for targetIdx in 0..<partitionedPaths.count where targetIdx != seedIdx {
                    let target = partitionedPaths[targetIdx]
                    guard target.count < maxMergedLength else { continue }

                    if let first = target.first, directionBetween(cell, first) != nil {
                        let extended = [cell] + target
                        if hasSelfClearEnd(extended) {
                            partitionedPaths[targetIdx] = extended
                            partitionedPaths.remove(at: seedIdx)
                            absorbed = true
                            mergedSeed = true
                            break
                        }
                    }
                    if let last = target.last, directionBetween(last, cell) != nil {
                        let extended = target + [cell]
                        if hasSelfClearEnd(extended) {
                            partitionedPaths[targetIdx] = extended
                            partitionedPaths.remove(at: seedIdx)
                            absorbed = true
                            mergedSeed = true
                            break
                        }
                    }
                }

                if !absorbed {
                    seedIdx += 1
                }
            }
        }

        // =====================================================================
        // STAGE B: Peeling-Driven DAG Orientation + Local Cycle Resolution
        // =====================================================================

        var remainingPaths = partitionedPaths
        var remainingOccupied = Array(repeating: false, count: gridCount)
        for path in remainingPaths {
            for c in path { remainingOccupied[c] = true }
        }

        // Tracks at which peeling step each cell left the board (0 = not yet peeled).
        // Orienting remaining paths to shoot through recently-peeled cells maximizes wave depth!
        var peeledStepAtCell = Array(repeating: 0, count: gridCount)
        var committedArrows: [(cells: [Int], direction: Direction)] = []
        committedArrows.reserveCapacity(remainingPaths.count + 8)

        func rayAgainstRemaining(from headIdx: Int, direction dir: Direction) -> (isClear: Bool, latestPeeledStep: Int, peeledHits: Int) {
            var cx = (headIdx % width) + dir.dx
            var cy = (headIdx / width) + dir.dy
            var latest = 0
            var hits = 0
            while cx >= 0 && cx < width && cy >= 0 && cy < height {
                let ci = cy * width + cx
                if remainingOccupied[ci] {
                    return (false, 0, 0)
                }
                let pStep = peeledStepAtCell[ci]
                if pStep > 0 {
                    hits += 1
                    if pStep > latest { latest = pStep }
                }
                cx += dir.dx
                cy += dir.dy
            }
            return (true, latest, hits)
        }

        func validOrientations(for path: [Int]) -> [(cells: [Int], dir: Direction, latestStep: Int, peeledHits: Int)] {
            var results: [(cells: [Int], dir: Direction, latestStep: Int, peeledHits: Int)] = []
            if path.count == 1 {
                let c = path[0]
                for dir in Direction.allCases {
                    let ray = rayAgainstRemaining(from: c, direction: dir)
                    if ray.isClear {
                        results.append(([c], dir, ray.latestPeeledStep, ray.peeledHits))
                    }
                }
            } else {
                if let fwdDir = directionBetween(path[path.count - 2], path[path.count - 1]) {
                    let ray = rayAgainstRemaining(from: path[path.count - 1], direction: fwdDir)
                    if ray.isClear {
                        results.append((path, fwdDir, ray.latestPeeledStep, ray.peeledHits))
                    }
                }
                if let bwdDir = directionBetween(path[1], path[0]) {
                    let ray = rayAgainstRemaining(from: path[0], direction: bwdDir)
                    if ray.isClear {
                        results.append((Array(path.reversed()), bwdDir, ray.latestPeeledStep, ray.peeledHits))
                    }
                }
            }
            return results
        }

        var peelStep = 0
        while !remainingPaths.isEmpty {
            peelStep += 1

            struct PeelChoice {
                let pathIndex: Int
                let cells: [Int]
                let dir: Direction
                let score: Double
            }

            var choices: [PeelChoice] = []
            for pIdx in 0..<remainingPaths.count {
                let path = remainingPaths[pIdx]
                let orients = validOrientations(for: path)
                for o in orients {
                    var score = rng.nextDouble() * 2.0
                    if o.latestStep > 0 {
                        // Strongly prefer paths that were LOCKED by recently peeled arrows -> deep chains!
                        score += Double(o.latestStep) * 16.0 + Double(o.peeledHits) * 4.5
                    } else if peelStep > 1 {
                        // Strongly penalize peeling a Turn-1 free arrow when chained arrows are available!
                        score -= 35.0
                    }

                    // Prefer peeling shorter/medium keys early so giant Hero spirals/ribbons pay off later!
                    if path.count >= 10 && peelStep <= max(2, remainingPaths.count / 3) {
                        score -= 8.0
                    }
                    // Prefer keeping multi-cell paths intact over peeling 1-cell pieces unless needed
                    if path.count == 1 {
                        score -= 4.0
                    }

                    choices.append(PeelChoice(pathIndex: pIdx, cells: o.cells, dir: o.dir, score: score))
                }
            }

            if !choices.isEmpty {
                choices.sort { $0.score > $1.score }
                // Monotonic mini-batch peeling on giant boards (remaining > 120):
                // peeling multiple already-clear paths in one scan preserves 100% solvability
                // while accelerating 100×100 generation by 5×–8×.
                let batchLimit = remainingPaths.count > 220 ? 8 : (remainingPaths.count > 120 ? 4 : 1)
                var removedPathIndices: [Int] = []
                removedPathIndices.reserveCapacity(batchLimit)

                if batchLimit == 1 {
                    let pool = min(choices.count, 3)
                    let pick = choices[rng.nextInt(in: 0...(pool - 1))]
                    for c in pick.cells {
                        remainingOccupied[c] = false
                        peeledStepAtCell[c] = peelStep
                    }
                    committedArrows.append((pick.cells, pick.dir))
                    removedPathIndices.append(pick.pathIndex)
                } else {
                    var pickedPaths = Set<Int>()
                    for choice in choices {
                        guard pickedPaths.count < batchLimit else { break }
                        guard !pickedPaths.contains(choice.pathIndex) else { continue }
                        pickedPaths.insert(choice.pathIndex)
                        for c in choice.cells {
                            remainingOccupied[c] = false
                            peeledStepAtCell[c] = peelStep
                        }
                        committedArrows.append((choice.cells, choice.dir))
                        removedPathIndices.append(choice.pathIndex)
                    }
                }

                for idxToRemove in removedPathIndices.sorted(by: >) {
                    remainingPaths.remove(at: idxToRemove)
                }
                continue
            }

            // DEADLOCK CYCLE RESOLUTION: No remaining path can escape yet — make ONE minimal clean split!
            var resolved = false

            // Strategy 1: Clean multi-cell split (both halves >= 2 cells) where one half can immediately peel
            var bestSplit: (pIdx: Int, left: [Int], right: [Int], score: Double)?
            for pIdx in 0..<remainingPaths.count {
                let path = remainingPaths[pIdx]
                guard path.count >= 4 else { continue }
                for s in 2...(path.count - 2) {
                    let left = Array(path[0..<s])
                    let right = Array(path[s..<path.count])
                    let leftOrients = validOrientations(for: left)
                    let rightOrients = validOrientations(for: right)
                    if !leftOrients.isEmpty || !rightOrients.isEmpty {
                        let bestLatest = max(
                            leftOrients.map(\.latestStep).max() ?? 0,
                            rightOrients.map(\.latestStep).max() ?? 0
                        )
                        let balanceBonus = Double(min(left.count, right.count)) * 3.0
                        let sc = Double(bestLatest) * 10.0 + balanceBonus + rng.nextDouble()
                        if bestSplit == nil || sc > bestSplit!.score {
                            bestSplit = (pIdx, left, right, sc)
                        }
                    }
                }
            }

            if let split = bestSplit {
                remainingPaths[split.pIdx] = split.left
                remainingPaths.append(split.right)
                resolved = true
            }

            // Strategy 2: Asymmetric split (1 + (n-1)) on length >= 3 paths exposing a clear exit ray
            if !resolved {
                outerLoop: for pIdx in 0..<remainingPaths.count {
                    let path = remainingPaths[pIdx]
                    guard path.count >= 3 else { continue }
                    for s in [1, path.count - 1] {
                        let left = Array(path[0..<s])
                        let right = Array(path[s..<path.count])
                        if !validOrientations(for: left).isEmpty || !validOrientations(for: right).isEmpty {
                            remainingPaths[pIdx] = left
                            remainingPaths.append(right)
                            resolved = true
                            break outerLoop
                        }
                    }
                }
            }

            // Strategy 3 (Guaranteed mathematical termination): Release one hull cell with a clear ray
            if !resolved {
                hullSearch: for pIdx in 0..<remainingPaths.count {
                    let path = remainingPaths[pIdx]
                    for pos in 0..<path.count {
                        let cell = path[pos]
                        for dir in Direction.allCases {
                            if rayAgainstRemaining(from: cell, direction: dir).isClear {
                                remainingOccupied[cell] = false
                                peeledStepAtCell[cell] = peelStep
                                committedArrows.append(([cell], dir))

                                let prefix = Array(path[0..<pos])
                                let suffix = Array(path[(pos + 1)..<path.count])
                                remainingPaths.remove(at: pIdx)
                                if !prefix.isEmpty { remainingPaths.append(prefix) }
                                if !suffix.isEmpty { remainingPaths.append(suffix) }
                                resolved = true
                                break hullSearch
                            }
                        }
                    }
                }
            }

            if !resolved { break }
        }

        // =====================================================================
        // STAGE C: Tandem Merge & Meaningless 1-Cell Cleanup
        // =====================================================================

        var arrows = committedArrows.enumerated().map { idx, item in
            Arrow(
                id: deterministicUUID(seed: UInt64(idx + 1) &* 0x9E37_79B9_7F4A_7C15 ^ rng.next()),
                cells: item.cells.map(toPoint),
                headDirection: item.direction
            )
        }

        arrows = cleanupSingleCellTandems(
            arrows: arrows,
            width: width,
            height: height,
            shape: config.shape,
            activeCells: activeCells,
            boundaryExposure: boundaryExposure
        )

        let subtitle = buildSubtitle(config: config)

        return PuzzleBoard(
            levelNumber: config.levelNumber,
            width: width,
            height: height,
            arrows: arrows,
            shape: config.shape,
            concept: config.concept,
            activeCells: activeCells,
            subtitle: subtitle,
            isHandcrafted: false,
            isHardChallenge: config.isHardChallenge
        )
    }

    /// Eliminates redundant same-direction 1-cell tandems (`──→ →` → `───→`) by safely merging
    /// into the arrow behind it, re-orienting orthogonally, or dropping meaningless 1-cell fillers.
    private func cleanupSingleCellTandems(
        arrows initialArrows: [Arrow],
        width: Int,
        height: Int,
        shape: BoardShape,
        activeCells: Set<GridPoint>,
        boundaryExposure: [Int]
    ) -> [Arrow] {
        var arrows = initialArrows

        func makeBoard(_ list: [Arrow]) -> PuzzleBoard {
            PuzzleBoard(
                levelNumber: 0,
                width: width,
                height: height,
                arrows: list,
                shape: shape,
                activeCells: activeCells
            )
        }

        var changed = true
        while changed {
            changed = false
            let occ = makeBoard(arrows).occupancyMap()
            let indexByID = Dictionary(uniqueKeysWithValues: arrows.enumerated().map { ($0.element.id, $0.offset) })

            for i in 0..<arrows.count where arrows[i].isSingleCell {
                let single = arrows[i]
                let cell = single.head
                let rearCell = cell.moved(by: single.headDirection.opposite)

                // Check if an arrow directly behind it points in the exact same direction
                let hasSameDirBehind: Bool
                var directRearHeadIdx: Int?
                if let rearID = occ[rearCell], let rIdx = indexByID[rearID] {
                    let rearArrow = arrows[rIdx]
                    hasSameDirBehind = (rearArrow.headDirection == single.headDirection)
                    if rearArrow.head == rearCell && rearArrow.headDirection == single.headDirection {
                        directRearHeadIdx = rIdx
                    }
                } else {
                    hasSameDirBehind = false
                }

                // 1) Try merging `──→ →` into a single seamless `───→` arrow!
                if let rIdx = directRearHeadIdx {
                    var candidate = arrows
                    let merged = Arrow(
                        id: arrows[rIdx].id,
                        cells: arrows[rIdx].cells + [cell],
                        headDirection: arrows[rIdx].headDirection
                    )
                    candidate[rIdx] = merged
                    candidate.remove(at: i)
                    if solver.isSolvable(makeBoard(candidate)) {
                        arrows = candidate
                        changed = true
                        break
                    }
                }

                // 2) Check if this 1-cell arrow is tandem or meaningless (blocks zero non-parallel arrows)
                let blocksNonParallel = arrows.contains { other in
                    guard other.id != single.id, other.headDirection != single.headDirection else { return false }
                    var cursor = other.head.moved(by: other.headDirection)
                    while cursor.x >= 0 && cursor.x < width && cursor.y >= 0 && cursor.y < height {
                        if cursor == cell { return true }
                        cursor = cursor.moved(by: other.headDirection)
                    }
                    return false
                }
                let isCriticalShapeTip = (shape != .rectangle) && (boundaryExposure[cell.y * width + cell.x] >= 2)

                if hasSameDirBehind || (!blocksNonParallel && !isCriticalShapeTip) {
                    // Try re-orienting to a clean non-tandem direction that keeps solvability
                    var reoriented = false
                    for altDir in Direction.allCases where altDir != single.headDirection {
                        let altRear = cell.moved(by: altDir.opposite)
                        if let rid = occ[altRear], let rIdx = indexByID[rid], arrows[rIdx].headDirection == altDir {
                            continue
                        }
                        var candidate = arrows
                        candidate[i] = Arrow(id: single.id, cells: [cell], headDirection: altDir)
                        if solver.isSolvable(makeBoard(candidate)) {
                            let altBlocksNonParallel = arrows.contains { other in
                                guard other.id != single.id, other.headDirection != altDir else { return false }
                                var cursor = other.head.moved(by: other.headDirection)
                                while cursor.x >= 0 && cursor.x < width && cursor.y >= 0 && cursor.y < height {
                                    if cursor == cell { return true }
                                    cursor = cursor.moved(by: other.headDirection)
                                }
                                return false
                            }
                            if altBlocksNonParallel || isCriticalShapeTip {
                                arrows = candidate
                                reoriented = true
                                changed = true
                                break
                            }
                        }
                    }

                    // If it cannot be merged or usefully reoriented, drop the meaningless 1-cell arrow
                    if !reoriented && (hasSameDirBehind || shape == .rectangle) {
                        arrows.remove(at: i)
                        changed = true
                        break
                    }
                }
            }
        }

        return arrows
    }

    private func buildSubtitle(config: LevelConfig) -> String? {
        if config.isHardChallenge && config.shape != .rectangle {
            return "HARD · \(config.shape.displayName) · \(config.concept.displayName)"
        } else if config.isHardChallenge {
            return "HARD · \(config.concept.displayName)"
        } else if config.shape != .rectangle {
            return "\(config.shape.displayName) · \(config.concept.displayName)"
        } else {
            return config.concept.displayName
        }
    }

    private func deterministicUUID(seed: UInt64) -> UUID {
        var rng = SplitMix64(seed: seed)
        let a = rng.next()
        let b = rng.next()
        var bytes: uuid_t = (
            UInt8((a >> 56) & 0xFF), UInt8((a >> 48) & 0xFF),
            UInt8((a >> 40) & 0xFF), UInt8((a >> 32) & 0xFF),
            UInt8((a >> 24) & 0xFF), UInt8((a >> 16) & 0xFF),
            UInt8(((a >> 8) & 0x0F) | 0x40), UInt8(a & 0xFF),
            UInt8(((b >> 56) & 0x3F) | 0x80), UInt8((b >> 48) & 0xFF),
            UInt8((b >> 40) & 0xFF), UInt8((b >> 32) & 0xFF),
            UInt8((b >> 24) & 0xFF), UInt8((b >> 16) & 0xFF),
            UInt8((b >> 8) & 0xFF), UInt8(b & 0xFF)
        )
        return withUnsafePointer(to: &bytes) { UUID(uuid: $0.pointee) }
    }

    private func evaluateQuality(_ board: PuzzleBoard, config: LevelConfig) -> Double {
        guard !board.arrows.isEmpty, let metrics = solver.analyzeDifficulty(of: board) else {
            return -Double.infinity
        }

        let totalCells = Double(max(1, board.activeCells.count))
        let filledCells = Double(board.arrows.reduce(0) { $0 + $1.cells.count })
        let fillRatio = filledCells / totalCells

        let singleCellCount = board.arrows.filter(\.isSingleCell).count
        let maxArrowLen = board.arrows.map(\.cells.count).max() ?? 0
        let bendCount = board.arrows.reduce(0) { total, arrow in
            total + countBends(in: arrow.cells)
        }
        let bendRatio = Double(bendCount) / Double(board.arrows.count)

        let shapeFullBonus: Double = (board.shape != .rectangle && fillRatio >= 0.999) ? 45.0 : 0.0
        let fillWeight: Double = board.shape == .rectangle ? 110.0 : 150.0
        let heroBonus: Double = maxArrowLen >= 10 ? min(28.0, Double(maxArrowLen) * 1.4) : 0.0

        let depthWeight: Double = config.isHardChallenge ? 20.0 : 15.0
        let bottleneckWeight: Double = config.isHardChallenge ? 165.0 : 135.0
        let loosePenalty: Double = metrics.initialFreeRatio > 0.35 ? -45.0 : 0.0

        return fillRatio * fillWeight
            + shapeFullBonus
            + heroBonus
            + (1.0 - metrics.initialFreeRatio) * bottleneckWeight
            + Double(metrics.peelDepth) * depthWeight
            + min(bendRatio, 2.5) * 10.0
            + loosePenalty
            - Double(singleCellCount) * 14.0
    }

    private func countBends(in cells: [GridPoint]) -> Int {
        guard cells.count >= 3 else { return 0 }
        var bends = 0
        for i in 1..<(cells.count - 1) {
            let d1 = Direction.from(from: cells[i - 1], to: cells[i])
            let d2 = Direction.from(from: cells[i], to: cells[i + 1])
            if d1 != d2 {
                bends += 1
            }
        }
        return bends
    }
}
