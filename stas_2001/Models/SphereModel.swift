//
//  SphereModel.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI
import Foundation

// MARK: - Sphere Model
struct Sphere: Identifiable, Equatable, Codable {
    let id = UUID()
    var position: GridPosition
    var type: SphereType
    var state: SphereState
    var powerUp: PowerUpType?
    var animationOffset: CGSize = .zero
    var isSelected: Bool = false
    var glowIntensity: Double = 0.0
    
    init(position: GridPosition, type: SphereType, state: SphereState = .normal) {
        self.position = position
        self.type = type
        self.state = state
    }
    
    static func == (lhs: Sphere, rhs: Sphere) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sphere Type
enum SphereType: Int, CaseIterable, Codable {
    case cyan = 0
    case neonGreen = 1
    case purple = 2
    case orange = 3
    case yellow = 4
    case pink = 5
    
    var color: Color {
        switch self {
        case .cyan: return AppConstants.Colors.sphereColors[0]
        case .neonGreen: return AppConstants.Colors.sphereColors[1]
        case .purple: return AppConstants.Colors.sphereColors[2]
        case .orange: return AppConstants.Colors.sphereColors[3]
        case .yellow: return AppConstants.Colors.sphereColors[4]
        case .pink: return AppConstants.Colors.sphereColors[5]
        }
    }
    
    var name: String {
        switch self {
        case .cyan: return "Cyan"
        case .neonGreen: return "Neon Green"
        case .purple: return "Purple"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .pink: return "Pink"
        }
    }
    
    static func random() -> SphereType {
        return SphereType.allCases.randomElement() ?? .cyan
    }
}

// MARK: - Sphere State
enum SphereState: Codable {
    case normal
    case highlighted
    case matched
    case transforming
    case exploding
    case frozen
    case charged
}

// MARK: - Grid Position
struct GridPosition: Equatable, Codable, Hashable {
    let row: Int
    let column: Int
    
    init(_ row: Int, _ column: Int) {
        self.row = row
        self.column = column
    }
    
    func distance(to other: GridPosition) -> Int {
        abs(row - other.row) + abs(column - other.column)
    }
    
    func isAdjacent(to other: GridPosition) -> Bool {
        distance(to: other) == 1
    }
    
    var neighbors: [GridPosition] {
        return [
            GridPosition(row - 1, column),     // Up
            GridPosition(row + 1, column),     // Down
            GridPosition(row, column - 1),     // Left
            GridPosition(row, column + 1)      // Right
        ].filter { $0.isValid }
    }
    
    var isValid: Bool {
        return row >= 0 && row < AppConstants.Game.gridSize &&
               column >= 0 && column < AppConstants.Game.gridSize
    }
}

// MARK: - Power-Up Types
enum PowerUpType: String, CaseIterable, Codable {
    case lightning = "bolt.fill"
    case transform = "wand.and.stars"
    case timeBoost = "timer"
    case multiplier = "sparkles"
    case bomb = "burst.fill"
    case freeze = "snowflake"
    
    var name: String {
        switch self {
        case .lightning: return "Lightning"
        case .transform: return "Transform"
        case .timeBoost: return "Time Boost"
        case .multiplier: return "Multiplier"
        case .bomb: return "Bomb"
        case .freeze: return "Freeze"
        }
    }
    
    var description: String {
        switch self {
        case .lightning: return "Clear an entire row"
        case .transform: return "Change sphere colors"
        case .timeBoost: return "Add 15 seconds"
        case .multiplier: return "Double score for 30s"
        case .bomb: return "Clear surrounding spheres"
        case .freeze: return "Stop timer for 10s"
        }
    }
    
    var color: Color {
        switch self {
        case .lightning: return AppConstants.Colors.neonGreen
        case .transform: return AppConstants.Colors.purpleGlow
        case .timeBoost: return AppConstants.Colors.accentCyan
        case .multiplier: return AppConstants.Colors.sphereColors[3]
        case .bomb: return AppConstants.Colors.sphereColors[3]
        case .freeze: return AppConstants.Colors.secondaryBlue
        }
    }
    
