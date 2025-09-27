//
//  SettingsView.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .profile
    
    var body: some View {
        let backgroundGradient = LinearGradient(
            colors: [AppConstants.Colors.darkBackground, AppConstants.Colors.cardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return NavigationView {
            ZStack {
                // Background
                backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView()
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: AppConstants.Dimensions.standardPadding) {
                            ForEach(SettingsSection.allCases, id: \.self) { section in
                                SettingsSectionView(
                                    section: section,
                                    isExpanded: selectedSection == section
                                ) {
                                    let newSection = selectedSection == section ? .profile : section
                                    withAnimation(Animation.easeInOut(duration: AppConstants.Animations.standardDuration)) {
                                        selectedSection = newSection
                                    }
                                }
                                .environmentObject(settingsViewModel)
                            }
                        }
                        .padding(AppConstants.Dimensions.standardPadding)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $settingsViewModel.showingProfileEdit) {
            ProfileEditView()
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $settingsViewModel.showingAchievements) {
            AchievementsView()
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $settingsViewModel.showingLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $settingsViewModel.showingDataManagement) {
            DataManagementView()
                .environmentObject(settingsViewModel)
        }
        .alert("Error", isPresented: $settingsViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(settingsViewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            settingsViewModel.loadUserProfile()
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppConstants.Colors.textPrimary)
                .glowEffect(color: AppConstants.Colors.accentCyan, radius: 2)
            
            Spacer()
            
            // Placeholder for balance
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(Color.clear)
            }
            .disabled(true)
        }
        .padding(AppConstants.Dimensions.standardPadding)
    }
}

