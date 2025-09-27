//
//  GameLogicService.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import Foundation
import SwiftUI

class GameLogicService {
    
    // MARK: - Pattern Matching
    func findAllMatches(in board: [[Sphere?]]) -> [MatchResult] {
        var matches: [MatchResult] = []
        let gridSize = board.count
        
        // Check horizontal matches
        for row in 0..<gridSize {
            var currentMatch: [GridPosition] = []
            var currentType: SphereType?
            
            for col in 0..<gridSize {
                if let sphere = board[row][col] {
                    if sphere.type == currentType {
                        currentMatch.append(GridPosition(row, col))
                    } else {
                        // Process previous match if it exists
                        if currentMatch.count >= 3 {
                            matches.append(MatchResult(
                                positions: currentMatch,
                                type: currentType!,
                                pattern: .horizontal,
                                score: calculateScore(for: currentMatch, pattern: .horizontal)
                            ))
                        }
                        
                        // Start new match
                        currentMatch = [GridPosition(row, col)]
                        currentType = sphere.type
                    }
                } else {
                    // Process current match if it exists
                    if currentMatch.count >= 3 {
                        matches.append(MatchResult(
                            positions: currentMatch,
                            type: currentType!,
                            pattern: .horizontal,
                            score: calculateScore(for: currentMatch, pattern: .horizontal)
                        ))
                    }
                    currentMatch = []
                    currentType = nil
                }
            }
            
            // Check final match in row
            if currentMatch.count >= 3 {
                matches.append(MatchResult(
                    positions: currentMatch,
                    type: currentType!,
                    pattern: .horizontal,
                    score: calculateScore(for: currentMatch, pattern: .horizontal)
                ))
            }
        }
        
        // Check vertical matches
        for col in 0..<gridSize {
            var currentMatch: [GridPosition] = []
            var currentType: SphereType?
            
            for row in 0..<gridSize {
                if let sphere = board[row][col] {
                    if sphere.type == currentType {
                        currentMatch.append(GridPosition(row, col))
                    } else {
                        // Process previous match if it exists
                        if currentMatch.count >= 3 {
                            matches.append(MatchResult(
                                positions: currentMatch,
                                type: currentType!,
                                pattern: .vertical,
                                score: calculateScore(for: currentMatch, pattern: .vertical)
                            ))
                        }
                        
                        // Start new match
                        currentMatch = [GridPosition(row, col)]
                        currentType = sphere.type
                    }
                } else {
                    // Process current match if it exists
                    if currentMatch.count >= 3 {
                        matches.append(MatchResult(
                            positions: currentMatch,
                            type: currentType!,
                            pattern: .vertical,
                            score: calculateScore(for: currentMatch, pattern: .vertical)
                        ))
                    }
                    currentMatch = []
                    currentType = nil
                }
            }
            
            // Check final match in column
            if currentMatch.count >= 3 {
                matches.append(MatchResult(
                    positions: currentMatch,
                    type: currentType!,
                    pattern: .vertical,
                    score: calculateScore(for: currentMatch, pattern: .vertical)
                ))
            }
        }
        
        // Check for special patterns (L-shapes, T-shapes, etc.)
        let specialMatches = findSpecialPatterns(in: board)
        matches.append(contentsOf: specialMatches)
        
        return removeDuplicateMatches(matches)
    }
    
    private func findSpecialPatterns(in board: [[Sphere?]]) -> [MatchResult] {
        var specialMatches: [MatchResult] = []
        let gridSize = board.count
        
        // Check for L-shapes
        for row in 0..<gridSize-2 {
            for col in 0..<gridSize-2 {
                if let lMatch = checkLShape(in: board, at: GridPosition(row, col)) {
                    specialMatches.append(lMatch)
                }
            }
        }
        
        // Check for T-shapes
        for row in 1..<gridSize-1 {
            for col in 1..<gridSize-1 {
                if let tMatch = checkTShape(in: board, at: GridPosition(row, col)) {
                    specialMatches.append(tMatch)
                }
            }
        }
        
        // Check for squares
        for row in 0..<gridSize-1 {
            for col in 0..<gridSize-1 {
                if let squareMatch = checkSquare(in: board, at: GridPosition(row, col)) {
                    specialMatches.append(squareMatch)
                }
            }
        }
        
        return specialMatches
    }
    