    var rarity: PowerUpRarity {
        switch self {
        case .lightning, .bomb: return .common
        case .transform, .timeBoost: return .uncommon
        case .multiplier, .freeze: return .rare
        }
    }
}

enum PowerUpRarity {
    case common, uncommon, rare
    
    var spawnChance: Double {
        switch self {
        case .common: return 0.15
        case .uncommon: return 0.08
        case .rare: return 0.03
        }
    }
}

// MARK: - Game Pattern
struct GamePattern: Identifiable, Codable {
    let id = UUID()
    let positions: [GridPosition]
    let requiredType: SphereType?
    let name: String
    let points: Int
    
    init(positions: [GridPosition], requiredType: SphereType? = nil, name: String, points: Int = 100) {
        self.positions = positions
        self.requiredType = requiredType
        self.name = name
        self.points = points
    }
    
    // Predefined patterns
    static let horizontalLine3 = GamePattern(
        positions: [GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2)],
        name: "Horizontal Line",
        points: 150
    )
    
    static let verticalLine3 = GamePattern(
        positions: [GridPosition(0, 0), GridPosition(1, 0), GridPosition(2, 0)],
        name: "Vertical Line",
        points: 150
    )
    
    static let lShape = GamePattern(
        positions: [GridPosition(0, 0), GridPosition(1, 0), GridPosition(1, 1)],
        name: "L-Shape",
        points: 200
    )
    
    static let square = GamePattern(
        positions: [GridPosition(0, 0), GridPosition(0, 1), GridPosition(1, 0), GridPosition(1, 1)],
        name: "Square",
        points: 250
    )
    
    static let cross = GamePattern(
        positions: [GridPosition(1, 0), GridPosition(0, 1), GridPosition(1, 1), GridPosition(2, 1), GridPosition(1, 2)],
        name: "Cross",
        points: 300
    )
}

// MARK: - Game Level
struct GameLevel: Identifiable, Codable {
    let id = UUID()
    let number: Int
    let name: String
    let description: String
    let targetScore: Int
    let timeLimit: Double
    let maxMoves: Int
    let requiredPatterns: [GamePattern]
    let initialSpheres: [Sphere]
    let powerUpsEnabled: [PowerUpType]
    let difficulty: Difficulty
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy, medium, hard, expert
        
        var multiplier: Double {
            switch self {
            case .easy: return 1.0
            case .medium: return 1.5
            case .hard: return 2.0
            case .expert: return 3.0
            }
        }
    }
}

// MARK: - Game Statistics
struct GameStats: Codable {
    var totalGamesPlayed: Int = 0
    var totalScore: Int = 0
    var highestScore: Int = 0
    var levelsCompleted: Int = 0
    var totalPlayTime: TimeInterval = 0
    var powerUpsUsed: [PowerUpType: Int] = [:]
    var patternsMatched: [String: Int] = [:]
    var achievements: [Achievement] = []
    
    mutating func recordGame(score: Int, level: Int, playTime: TimeInterval, powerUpsUsed: [PowerUpType]) {
        totalGamesPlayed += 1
        totalScore += score
        highestScore = max(highestScore, score)
        levelsCompleted = max(levelsCompleted, level)
        totalPlayTime += playTime
        
        for powerUp in powerUpsUsed {
            self.powerUpsUsed[powerUp, default: 0] += 1
        }
    }
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let requirement: Int
    var isUnlocked: Bool = false
    var progress: Int = 0
    let category: AchievementCategory
    
    enum AchievementCategory: String, Codable {
        case score, levels, patterns, powerUps, time
    }
    
    var progressPercentage: Double {
        return min(Double(progress) / Double(requirement), 1.0)
    }
    
    // Predefined achievements
    static let firstWin = Achievement(
        name: "First Victory",
        description: "Complete your first level",
        iconName: "trophy.fill",
        requirement: 1,
        category: .levels
    )
    
    static let scoremaster = Achievement(
        name: "Score Master",
        description: "Reach 10,000 points in a single game",
        iconName: "star.fill",
        requirement: 10000,
        category: .score
    )
    
    static let patternExpert = Achievement(
        name: "Pattern Expert",
        description: "Match 100 patterns",
        iconName: "square.grid.3x3.fill",
        requirement: 100,
        category: .patterns
    )
}