// MARK: - Settings Section View
struct SettingsSectionView: View {
    let section: SettingsSection
    let isExpanded: Bool
    let onTap: () -> Void
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onTap) {
                HStack {
                    Image(systemName: section.icon)
                        .font(.title2)
                        .foregroundColor(AppConstants.Colors.accentCyan)
                        .frame(width: 30)
                    
                    Text(section.rawValue)
                        .font(.headline)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(Animation.easeInOut(duration: AppConstants.Animations.standardDuration), value: isExpanded)
                }
                .padding(AppConstants.Dimensions.standardPadding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                        .fill(AppConstants.Colors.cardBackground.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                                .stroke(AppConstants.Colors.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Section Content
            if isExpanded {
                VStack(spacing: AppConstants.Dimensions.standardPadding) {
                    switch section {
                    case .profile:
                        ProfileSectionContent()
                    case .gameplay:
                        GameplaySectionContent()
                    case .audio:
                        AudioSectionContent()
                    case .display:
                        DisplaySectionContent()
                    case .accessibility:
                        AccessibilitySectionContent()
                    case .data:
                        DataSectionContent()
                    case .about:
                        AboutSectionContent()
                    }
                }
                .padding(AppConstants.Dimensions.standardPadding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                        .fill(AppConstants.Colors.cardBackground.opacity(0.4))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Section Content Views

struct ProfileSectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            // User Info Card
            HStack {
                Image(systemName: settingsViewModel.userProfile.avatar)
                    .font(.system(size: 50))
                    .foregroundColor(AppConstants.Colors.accentCyan)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(AppConstants.Colors.cardBackground)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsViewModel.userProfile.username)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text(settingsViewModel.levelProgressText)
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                    
                    ProgressView(value: settingsViewModel.userProfile.levelProgress)
                        .tint(AppConstants.Colors.neonGreen)
                        .frame(width: 150)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(AppConstants.Colors.sphereColors[3])
                        Text("\(settingsViewModel.userProfile.coins)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(AppConstants.Colors.purpleGlow)
                        Text("\(settingsViewModel.userProfile.gems)")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(AppConstants.Colors.textPrimary)
            }
            
            // Action Buttons
            HStack(spacing: AppConstants.Dimensions.standardPadding) {
                Button("Edit Profile") {
                    settingsViewModel.showingProfileEdit = true
                }
                .futuristicButton(color: AppConstants.Colors.primaryBlue)
                
                Button("Achievements") {
                    settingsViewModel.showingAchievements = true
                }
                .futuristicButton(color: AppConstants.Colors.neonGreen)
                
                Button("Leaderboard") {
                    settingsViewModel.showingLeaderboard = true
                }
                .futuristicButton(color: AppConstants.Colors.purpleGlow)
            }
        }
    }
}

struct GameplaySectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            SettingRow(
                title: "Difficulty",
                subtitle: "Game challenge level"
            ) {
                Picker("Difficulty", selection: $settingsViewModel.difficulty) {
                    ForEach(GameLevel.Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue.capitalized)
                            .tag(difficulty)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            SettingRow(
                title: "Show Hints",
                subtitle: "Display helpful suggestions"
            ) {
                Toggle("", isOn: $settingsViewModel.showHints)
                    .tint(AppConstants.Colors.accentCyan)
            }
            
            SettingRow(
                title: "Animation Speed",
                subtitle: "Game animation timing"
            ) {
                Picker("Speed", selection: $settingsViewModel.animationSpeed) {
                    ForEach(UserPreferences.AnimationSpeed.allCases, id: \.self) { speed in
                        Text(speed.rawValue)
                            .tag(speed)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

struct AudioSectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            SettingRow(
                title: "Sound Effects",
                subtitle: "Game sounds and audio feedback"
            ) {
                Toggle("", isOn: $settingsViewModel.soundEnabled)
                    .tint(AppConstants.Colors.accentCyan)
            }
            
            SettingRow(
                title: "Background Music",
                subtitle: "Ambient game music"
            ) {
                Toggle("", isOn: $settingsViewModel.musicEnabled)
                    .tint(AppConstants.Colors.accentCyan)
            }
            
            SettingRow(
                title: "Haptic Feedback",
                subtitle: "Vibration on interactions"
            ) {
                Toggle("", isOn: $settingsViewModel.hapticFeedbackEnabled)
                    .tint(AppConstants.Colors.accentCyan)
            }
        }
    }
}

struct DisplaySectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            SettingRow(
                title: "Theme",
                subtitle: "Visual appearance style"
            ) {
                Picker("Theme", selection: $settingsViewModel.theme) {
                    ForEach(UserPreferences.GameTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue)
                            .tag(theme)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            SettingRow(
                title: "Particle Effects",
                subtitle: "Visual effects and animations"
            ) {
                Toggle("", isOn: $settingsViewModel.particleEffects)
                    .tint(AppConstants.Colors.accentCyan)
            }
        }
    }
}

struct AccessibilitySectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            SettingRow(
                title: "Color Blind Mode",
                subtitle: "Enhanced color differentiation"
            ) {
                Toggle("", isOn: $settingsViewModel.colorBlindMode)
                    .tint(AppConstants.Colors.accentCyan)
            }
            
            if settingsViewModel.colorBlindMode {
                Text("Color blind friendly palette is active")
                    .font(.caption)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .padding(.top, -8)
            }
        }
    }
}

struct DataSectionContent: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            Button("Manage Data") {
                settingsViewModel.showingDataManagement = true
            }
            .futuristicButton(color: AppConstants.Colors.primaryBlue)
            
            Button("Reset All Settings") {
                settingsViewModel.resetPreferences()
            }
            .futuristicButton(color: AppConstants.Colors.textSecondary.opacity(0.6))
        }
    }
}

struct AboutSectionContent: View {
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            HStack {
                Text("Version")
                    .foregroundColor(AppConstants.Colors.textSecondary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppConstants.Colors.textPrimary)
            }
            
            HStack {
                Text("Build")
                    .foregroundColor(AppConstants.Colors.textSecondary)
                Spacer()
                Text("2025.09.27")
                    .foregroundColor(AppConstants.Colors.textPrimary)
            }
            
            Text("FuturoSpherePlin - A futuristic puzzle game experience")
                .font(.caption)
                .foregroundColor(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
    }
}

// MARK: - Helper Views

struct SettingRow<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                Spacer()
                
                content
            }
            
            Divider()
                .background(AppConstants.Colors.textSecondary.opacity(0.3))
        }
    }
}

// MARK: - Additional Views

