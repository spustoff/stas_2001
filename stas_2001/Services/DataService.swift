//
//  DataService.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import Foundation
import SwiftUI

@MainActor
class DataService: ObservableObject {
    static let shared = DataService()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let userProfile = "userProfile"
        static let gameSaves = "gameSaves"
        static let leaderboard = "leaderboard"
    }
    
    // MARK: - Initialization
    private init() {
        // Initialize with UserDefaults-based storage
    }
    
    // MARK: - Storage Operations
    private func save<T: Codable>(_ object: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(object)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    private func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - User Profile Management
    func loadUserProfile() async -> UserProfile? {
        return load(UserProfile.self, forKey: Keys.userProfile)
    }
    
    func saveUserProfile(_ profile: UserProfile) async {
        do {
            try save(profile, forKey: Keys.userProfile)
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
    
    func createDefaultUserProfile() async -> UserProfile {
        let profile = UserProfile()
        await saveUserProfile(profile)
        return profile
    }
    
    // MARK: - Game Save Management
    func saveGame(_ saveData: GameSaveData) async throws {
        var saves = load([GameSaveData].self, forKey: Keys.gameSaves) ?? []
        
        // Remove existing save with same ID if it exists
        saves.removeAll { $0.id == saveData.id }
        
        // Add new save
        saves.append(saveData)
        
        // Keep only the latest 10 saves
        saves = Array(saves.sorted { $0.savedAt > $1.savedAt }.prefix(10))
        
        try save(saves, forKey: Keys.gameSaves)
    }
    
    func loadGameSaves(for userId: UUID) async throws -> [GameSaveData] {
        let allSaves = load([GameSaveData].self, forKey: Keys.gameSaves) ?? []
        return allSaves.filter { $0.userProfile.id == userId }
    }
    
    func deleteGameSave(_ saveData: GameSaveData) async throws {
        var saves = load([GameSaveData].self, forKey: Keys.gameSaves) ?? []
        saves.removeAll { $0.id == saveData.id }
        try save(saves, forKey: Keys.gameSaves)
    }
    
    func loadLatestGameSave(for userId: UUID) async -> GameSaveData? {
        do {
            let saves = try await loadGameSaves(for: userId)
            return saves.first
        } catch {
            print("Failed to load latest game save: \(error)")
            return nil
        }
    }
    
    // MARK: - Statistics and Progress
    func saveGameProgress(level: Int, score: Int, playTime: TimeInterval) async {
        guard var profile = await loadUserProfile() else { return }
        
        // Update statistics
        profile.stats.recordGame(
            score: score,
            level: level,
            playTime: playTime,
            powerUpsUsed: [] // This would be passed from the game
        )
        
        // Add experience and coins based on performance
        let experienceGained = score / 100
        let coinsGained = level * 10
        
        profile.addExperience(experienceGained)
        profile.addCoins(coinsGained)
        
        // Update last played date
        profile.lastPlayedAt = Date()
        
        await saveUserProfile(profile)
    }
    
    func updateAchievements(_ achievements: [Achievement]) async {
        guard var profile = await loadUserProfile() else { return }
        profile.stats.achievements = achievements
        await saveUserProfile(profile)
    }
    
    // MARK: - Leaderboard Management
    func saveLeaderboardEntry(_ entry: LeaderboardEntry) async throws {
        var entries = load([LeaderboardEntry].self, forKey: Keys.leaderboard) ?? []
        
        // Remove existing entry with same username if it exists
        entries.removeAll { $0.username == entry.username }
        
        // Add new entry
        entries.append(entry)
        
        // Keep only top 100 entries
        entries = Array(entries.sorted { $0.score > $1.score }.prefix(100))
        
        try save(entries, forKey: Keys.leaderboard)
    }
    
    func loadLeaderboardEntries() async -> [LeaderboardEntry] {
        var entries = load([LeaderboardEntry].self, forKey: Keys.leaderboard) ?? []
        
        // Sort by score descending
        entries.sort { $0.score > $1.score }
        
        // Assign ranks
        for (index, _) in entries.enumerated() {
            entries[index].rank = index + 1
        }
        
        return entries
    }
    
    func getPlayerRank(score: Int) async -> Int {
        let entries = await loadLeaderboardEntries()
        let betterScores = entries.filter { $0.score > score }
        return betterScores.count + 1
    }
    
    // MARK: - Data Export/Import
    func exportAllData() async throws -> Data {
        guard let profile = await loadUserProfile() else {
            throw DataServiceError.noDataToExport
        }
        
        let saves = try await loadGameSaves(for: profile.id)
        let leaderboard = await loadLeaderboardEntries()
        
        let exportData = ExportData(
            userProfile: profile,
            gameSaves: saves,
            leaderboardEntries: leaderboard,
            exportDate: Date()
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    func importAllData(_ data: Data) async throws {
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // Save user profile
        await saveUserProfile(importData.userProfile)
        
        // Save game saves
        for save in importData.gameSaves {
            try await saveGame(save)
        }
        
        // Save leaderboard entries
        for entry in importData.leaderboardEntries {
            try await saveLeaderboardEntry(entry)
        }
    }
    
    // MARK: - Data Reset
    func resetAllData() async throws {
        // Clear all stored data
        remove(forKey: Keys.userProfile)
        remove(forKey: Keys.gameSaves)
        remove(forKey: Keys.leaderboard)
        
        // Clear onboarding flag
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
    }
    
    // MARK: - Backup and Sync
    func createBackup() async throws -> URL {
        let exportData = try await exportAllData()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupURL = documentsPath.appendingPathComponent("FuturoSphere_Backup_\(Date().timeIntervalSince1970).json")
        
        try exportData.write(to: backupURL)
        return backupURL
    }
    
    func restoreFromBackup(url: URL) async throws {
        let data = try Data(contentsOf: url)
        try await importAllData(data)
    }
    
    // MARK: - Performance Optimization
    func performBackgroundTask<T>(_ block: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result = try block()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Data Validation
    func validateDataIntegrity() async -> DataIntegrityReport {
        var report = DataIntegrityReport()
        
        do {
            // Check user profile
            let profile = await loadUserProfile()
            report.userProfilesCount = profile != nil ? 1 : 0
            
            // Check game saves
            if let profile = profile {
                let saves = try await loadGameSaves(for: profile.id)
                report.gameSavesCount = saves.count
            }
            
            // Check leaderboard entries
            let leaderboard = await loadLeaderboardEntries()
            report.leaderboardEntriesCount = leaderboard.count
            
            report.isValid = true
            
        } catch {
            report.error = error.localizedDescription
            report.isValid = false
        }
        
        return report
    }
    
    func cleanupOrphanedData() async throws {
        // With UserDefaults storage, there's no orphaned data to clean up
        // This method is kept for compatibility
    }
}

// MARK: - Supporting Types
enum DataServiceError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case noDataToExport
    case invalidImportData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .noDataToExport:
            return "No data available to export"
        case .invalidImportData:
            return "Invalid import data format"
        }
    }
}

struct ExportData: Codable {
    let userProfile: UserProfile
    let gameSaves: [GameSaveData]
    let leaderboardEntries: [LeaderboardEntry]
    let exportDate: Date
    let version: String = "1.0"
}

struct DataIntegrityReport {
    var userProfilesCount: Int = 0
    var gameSavesCount: Int = 0
    var leaderboardEntriesCount: Int = 0
    var orphanedSaves: [UUID] = []
    var isValid: Bool = true
    var error: String?
    
    var summary: String {
        if let error = error {
            return "Data integrity check failed: \(error)"
        }
        
        var summary = "Data Integrity Report:\n"
        summary += "• User Profiles: \(userProfilesCount)\n"
        summary += "• Game Saves: \(gameSavesCount)\n"
        summary += "• Leaderboard Entries: \(leaderboardEntriesCount)\n"
        summary += "• Orphaned Saves: \(orphanedSaves.count)\n"
        summary += "• Status: \(isValid ? "✅ Valid" : "❌ Issues Found")"
        
        return summary
    }
}
