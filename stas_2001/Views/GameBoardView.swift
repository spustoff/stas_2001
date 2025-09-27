//
//  GameBoardView.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var draggedSphere: Sphere?
    @State private var animatingMatches: Set<UUID> = []
    @State private var showingHint: Bool = false
    @State private var hintPositions: [GridPosition] = []
    
    private let gridSpacing: CGFloat = 4
    private let boardPadding: CGFloat = 16
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.standardPadding) {
            // Power-ups bar
            if !gameViewModel.availablePowerUps.isEmpty {
                PowerUpsBar()
                    .environmentObject(gameViewModel)
            }
            
            // Game board
            GeometryReader { geometry in
                let boardSize = min(geometry.size.width, geometry.size.height) - boardPadding * 2
                let cellSize = (boardSize - gridSpacing * CGFloat(AppConstants.Game.gridSize - 1)) / CGFloat(AppConstants.Game.gridSize)
                
                ZStack {
                    // Background grid
                    GridBackground(cellSize: cellSize, spacing: gridSpacing)
                    
                    // Spheres
                    ForEach(0..<AppConstants.Game.gridSize, id: \.self) { row in
                        ForEach(0..<AppConstants.Game.gridSize, id: \.self) { col in
                            if let sphere = gameViewModel.gameBoard[row][col] {
                                SphereView(
                                    sphere: sphere,
                                    cellSize: cellSize,
                                    isHinted: hintPositions.contains(sphere.position),
                                    isAnimatingMatch: animatingMatches.contains(sphere.id)
                                )
                                .position(
                                    x: CGFloat(col) * (cellSize + gridSpacing) + cellSize / 2 + boardPadding,
                                    y: CGFloat(row) * (cellSize + gridSpacing) + cellSize / 2 + boardPadding
                                )
                                .offset(sphere.id == draggedSphere?.id ? dragOffset : .zero)
                                .scaleEffect(sphere.id == draggedSphere?.id ? 1.1 : 1.0)
                                .animation(AppConstants.Animations.bounceAnimation, value: draggedSphere?.id)
                                .onTapGesture {
                                    selectSphere(sphere)
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            handleDragChanged(sphere: sphere, value: value, cellSize: cellSize)
                                        }
                                        .onEnded { value in
                                            handleDragEnded(sphere: sphere, value: value, cellSize: cellSize)
                                        }
                                )
                            }
                        }
                    }
                    
                    // Match animations overlay
                    if gameViewModel.lastMatchScore > 0 {
                        ScorePopupView(score: gameViewModel.lastMatchScore)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: boardSize + boardPadding * 2, height: boardSize + boardPadding * 2)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                        .fill(AppConstants.Colors.cardBackground.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                                .stroke(AppConstants.Colors.accentCyan.opacity(0.3), lineWidth: 2)
                        )
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            // Hint button
            HStack {
                Button(action: showHint) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Hint")
                    }
                }
                .futuristicButton(color: AppConstants.Colors.neonGreen.opacity(0.8))
                .disabled(!gameViewModel.canMove)
                
                Spacer()
                
                // Combo indicator
                if gameViewModel.comboMultiplier > 1 {
                    HStack {
                        Text("COMBO")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("×\(gameViewModel.comboMultiplier)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(AppConstants.Colors.neonGreen)
                    .glowEffect(color: AppConstants.Colors.neonGreen, radius: 4)
                    .scaleEffect(1.2)
                    .animation(AppConstants.Animations.pulseAnimation, value: gameViewModel.comboMultiplier)
                }
            }
            .padding(.horizontal, AppConstants.Dimensions.standardPadding)
        }
        .onReceive(gameViewModel.$matchedPatterns) { patterns in
            if !patterns.isEmpty {
                animateMatches(patterns)
            }
        }
    }
    
    // MARK: - Sphere Interaction
    private func selectSphere(_ sphere: Sphere) {
        gameViewModel.selectSphere(at: sphere.position)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleDragChanged(sphere: Sphere, value: DragGesture.Value, cellSize: CGFloat) {
        draggedSphere = sphere
        dragOffset = value.translation
        
        // Provide haptic feedback when dragging starts
        if dragOffset == .zero {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleDragEnded(sphere: Sphere, value: DragGesture.Value, cellSize: CGFloat) {
        defer {
            draggedSphere = nil
            dragOffset = .zero
        }
        
        let translation = value.translation
        let threshold = cellSize * 0.5
        
        // Determine direction and target position
        var targetPosition = sphere.position
        
        if abs(translation.width) > abs(translation.height) {
            // Horizontal movement
            if translation.width > threshold {
                targetPosition = GridPosition(sphere.position.row, sphere.position.column + 1)
            } else if translation.width < -threshold {
                targetPosition = GridPosition(sphere.position.row, sphere.position.column - 1)
            }
        } else {
            // Vertical movement
            if translation.height > threshold {
                targetPosition = GridPosition(sphere.position.row + 1, sphere.position.column)
            } else if translation.height < -threshold {
                targetPosition = GridPosition(sphere.position.row - 1, sphere.position.column)
            }
        }
        
        // Attempt move if target is different and valid
        if targetPosition != sphere.position && targetPosition.isValid {
            gameViewModel.selectSphere(at: sphere.position)
            gameViewModel.selectSphere(at: targetPosition)
        }
    }
    
    // MARK: - Hint System
    private func showHint() {
        let gameLogicService = GameLogicService()
        let possibleMoves = gameLogicService.findPossibleMoves(in: gameViewModel.gameBoard)
        
        if let bestMove = possibleMoves.first {
            hintPositions = [bestMove.from, bestMove.to]
            showingHint = true
            
            // Hide hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(Animation.easeInOut(duration: AppConstants.Animations.standardDuration)) {
                    hintPositions = []
                    showingHint = false
                }
            }
            
            // Haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } else {
            // No moves available - could trigger shuffle or game over
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
    
    // MARK: - Match Animation
    private func animateMatches(_ patterns: [GamePattern]) {
        let allPositions = patterns.flatMap { $0.positions }
        
        for position in allPositions {
            if let sphere = gameViewModel.gameBoard[position.row][position.column] {
                animatingMatches.insert(sphere.id)
            }
        }
        
        // Remove animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingMatches.removeAll()
        }
    }
}

// MARK: - Supporting Views

struct GridBackground: View {
    let cellSize: CGFloat
    let spacing: CGFloat
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<AppConstants.Game.gridSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<AppConstants.Game.gridSize, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppConstants.Colors.cardBackground.opacity(0.5))
                            .frame(width: cellSize, height: cellSize)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppConstants.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

struct SphereView: View {
    let sphere: Sphere
    let cellSize: CGFloat
    let isHinted: Bool
    let isAnimatingMatch: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Main sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            sphere.type.color.opacity(0.8),
                            sphere.type.color,
                            sphere.type.color.opacity(0.6)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: cellSize * 0.4
                    )
                )
                .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .glowEffect(color: sphere.type.color, radius: sphere.isSelected ? 8 : 4)
                .scaleEffect(pulseScale)
                .rotationEffect(.degrees(rotationAngle))
            
            // Power-up indicator
            if let powerUp = sphere.powerUp {
                Image(systemName: powerUp.rawValue)
                    .font(.system(size: cellSize * 0.3))
                    .foregroundColor(AppConstants.Colors.textPrimary)
                    .glowEffect(color: powerUp.color, radius: 2)
            }
            
            // Selection indicator
            if sphere.isSelected {
                Circle()
                    .stroke(AppConstants.Colors.textPrimary, lineWidth: 3)
                    .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                    .scaleEffect(pulseScale)
            }
            
            // Hint indicator
            if isHinted {
                Circle()
                    .stroke(AppConstants.Colors.neonGreen, lineWidth: 4)
                    .frame(width: cellSize * 0.95, height: cellSize * 0.95)
                    .opacity(0.8)
                    .scaleEffect(pulseScale)
            }
        }
        .animation(AppConstants.Animations.bounceAnimation, value: sphere.isSelected)
        .onAppear {
            startIdleAnimation()
        }
        .onChange(of: isAnimatingMatch) { isAnimating in
            if isAnimating {
                startMatchAnimation()
            }
        }
        .onChange(of: sphere.state) { state in
            handleStateChange(state)
        }
    }
    
    private func startIdleAnimation() {
        withAnimation(
            Animation.linear(duration: 10.0).repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
        
        withAnimation(AppConstants.Animations.pulseAnimation) {
            pulseScale = sphere.isSelected ? 1.1 : 1.0
        }
    }
    
    private func startMatchAnimation() {
        withAnimation(Animation.easeInOut(duration: AppConstants.Animations.fastDuration)) {
            pulseScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animations.fastDuration) {
            withAnimation(Animation.easeInOut(duration: AppConstants.Animations.fastDuration)) {
                pulseScale = 0.1
            }
        }
    }
    
    private func handleStateChange(_ state: SphereState) {
        switch state {
        case .transforming:
            withAnimation(Animation.easeInOut(duration: AppConstants.Animations.standardDuration)) {
                rotationAngle += 180
                pulseScale = 1.2
            }
        case .exploding:
            startMatchAnimation()
        case .charged:
            withAnimation(AppConstants.Animations.pulseAnimation) {
                pulseScale = 1.15
            }
        default:
            break
        }
    }
}