    private func checkLShape(in board: [[Sphere?]], at position: GridPosition) -> MatchResult? {
        let row = position.row
        let col = position.column
        
        guard let centerSphere = board[row][col] else { return nil }
        let type = centerSphere.type
        
        // Check all possible L-shape orientations
        let lPatterns: [[(Int, Int)]] = [
            [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)], // L pointing right-down
            [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)], // L pointing left-down
            [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)], // L pointing right-up
            [(0, 2), (1, 2), (2, 2), (2, 1), (2, 0)]  // L pointing left-up
        ]
        
        for pattern in lPatterns {
            var positions: [GridPosition] = []
            var isValidPattern = true
            
            for (deltaRow, deltaCol) in pattern {
                let newRow = row + deltaRow
                let newCol = col + deltaCol
                
                if newRow >= 0 && newRow < board.count && newCol >= 0 && newCol < board[0].count,
                   let sphere = board[newRow][newCol], sphere.type == type {
                    positions.append(GridPosition(newRow, newCol))
                } else {
                    isValidPattern = false
                    break
                }
            }
            
            if isValidPattern && positions.count == 5 {
                return MatchResult(
                    positions: positions,
                    type: type,
                    pattern: .lShape,
                    score: calculateScore(for: positions, pattern: .lShape)
                )
            }
        }
        
        return nil
    }
    
    private func checkTShape(in board: [[Sphere?]], at position: GridPosition) -> MatchResult? {
        let row = position.row
        let col = position.column
        
        guard let centerSphere = board[row][col] else { return nil }
        let type = centerSphere.type
        
        // T-shape patterns (center + 4 directions)
        let tPatterns: [[(Int, Int)]] = [
            [(-1, 0), (0, -1), (0, 0), (0, 1), (1, 0)], // Standard T
            [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)], // Rotated T
        ]
        
        for pattern in tPatterns {
            var positions: [GridPosition] = []
            var isValidPattern = true
            
            for (deltaRow, deltaCol) in pattern {
                let newRow = row + deltaRow
                let newCol = col + deltaCol
                
                if newRow >= 0 && newRow < board.count && newCol >= 0 && newCol < board[0].count,
                   let sphere = board[newRow][newCol], sphere.type == type {
                    positions.append(GridPosition(newRow, newCol))
                } else {
                    isValidPattern = false
                    break
                }
            }
            
            if isValidPattern && positions.count == 5 {
                return MatchResult(
                    positions: positions,
                    type: type,
                    pattern: .tShape,
                    score: calculateScore(for: positions, pattern: .tShape)
                )
            }
        }
        
        return nil
    }
    
    private func checkSquare(in board: [[Sphere?]], at position: GridPosition) -> MatchResult? {
        let row = position.row
        let col = position.column
        
        guard let topLeftSphere = board[row][col] else { return nil }
        let type = topLeftSphere.type
        
        let squarePositions = [
            GridPosition(row, col),
            GridPosition(row, col + 1),
            GridPosition(row + 1, col),
            GridPosition(row + 1, col + 1)
        ]
        
        for position in squarePositions {
            if position.row >= board.count || position.column >= board[0].count ||
               board[position.row][position.column]?.type != type {
                return nil
            }
        }
        
        return MatchResult(
            positions: squarePositions,
            type: type,
            pattern: .square,
            score: calculateScore(for: squarePositions, pattern: .square)
        )
    }
    
    private func removeDuplicateMatches(_ matches: [MatchResult]) -> [MatchResult] {
        var uniqueMatches: [MatchResult] = []
        
        for match in matches {
            let isDuplicate = uniqueMatches.contains { existingMatch in
                Set(existingMatch.positions) == Set(match.positions)
            }
            
            if !isDuplicate {
                uniqueMatches.append(match)
            }
        }
        
        return uniqueMatches
    }
    
    // MARK: - Scoring System
    private func calculateScore(for positions: [GridPosition], pattern: MatchPattern) -> Int {
        let baseScore = positions.count * AppConstants.Game.scoreMultiplier
        let patternMultiplier = pattern.scoreMultiplier
        return Int(Double(baseScore) * patternMultiplier)
    }
    
    func calculateTotalScore(for matches: [MatchResult], comboMultiplier: Int = 1) -> Int {
        let baseScore = matches.reduce(0) { $0 + $1.score }
        let comboBonus = baseScore * max(0, comboMultiplier - 1)
        return baseScore + comboBonus
    }
    
    // MARK: - Board Manipulation
    func applyGravity(to board: inout [[Sphere?]]) -> [SphereMovement] {
        var movements: [SphereMovement] = []
        let gridSize = board.count
        
        for col in 0..<gridSize {
            var writeIndex = gridSize - 1
            
            // Move existing spheres down
            for row in stride(from: gridSize - 1, through: 0, by: -1) {
                if let sphere = board[row][col] {
                    if writeIndex != row {
                        // Record movement
                        movements.append(SphereMovement(
                            sphere: sphere,
                            from: GridPosition(row, col),
                            to: GridPosition(writeIndex, col)
                        ))
                        
                        // Move sphere
                        board[writeIndex][col] = sphere
                        board[writeIndex][col]?.position = GridPosition(writeIndex, col)
                        board[row][col] = nil
                    }
                    writeIndex -= 1
                }
            }
        }
        
        return movements
    }
    
    func fillEmptySpaces(in board: inout [[Sphere?]]) -> [Sphere] {
        var newSpheres: [Sphere] = []
        let gridSize = board.count
        
        for col in 0..<gridSize {
            for row in 0..<gridSize {
                if board[row][col] == nil {
                    let position = GridPosition(row, col)
                    let newSphere = Sphere(position: position, type: SphereType.random())
                    board[row][col] = newSphere
                    newSpheres.append(newSphere)
                }
            }
        }
        
        return newSpheres
    }
    
    // MARK: - Power-Up Logic
    func applyPowerUp(_ powerUp: PowerUpType, to board: inout [[Sphere?]], at position: GridPosition?) -> PowerUpResult {
        switch powerUp {
        case .lightning:
            return applyLightningPowerUp(to: &board, at: position)
        case .transform:
            return applyTransformPowerUp(to: &board)
        case .bomb:
            return applyBombPowerUp(to: &board, at: position)
        case .freeze:
            return PowerUpResult(affectedPositions: [], newSpheres: [], scoreBonus: 0)
        case .timeBoost:
            return PowerUpResult(affectedPositions: [], newSpheres: [], scoreBonus: 0)
        case .multiplier:
            return PowerUpResult(affectedPositions: [], newSpheres: [], scoreBonus: 0)
        }
    }
    
    private func applyLightningPowerUp(to board: inout [[Sphere?]], at position: GridPosition?) -> PowerUpResult {
        let targetRow = position?.row ?? Int.random(in: 0..<board.count)
        var affectedPositions: [GridPosition] = []
        
        // Clear entire row
        for col in 0..<board[targetRow].count {
            if board[targetRow][col] != nil {
                affectedPositions.append(GridPosition(targetRow, col))
                board[targetRow][col] = nil
            }
        }
        
        // Apply gravity and fill
        let movements = applyGravity(to: &board)
        let newSpheres = fillEmptySpaces(in: &board)
        
        return PowerUpResult(
            affectedPositions: affectedPositions,
            newSpheres: newSpheres,
            scoreBonus: affectedPositions.count * 50
        )
    }
    
    private func applyTransformPowerUp(to board: inout [[Sphere?]]) -> PowerUpResult {
        let fromType = SphereType.random()
        var toType = SphereType.random()
        while toType == fromType {
            toType = SphereType.random()
        }
        
        var affectedPositions: [GridPosition] = []
        
        for row in 0..<board.count {
            for col in 0..<board[row].count {
                if board[row][col]?.type == fromType {
                    board[row][col]?.type = toType
                    board[row][col]?.state = .transforming
                    affectedPositions.append(GridPosition(row, col))
                }
            }
        }
        
        return PowerUpResult(
            affectedPositions: affectedPositions,
            newSpheres: [],
            scoreBonus: affectedPositions.count * 25
        )
    }
    
    private func applyBombPowerUp(to board: inout [[Sphere?]], at position: GridPosition?) -> PowerUpResult {
        guard let center = position else {
            return PowerUpResult(affectedPositions: [], newSpheres: [], scoreBonus: 0)
        }
        
        var affectedPositions: [GridPosition] = []
        let radius = 1
        
        // Clear area around center
        for row in max(0, center.row - radius)...min(board.count - 1, center.row + radius) {
            for col in max(0, center.column - radius)...min(board[0].count - 1, center.column + radius) {
                if board[row][col] != nil {
                    affectedPositions.append(GridPosition(row, col))
                    board[row][col] = nil
                }
            }
        }
        
        // Apply gravity and fill
        let movements = applyGravity(to: &board)
        let newSpheres = fillEmptySpaces(in: &board)
        
        return PowerUpResult(
            affectedPositions: affectedPositions,
            newSpheres: newSpheres,
            scoreBonus: affectedPositions.count * 75
        )
    }
    
    // MARK: - Move Validation
    func isValidMove(from: GridPosition, to: GridPosition, in board: [[Sphere?]]) -> Bool {
        // Check if positions are adjacent
        guard from.isAdjacent(to: to) else { return false }
        
        // Check if both positions have spheres
        guard board[from.row][from.column] != nil,
              board[to.row][to.column] != nil else { return false }
        
        // Simulate the move and check if it creates matches
        var testBoard = board
        let fromSphere = testBoard[from.row][from.column]
        let toSphere = testBoard[to.row][to.column]
        
        testBoard[from.row][from.column] = toSphere
        testBoard[to.row][to.column] = fromSphere
        
        testBoard[from.row][from.column]?.position = from
        testBoard[to.row][to.column]?.position = to
        
        let matches = findAllMatches(in: testBoard)
        return !matches.isEmpty
    }
    
    // MARK: - Hint System
    func findPossibleMoves(in board: [[Sphere?]]) -> [PossibleMove] {
        var possibleMoves: [PossibleMove] = []
        let gridSize = board.count
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let currentPosition = GridPosition(row, col)
                
                // Check all adjacent positions
                for neighbor in currentPosition.neighbors {
                    if neighbor.isValid && isValidMove(from: currentPosition, to: neighbor, in: board) {
                        // Calculate potential score for this move
                        var testBoard = board
                        let fromSphere = testBoard[currentPosition.row][currentPosition.column]
                        let toSphere = testBoard[neighbor.row][neighbor.column]
                        
                        testBoard[currentPosition.row][currentPosition.column] = toSphere
                        testBoard[neighbor.row][neighbor.column] = fromSphere
                        
                        testBoard[currentPosition.row][currentPosition.column]?.position = currentPosition
                        testBoard[neighbor.row][neighbor.column]?.position = neighbor
                        
                        let matches = findAllMatches(in: testBoard)
                        let score = calculateTotalScore(for: matches)
                        
                        possibleMoves.append(PossibleMove(
                            from: currentPosition,
                            to: neighbor,
                            potentialScore: score,
                            matchCount: matches.count
                        ))
                    }
                }
            }
        }
        
        // Sort by potential score (highest first)
        possibleMoves.sort { $0.potentialScore > $1.potentialScore }
        
        return possibleMoves
    }
    
    func getBestMove(in board: [[Sphere?]]) -> PossibleMove? {
        let possibleMoves = findPossibleMoves(in: board)
        return possibleMoves.first
    }
    
    // MARK: - Difficulty Adjustment
    func adjustDifficultyForLevel(_ level: Int) -> DifficultySettings {
        let baseSettings = DifficultySettings()
        
        switch level {
        case 1...10:
            return baseSettings
        case 11...25:
            return DifficultySettings(
                sphereTypes: min(5, baseSettings.sphereTypes + 1),
                timeLimit: baseSettings.timeLimit - 5,
                targetScoreMultiplier: 1.2,
                powerUpSpawnRate: baseSettings.powerUpSpawnRate * 0.8
            )
        case 26...40:
            return DifficultySettings(
                sphereTypes: 6,
                timeLimit: baseSettings.timeLimit - 10,
                targetScoreMultiplier: 1.5,
                powerUpSpawnRate: baseSettings.powerUpSpawnRate * 0.6
            )
        default:
            return DifficultySettings(
                sphereTypes: 6,
                timeLimit: max(30, baseSettings.timeLimit - 15),
                targetScoreMultiplier: 2.0,
                powerUpSpawnRate: baseSettings.powerUpSpawnRate * 0.4
            )
        }
    }
}