struct ProfileEditView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editData: ProfileEditData
    
    init() {
        _editData = State(initialValue: ProfileEditData(from: UserProfile()))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.darkBackground.ignoresSafeArea()
                
                VStack(spacing: AppConstants.Dimensions.largePadding) {
                    // Avatar Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(SettingsViewModel.availableAvatars, id: \.self) { avatar in
                            Button(action: {
                                editData.selectedAvatar = avatar
                            }) {
                                Image(systemName: avatar)
                                    .font(.title)
                                    .foregroundColor(editData.selectedAvatar == avatar ? AppConstants.Colors.accentCyan : AppConstants.Colors.textSecondary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(AppConstants.Colors.cardBackground)
                                            .overlay(
                                                Circle()
                                                    .stroke(editData.selectedAvatar == avatar ? AppConstants.Colors.accentCyan : Color.clear, lineWidth: 2)
                                            )
                                    )
                            }
                        }
                    }
                    
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        TextField("Enter username", text: $editData.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Spacer()
                    
                    // Save Button
                    Button("Save Changes") {
                        settingsViewModel.updateUsername(editData.username)
                        settingsViewModel.updateAvatar(editData.selectedAvatar)
                        dismiss()
                    }
                    .futuristicButton(color: AppConstants.Colors.primaryBlue)
                    .disabled(editData.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(AppConstants.Dimensions.standardPadding)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            editData = ProfileEditData(from: settingsViewModel.userProfile)
        }
    }
}

struct AchievementsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppConstants.Dimensions.standardPadding) {
                        ForEach(settingsViewModel.getAchievementProgress()) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                    .padding(AppConstants.Dimensions.standardPadding)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? AppConstants.Colors.neonGreen : AppConstants.Colors.textSecondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                
                ProgressView(value: achievement.progressPercentage)
                    .tint(AppConstants.Colors.accentCyan)
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppConstants.Colors.neonGreen)
            } else {
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption)
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
        }
        .padding(AppConstants.Dimensions.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                .fill(AppConstants.Colors.cardBackground.opacity(0.6))
        )
    }
}

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.darkBackground.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                        .foregroundColor(AppConstants.Colors.textPrimary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppConstants.Dimensions.standardPadding) {
                            ForEach(leaderboardEntries) { entry in
                                LeaderboardRow(entry: entry)
                            }
                        }
                        .padding(AppConstants.Dimensions.standardPadding)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        Task {
            let entries = await DataService.shared.loadLeaderboardEntries()
            await MainActor.run {
                self.leaderboardEntries = entries
                self.isLoading = false
            }
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Avatar
            Image(systemName: entry.avatar)
                .font(.title2)
                .foregroundColor(AppConstants.Colors.accentCyan)
                .frame(width: 30)
            
            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.headline)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Text("Level \(entry.level) • \(entry.timeAgo)")
                    .font(.caption)
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            
            Spacer()
            
            // Score
            Text(entry.formattedScore)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppConstants.Colors.neonGreen)
        }
        .padding(AppConstants.Dimensions.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                .fill(AppConstants.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return AppConstants.Colors.sphereColors[3] // Gold
        case 2: return AppConstants.Colors.textSecondary // Silver
        case 3: return AppConstants.Colors.sphereColors[2] // Bronze
        default: return AppConstants.Colors.textPrimary
        }
    }
}

struct DataManagementView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.darkBackground.ignoresSafeArea()
                
                VStack(spacing: AppConstants.Dimensions.largePadding) {
                    // Statistics
                    VStack(alignment: .leading, spacing: AppConstants.Dimensions.standardPadding) {
                        Text("Statistics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        ForEach(settingsViewModel.getStatsSummary(), id: \.0) { stat in
                            HStack {
                                Text(stat.0)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                Spacer()
                                Text(stat.1)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                            }
                        }
                    }
                    .padding(AppConstants.Dimensions.standardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                            .fill(AppConstants.Colors.cardBackground.opacity(0.6))
                    )
                    
                    Spacer()
                    
                    // Data Management Actions
                    VStack(spacing: AppConstants.Dimensions.standardPadding) {
                        Button("Export Data") {
                            exportData()
                        }
                        .futuristicButton(color: AppConstants.Colors.primaryBlue)
                        
                        Button("Reset All Data") {
                            showingResetAlert = true
                        }
                        .futuristicButton(color: AppConstants.Colors.sphereColors[3])
                    }
                }
                .padding(AppConstants.Dimensions.standardPadding)
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsViewModel.resetAllData()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all your game data, progress, and settings. This action cannot be undone.")
        }
    }
    
    private func exportData() {
        if let exportString = settingsViewModel.exportUserData() {
            let activityVC = UIActivityViewController(
                activityItems: [exportString],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
}

#Preview {
    SettingsView()
}
