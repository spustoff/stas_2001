//
//  SettingsViewModel.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile = UserProfile()
    @Published var isLoading: Bool = false
    @Published var showingProfileEdit: Bool = false
    @Published var showingAchievements: Bool = false
    @Published var showingLeaderboard: Bool = false
    @Published var showingDataManagement: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    
    // MARK: - Preferences (Published for immediate UI updates)
    @Published var soundEnabled: Bool = true {
        didSet { updatePreference(\.soundEnabled, value: soundEnabled) }
    }
    
    @Published var musicEnabled: Bool = true {
        didSet { updatePreference(\.musicEnabled, value: musicEnabled) }
    }
    
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet { updatePreference(\.hapticFeedbackEnabled, value: hapticFeedbackEnabled) }
    }
    
    @Published var notificationsEnabled: Bool = true {
        didSet { updatePreference(\.notificationsEnabled, value: notificationsEnabled) }
    }
    
    @Published var difficulty: GameLevel.Difficulty = .medium {
        didSet { updatePreference(\.difficulty, value: difficulty) }
    }
    
    @Published var colorBlindMode: Bool = false {
        didSet { updatePreference(\.colorBlindMode, value: colorBlindMode) }
    }
    
    @Published var animationSpeed: UserPreferences.AnimationSpeed = .normal {
        didSet { updatePreference(\.animationSpeed, value: animationSpeed) }
    }
    
    @Published var theme: UserPreferences.GameTheme = .futuristic {
        didSet { updatePreference(\.theme, value: theme) }
    }
    
    @Published var showHints: Bool = true {
        didSet { updatePreference(\.showHints, value: showHints) }
    }
    
    @Published var particleEffects: Bool = true {
        didSet { updatePreference(\.particleEffects, value: particleEffects) }
    }
    
    // MARK: - Private Properties
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var levelProgressText: String {
        return "Level \(userProfile.level) (\(userProfile.experienceToNextLevel) XP to next)"
    }
    
    var totalPlayTimeText: String {
        let hours = Int(userProfile.stats.totalPlayTime) / 3600
        let minutes = Int(userProfile.stats.totalPlayTime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var averageScoreText: String {
        guard userProfile.stats.totalGamesPlayed > 0 else { return "0" }
        let average = userProfile.stats.totalScore / userProfile.stats.totalGamesPlayed
        return "\(average)"
    }
    
    // MARK: - Initialization
    init() {
        loadUserProfile()
    }
    
    // MARK: - Data Loading
    func loadUserProfile() {
        isLoading = true
        
        Task {
            if let profile = await dataService.loadUserProfile() {
                await MainActor.run {
                    self.userProfile = profile
                    self.syncPreferencesToPublished()
                    self.isLoading = false
                }
            } else {
                // Create new user profile
                let newProfile = UserProfile()
                await dataService.saveUserProfile(newProfile)
                await MainActor.run {
                    self.userProfile = newProfile
                    self.syncPreferencesToPublished()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func syncPreferencesToPublished() {
        let prefs = userProfile.preferences
        soundEnabled = prefs.soundEnabled
        musicEnabled = prefs.musicEnabled
        hapticFeedbackEnabled = prefs.hapticFeedbackEnabled
        notificationsEnabled = prefs.notificationsEnabled
        difficulty = prefs.difficulty
        colorBlindMode = prefs.colorBlindMode
        animationSpeed = prefs.animationSpeed
        theme = prefs.theme
        showHints = prefs.showHints
        particleEffects = prefs.particleEffects
    }
    
    // MARK: - Profile Management
    func updateUsername(_ newUsername: String) {
        guard !newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Username cannot be empty")
            return
        }
        
        userProfile.username = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        saveUserProfile()
    }
    
    func updateAvatar(_ newAvatar: String) {
        userProfile.avatar = newAvatar
        saveUserProfile()
    }
    
    func addExperience(_ amount: Int) {
        userProfile.addExperience(amount)
        saveUserProfile()
    }
    
    func addCoins(_ amount: Int) {
        userProfile.addCoins(amount)
        saveUserProfile()
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if userProfile.spendCoins(amount) {
            saveUserProfile()
            return true
        }
        return false
    }
    
    func addGems(_ amount: Int) {
        userProfile.addGems(amount)
        saveUserProfile()
    }
    
    func spendGems(_ amount: Int) -> Bool {
        if userProfile.spendGems(amount) {
            saveUserProfile()
            return true
        }
        return false
    }
    
    // MARK: - Preferences Management
    private func updatePreference<T>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) {
        userProfile.preferences[keyPath: keyPath] = value
        saveUserProfile()
    }
    
    func resetPreferences() {
        userProfile.preferences = UserPreferences()
        syncPreferencesToPublished()
        saveUserProfile()
    }
    
    // MARK: - Data Management
    func exportUserData() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(userProfile)
            return String(data: data, encoding: .utf8)
        } catch {
            showError("Failed to export data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importUserData(_ jsonString: String) {
        do {
            guard let data = jsonString.data(using: .utf8) else {
                showError("Invalid data format")
                return
            }
            
            let decoder = JSONDecoder()
            let importedProfile = try decoder.decode(UserProfile.self, from: data)
            
            userProfile = importedProfile
            syncPreferencesToPublished()
            saveUserProfile()
            
        } catch {
            showError("Failed to import data: \(error.localizedDescription)")
        }
    }
    
    func resetAllData() {
        Task {
            do {
                try await dataService.resetAllData()
                await MainActor.run {
                    self.userProfile = UserProfile()
                    self.syncPreferencesToPublished()
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to reset data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Statistics
    func getAchievementProgress() -> [Achievement] {
        var achievements = userProfile.stats.achievements
        
        // Update achievement progress based on current stats
        for i in achievements.indices {
            switch achievements[i].category {
            case .score:
                achievements[i].progress = userProfile.stats.highestScore
            case .levels:
                achievements[i].progress = userProfile.stats.levelsCompleted
            case .patterns:
                achievements[i].progress = userProfile.stats.patternsMatched.values.reduce(0, +)
            case .powerUps:
                achievements[i].progress = userProfile.stats.powerUpsUsed.values.reduce(0, +)
            case .time:
                achievements[i].progress = Int(userProfile.stats.totalPlayTime / 3600) // Hours
            }
            
            // Check if achievement is unlocked
            if achievements[i].progress >= achievements[i].requirement && !achievements[i].isUnlocked {
                achievements[i].isUnlocked = true
                // Could trigger achievement notification here
            }
        }
        
        userProfile.stats.achievements = achievements
        return achievements
    }
    
    func getStatsSummary() -> [(String, String)] {
        let stats = userProfile.stats
        return [
            ("Games Played", "\(stats.totalGamesPlayed)"),
            ("Total Score", "\(stats.totalScore)"),
            ("Highest Score", "\(stats.highestScore)"),
            ("Levels Completed", "\(stats.levelsCompleted)"),
            ("Play Time", totalPlayTimeText),
            ("Average Score", averageScoreText)
        ]
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() {
        // Implementation would depend on notification service
        // For now, just update the preference
        notificationsEnabled = true
    }
    
    // MARK: - Theme Management
    func applyTheme(_ theme: UserPreferences.GameTheme) {
        self.theme = theme
        // Additional theme application logic could go here
    }
    
    func getAvailableThemes() -> [UserPreferences.GameTheme] {
        return UserPreferences.GameTheme.allCases
    }
    
    // MARK: - Accessibility
    func toggleColorBlindMode() {
        colorBlindMode.toggle()
    }
    
    func getColorBlindPalette() -> [Color] {
        if colorBlindMode {
            // Return colorblind-friendly palette
            return [
                Color.blue,
                Color.orange,
                Color.green,
                Color.red,
                Color.purple,
                Color.brown
            ]
        } else {
            return AppConstants.Colors.sphereColors
        }
    }
    
    // MARK: - Private Helpers
    private func saveUserProfile() {
        Task {
            do {
                await dataService.saveUserProfile(userProfile)
            } catch {
                await MainActor.run {
                    self.showError("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    // MARK: - Debug Helpers
    #if DEBUG
    func addTestData() {
        userProfile.addExperience(5000)
        userProfile.addCoins(1000)
        userProfile.addGems(50)
        userProfile.stats.totalGamesPlayed = 25
        userProfile.stats.totalScore = 50000
        userProfile.stats.highestScore = 5000
        userProfile.stats.levelsCompleted = 15
        userProfile.stats.totalPlayTime = 7200 // 2 hours
        saveUserProfile()
    }
    
    func simulateAchievement() {
        var achievement = Achievement.firstWin
        achievement.isUnlocked = true
        achievement.progress = achievement.requirement
        userProfile.stats.achievements.append(achievement)
        saveUserProfile()
    }
    #endif
}

// MARK: - Settings Sections
enum SettingsSection: String, CaseIterable {
    case profile = "Profile"
    case gameplay = "Gameplay"
    case audio = "Audio & Haptics"
    case display = "Display"
    case accessibility = "Accessibility"
    case data = "Data Management"
    case about = "About"
    
    var icon: String {
        switch self {
        case .profile: return "person.circle.fill"
        case .gameplay: return "gamecontroller.fill"
        case .audio: return "speaker.wave.3.fill"
        case .display: return "display"
        case .accessibility: return "accessibility"
        case .data: return "externaldrive.fill"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - Profile Edit Data
struct ProfileEditData {
    var username: String
    var selectedAvatar: String
    
    init(from profile: UserProfile) {
        self.username = profile.username
        self.selectedAvatar = profile.avatar
    }
}

// MARK: - Available Avatars
extension SettingsViewModel {
    static let availableAvatars = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.crop.circle.badge.plus",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.xmark",
        "person.crop.circle.badge.questionmark",
        "person.crop.circle.badge.exclamationmark",
        "person.2.circle.fill",
        "person.3.circle.fill",
        "gamecontroller.fill"
    ]
}