struct PowerUpsBar: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: AppConstants.Dimensions.standardPadding) {
            Text("Power-Ups:")
                .font(.headline)
                .foregroundColor(AppConstants.Colors.textSecondary)
            
            ForEach(gameViewModel.availablePowerUps, id: \.self) { powerUp in
                Button(action: {
                    gameViewModel.usePowerUp(powerUp)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: powerUp.rawValue)
                            .font(.title2)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Text(powerUp.name)
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(powerUp.color.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(powerUp.color, lineWidth: 2)
                            )
                    )
                    .glowEffect(color: powerUp.color, radius: 4)
                }
                .disabled(!gameViewModel.canMove)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.Dimensions.standardPadding)
    }
}

struct ScorePopupView: View {
    let score: Int
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Text("+\(score)")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(AppConstants.Colors.neonGreen)
            .glowEffect(color: AppConstants.Colors.neonGreen, radius: 4)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: yOffset)
            .onAppear {
                withAnimation(AppConstants.Animations.bounceAnimation) {
                    opacity = 1.0
                    scale = 1.2
                }
                
                withAnimation(
                    Animation.easeOut(duration: 1.0).delay(0.3)
                ) {
                    yOffset = -50
                    opacity = 0
                }
            }
    }
}

#Preview {
    GameBoardView()
        .environmentObject(GameViewModel())
        .background(AppConstants.Colors.darkBackground)
}
