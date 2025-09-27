//
//  UserModel.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Codable {
    var id: UUID = UUID()
    var username: String = "Player"
    var avatar: String = "person.circle.fill"
    var level: Int = 1
    var experience: Int = 0
    var coins: Int = 0
    var gems: Int = 0
    var createdAt: Date = Date()
    var lastPlayedAt: Date = Date()
    var preferences: UserPreferences = UserPreferences()
    var stats: GameStats = GameStats()
    
    var experienceToNextLevel: Int {
        return (level * 1000) - experience
    }
    
    var levelProgress: Double {
        let currentLevelExp = (level - 1) * 1000
        let nextLevelExp = level * 1000
        let progressExp = experience - currentLevelExp
        return Double(progressExp) / Double(nextLevelExp - currentLevelExp)
    }
    
    mutating func addExperience(_ amount: Int) {
        experience += amount
        while experience >= level * 1000 {
            level += 1
            coins += level * 10 // Bonus coins for leveling up
        }
    }
    
    mutating func addCoins(_ amount: Int) {
        coins += amount
    }
    
    mutating func spendCoins(_ amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            return true
        }
        return false
    }
    
    mutating func addGems(_ amount: Int) {
        gems += amount
    }
    
    mutating func spendGems(_ amount: Int) -> Bool {
        if gems >= amount {
            gems -= amount
            return true
        }
        return false
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var difficulty: GameLevel.Difficulty = .medium
    var colorBlindMode: Bool = false
    var animationSpeed: AnimationSpeed = .normal
    var theme: GameTheme = .futuristic
    var language: String = "en"
    var autoSave: Bool = true
    var showHints: Bool = true
    var particleEffects: Bool = true
    
    enum AnimationSpeed: String, CaseIterable, Codable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
        
        var multiplier: Double {
            switch self {
            case .slow: return 1.5
            case .normal: return 1.0
            case .fast: return 0.7
            }
        }
    }
    
    enum GameTheme: String, CaseIterable, Codable {
        case futuristic = "Futuristic"
        case neon = "Neon"
        case cosmic = "Cosmic"
        case minimal = "Minimal"
        
        var primaryColor: Color {
            switch self {
            case .futuristic: return AppConstants.Colors.primaryBlue
            case .neon: return AppConstants.Colors.neonGreen
            case .cosmic: return AppConstants.Colors.purpleGlow
            case .minimal: return Color.gray
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .futuristic: return AppConstants.Colors.darkBackground
            case .neon: return Color.black
            case .cosmic: return Color(red: 0.1, green: 0.0, blue: 0.2)
            case .minimal: return Color(red: 0.95, green: 0.95, blue: 0.95)
            }
        }
    }
}

// MARK: - Game Save Data
struct GameSaveData: Codable {
    let id: UUID = UUID()
    let userProfile: UserProfile
    let currentLevel: Int
    let currentScore: Int
    let gameBoard: [[Sphere?]]
    let timeRemaining: Double
    let movesLeft: Int
    let activePowerUps: [ActivePowerUp]
    let savedAt: Date = Date()
    
    struct ActivePowerUp: Codable {
        let type: PowerUpType
        let remainingTime: Double
        let isActive: Bool
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id = UUID()
    let username: String
    let score: Int
    let level: Int
    let achievedAt: Date
    let avatar: String
    
    var rank: Int = 0 // Set by leaderboard service
    
    var formattedScore: String {
        if score >= 1_000_000 {
            return String(format: "%.1fM", Double(score) / 1_000_000)
        } else if score >= 1_000 {
            return String(format: "%.1fK", Double(score) / 1_000)
        } else {
            return "\(score)"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: achievedAt, relativeTo: Date())
    }
}

// MARK: - Helper Extensions
extension UserProfile {
    static let `default` = UserProfile()
}