// MARK: - Supporting Types
struct MatchResult {
    let positions: [GridPosition]
    let type: SphereType
    let pattern: MatchPattern
    let score: Int
}

enum MatchPattern {
    case horizontal
    case vertical
    case lShape
    case tShape
    case square
    case cross
    
    var scoreMultiplier: Double {
        switch self {
        case .horizontal, .vertical: return 1.0
        case .lShape, .tShape: return 1.5
        case .square: return 2.0
        case .cross: return 2.5
        }
    }
    
    var name: String {
        switch self {
        case .horizontal: return "Horizontal Line"
        case .vertical: return "Vertical Line"
        case .lShape: return "L-Shape"
        case .tShape: return "T-Shape"
        case .square: return "Square"
        case .cross: return "Cross"
        }
    }
}

struct SphereMovement {
    let sphere: Sphere
    let from: GridPosition
    let to: GridPosition
}

struct PowerUpResult {
    let affectedPositions: [GridPosition]
    let newSpheres: [Sphere]
    let scoreBonus: Int
}

struct PossibleMove {
    let from: GridPosition
    let to: GridPosition
    let potentialScore: Int
    let matchCount: Int
}

struct DifficultySettings {
    let sphereTypes: Int
    let timeLimit: Double
    let targetScoreMultiplier: Double
    let powerUpSpawnRate: Double
    
    init(sphereTypes: Int = 4, timeLimit: Double = 60, targetScoreMultiplier: Double = 1.0, powerUpSpawnRate: Double = 0.1) {
        self.sphereTypes = sphereTypes
        self.timeLimit = timeLimit
        self.targetScoreMultiplier = targetScoreMultiplier
        self.powerUpSpawnRate = powerUpSpawnRate
    }
}
