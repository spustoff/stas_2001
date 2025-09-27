//
//  GameViewModel.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameBoard: [[Sphere?]] = []
    @Published var score: Int = 0
    @Published var currentLevel: Int = 1
    @Published var timeRemaining: Double = AppConstants.Game.timeLimit
    @Published var movesLeft: Int = 30
    @Published var gameState: GameState = .menu
    @Published var selectedSphere: Sphere?
    @Published var availablePowerUps: [PowerUpType] = []
    @Published var activePowerUps: [ActivePowerUp] = []
    @Published var matchedPatterns: [GamePattern] = []
    @Published var showLevelComplete: Bool = false
    @Published var showGameOver: Bool = false
    @Published var comboMultiplier: Int = 1
    @Published var lastMatchScore: Int = 0
    
    // MARK: - Private Properties
    private var gameTimer: Timer?
    private var powerUpTimers: [PowerUpType: Timer] = [:]
    private var gameLogicService = GameLogicService()
    private var dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentLevelData: GameLevel?
    
    // MARK: - Computed Properties
    var levelProgress: Double {
        guard let levelData = currentLevelData else { return 0.0 }
        return Double(score) / Double(levelData.targetScore)
    }
    
    var timeProgress: Double {
        guard let levelData = currentLevelData else { return 1.0 }
        return timeRemaining / levelData.timeLimit
    }
    
    var canMove: Bool {
        return gameState == .playing && movesLeft > 0 && timeRemaining > 0
    }
    
    // MARK: - Initialization
    init() {
        setupGame()
    }
    
    // MARK: - Game Setup
    private func setupGame() {
        initializeBoard()
        loadUserProgress()
    }
    
    private func initializeBoard() {
        gameBoard = Array(repeating: Array(repeating: nil, count: AppConstants.Game.gridSize), 
                         count: AppConstants.Game.gridSize)
    }
    
    private func loadUserProgress() {
        Task {
            if let userProfile = await dataService.loadUserProfile() {
                currentLevel = max(1, userProfile.stats.levelsCompleted)
            }
        }
    }
    
    // MARK: - Game Control
    func startNewGame() {
        resetGameState()
        currentLevelData = generateLevel(number: currentLevel)
        populateBoard()
        startTimer()
        gameState = .playing
    }
    
    func pauseGame() {
        if gameState == .playing {
            gameState = .paused
            stopTimer()
        } else if gameState == .paused {
            gameState = .playing
            startTimer()
        }
    }
    
    func resetGame() {
        resetGameState()
        gameState = .menu
    }
    
    private func resetGameState() {
        score = 0
        timeRemaining = AppConstants.Game.timeLimit
        movesLeft = 30
        selectedSphere = nil
        availablePowerUps = []
        activePowerUps = []
        matchedPatterns = []
        comboMultiplier = 1
        lastMatchScore = 0
        showLevelComplete = false
        showGameOver = false
        stopTimer()
        clearPowerUpTimers()
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updateTimer() {
        guard gameState == .playing else { return }
        
        timeRemaining -= 0.1
        
        if timeRemaining <= 0 {
            timeRemaining = 0
            endGame(won: false)
        }
    }
    
    // MARK: - Board Management
    private func populateBoard() {
        for row in 0..<AppConstants.Game.gridSize {
            for col in 0..<AppConstants.Game.gridSize {
                let position = GridPosition(row, col)
                let sphereType = SphereType.random()
                let sphere = Sphere(position: position, type: sphereType)
                gameBoard[row][col] = sphere
            }
        }
        
        // Ensure no initial matches
        removeInitialMatches()
    }
    
    private func removeInitialMatches() {
        var hasMatches = true
        var attempts = 0
        
        while hasMatches && attempts < 10 {
            hasMatches = false
            
            for row in 0..<AppConstants.Game.gridSize {
                for col in 0..<AppConstants.Game.gridSize {
                    if let sphere = gameBoard[row][col] {
                        let matches = findMatches(for: sphere)
                        if !matches.isEmpty {
                            // Change the sphere type to avoid matches
                            var newType = SphereType.random()
                            while newType == sphere.type {
                                newType = SphereType.random()
                            }
                            gameBoard[row][col]?.type = newType
                            hasMatches = true
                        }
                    }
                }
            }
            attempts += 1
        }
    }
    
    // MARK: - Sphere Movement
    func selectSphere(at position: GridPosition) {
        guard canMove, let sphere = gameBoard[position.row][position.column] else { return }
        
        if let selected = selectedSphere {
            if selected.position == position {
                // Deselect
                deselectSphere()
            } else if position.isAdjacent(to: selected.position) {
                // Attempt move
                moveSphere(from: selected.position, to: position)
            } else {
                // Select new sphere
                selectNewSphere(sphere)
            }
        } else {
            // Select sphere
            selectNewSphere(sphere)
        }
    }
    
    private func selectNewSphere(_ sphere: Sphere) {
        selectedSphere = sphere
        gameBoard[sphere.position.row][sphere.position.column]?.isSelected = true
        
        // Add visual feedback
        withAnimation(Animation.easeInOut(duration: AppConstants.Animations.fastDuration)) {
            gameBoard[sphere.position.row][sphere.position.column]?.glowIntensity = 1.0
        }
    }
    
    private func deselectSphere() {
        if let selected = selectedSphere {
            gameBoard[selected.position.row][selected.position.column]?.isSelected = false
            gameBoard[selected.position.row][selected.position.column]?.glowIntensity = 0.0
        }
        selectedSphere = nil
    }
    
    private func moveSphere(from: GridPosition, to: GridPosition) {
        guard let fromSphere = gameBoard[from.row][from.column],
              let toSphere = gameBoard[to.row][to.column] else { return }
        
        // Swap spheres
        gameBoard[from.row][from.column] = toSphere
        gameBoard[to.row][to.column] = fromSphere
        
        // Update positions
        gameBoard[from.row][from.column]?.position = from
        gameBoard[to.row][to.column]?.position = to
        
        deselectSphere()
        movesLeft -= 1
        
        // Check for matches
        checkForMatches()
        
        // Check win/lose conditions
        checkGameEndConditions()
    }
    
    // MARK: - Match Detection
    private func checkForMatches() {
        var allMatches: [Sphere] = []
        var matchedPatterns: [GamePattern] = []
        
        // Find all matches on the board
        for row in 0..<AppConstants.Game.gridSize {
            for col in 0..<AppConstants.Game.gridSize {
                if let sphere = gameBoard[row][col] {
                    let matches = findMatches(for: sphere)
                    if !matches.isEmpty {
                        allMatches.append(contentsOf: matches)
                        
                        // Identify pattern type
                        if let pattern = identifyPattern(matches: matches) {
                            matchedPatterns.append(pattern)
                        }
                    }
                }
            }
        }
        
        if !allMatches.isEmpty {
            processMatches(allMatches, patterns: matchedPatterns)
        } else {
            comboMultiplier = 1 // Reset combo if no matches
        }
    }
    
    private func findMatches(for sphere: Sphere) -> [Sphere] {
        var matches: [Sphere] = []
        let position = sphere.position
        
        // Check horizontal matches
        let horizontalMatches = findHorizontalMatches(at: position, type: sphere.type)
        if horizontalMatches.count >= 3 {
            matches.append(contentsOf: horizontalMatches)
        }
        
        // Check vertical matches
        let verticalMatches = findVerticalMatches(at: position, type: sphere.type)
        if verticalMatches.count >= 3 {
            matches.append(contentsOf: verticalMatches)
        }
        
        // Remove duplicates by ID
        var uniqueMatches: [Sphere] = []
        var seenIds: Set<UUID> = []
        
        for match in matches {
            if !seenIds.contains(match.id) {
                uniqueMatches.append(match)
                seenIds.insert(match.id)
            }
        }
        
        return uniqueMatches
    }
    
    private func findHorizontalMatches(at position: GridPosition, type: SphereType) -> [Sphere] {
        var matches: [Sphere] = []
        let row = position.row
        
        // Find leftmost position of the match
        var startCol = position.column
        while startCol > 0 && gameBoard[row][startCol - 1]?.type == type {
            startCol -= 1
        }
        
        // Find rightmost position of the match
        var endCol = position.column
        while endCol < AppConstants.Game.gridSize - 1 && gameBoard[row][endCol + 1]?.type == type {
            endCol += 1
        }
        
        // Collect matches if 3 or more
        if endCol - startCol + 1 >= 3 {
            for col in startCol...endCol {
                if let sphere = gameBoard[row][col] {
                    matches.append(sphere)
                }
            }
        }
        
        return matches
    }
    
    private func findVerticalMatches(at position: GridPosition, type: SphereType) -> [Sphere] {
        var matches: [Sphere] = []
        let col = position.column
        
        // Find topmost position of the match
        var startRow = position.row
        while startRow > 0 && gameBoard[startRow - 1][col]?.type == type {
            startRow -= 1
        }
        
        // Find bottommost position of the match
        var endRow = position.row
        while endRow < AppConstants.Game.gridSize - 1 && gameBoard[endRow + 1][col]?.type == type {
            endRow += 1
        }
        
        // Collect matches if 3 or more
        if endRow - startRow + 1 >= 3 {
            for row in startRow...endRow {
                if let sphere = gameBoard[row][col] {
                    matches.append(sphere)
                }
            }
        }
        
        return matches
    }
    
    private func identifyPattern(matches: [Sphere]) -> GamePattern? {
        let positions = matches.map { $0.position }
        
        // Check for specific patterns
        if isHorizontalLine(positions: positions) {
            return GamePattern.horizontalLine3
        } else if isVerticalLine(positions: positions) {
            return GamePattern.verticalLine3
        } else if isLShape(positions: positions) {
            return GamePattern.lShape
        } else if isSquare(positions: positions) {
            return GamePattern.square
        } else if isCross(positions: positions) {
            return GamePattern.cross
        }
        
        return nil
    }
    
    // MARK: - Pattern Recognition Helpers
    private func isHorizontalLine(positions: [GridPosition]) -> Bool {
        guard positions.count >= 3 else { return false }
        let sortedPositions = positions.sorted { $0.column < $1.column }
        let row = sortedPositions.first?.row ?? -1
        
        for (index, position) in sortedPositions.enumerated() {
            if position.row != row || position.column != sortedPositions.first!.column + index {
                return false
            }
        }
        return true
    }
    
    private func isVerticalLine(positions: [GridPosition]) -> Bool {
        guard positions.count >= 3 else { return false }
        let sortedPositions = positions.sorted { $0.row < $1.row }
        let col = sortedPositions.first?.column ?? -1
        
        for (index, position) in sortedPositions.enumerated() {
            if position.column != col || position.row != sortedPositions.first!.row + index {
                return false
            }
        }
        return true
    }
    
    private func isLShape(positions: [GridPosition]) -> Bool {
        return positions.count == 3 // Simplified check
    }
    
    private func isSquare(positions: [GridPosition]) -> Bool {
        return positions.count == 4 // Simplified check
    }
    
    private func isCross(positions: [GridPosition]) -> Bool {
        return positions.count == 5 // Simplified check
    }
    
    // MARK: - Match Processing
    private func processMatches(_ matches: [Sphere], patterns: [GamePattern]) {
        // Calculate score
        let baseScore = matches.count * AppConstants.Game.scoreMultiplier
        let patternBonus = patterns.reduce(0) { $0 + $1.points }
        let comboBonus = baseScore * (comboMultiplier - 1)
        let totalScore = baseScore + patternBonus + comboBonus
        
        score += totalScore
        lastMatchScore = totalScore
        comboMultiplier += 1
        
        // Apply power-up effects
        applyActivePowerUpEffects(matches: matches)
        
        // Remove matched spheres with animation
        removeMatchedSpheres(matches)
        
        // Drop spheres and fill empty spaces
        dropSpheresAndFill()
        
        // Check for chain reactions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkForMatches()
        }
        
        // Randomly spawn power-ups
        spawnPowerUps()
    }
    
    private func removeMatchedSpheres(_ matches: [Sphere]) {
        for sphere in matches {
            let position = sphere.position
            
            // Animate removal
            withAnimation(Animation.easeInOut(duration: AppConstants.Animations.fastDuration)) {
                gameBoard[position.row][position.column]?.state = .exploding
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animations.fastDuration) {
                self.gameBoard[position.row][position.column] = nil
            }
        }
    }
    
    private func dropSpheresAndFill() {
        // Drop existing spheres
        for col in 0..<AppConstants.Game.gridSize {
            var writeIndex = AppConstants.Game.gridSize - 1
            
            for row in stride(from: AppConstants.Game.gridSize - 1, through: 0, by: -1) {
                if let sphere = gameBoard[row][col] {
                    if writeIndex != row {
                        gameBoard[writeIndex][col] = sphere
                        gameBoard[writeIndex][col]?.position = GridPosition(writeIndex, col)
                        gameBoard[row][col] = nil
                    }
                    writeIndex -= 1
                }
            }
            
            // Fill empty spaces with new spheres
            for row in 0...writeIndex {
                let position = GridPosition(row, col)
                let newSphere = Sphere(position: position, type: SphereType.random())
                gameBoard[row][col] = newSphere
            }
        }
    }
    
    // MARK: - Power-Up Management
    private func spawnPowerUps() {
        for powerUpType in PowerUpType.allCases {
            if Double.random(in: 0...1) < powerUpType.rarity.spawnChance {
                availablePowerUps.append(powerUpType)
            }
        }
        
        // Limit available power-ups
        if availablePowerUps.count > 3 {
            availablePowerUps = Array(availablePowerUps.suffix(3))
        }
    }
    
    func usePowerUp(_ powerUpType: PowerUpType) {
        guard availablePowerUps.contains(powerUpType) else { return }
        
        availablePowerUps.removeAll { $0 == powerUpType }
        
        switch powerUpType {
        case .lightning:
            useLightningPowerUp()
        case .transform:
            useTransformPowerUp()
        case .timeBoost:
            useTimeBoostPowerUp()
        case .multiplier:
            useMultiplierPowerUp()
        case .bomb:
            useBombPowerUp()
        case .freeze:
            useFreezePowerUp()
        }
    }
    
    private func useLightningPowerUp() {
        // Clear a random row
        let randomRow = Int.random(in: 0..<AppConstants.Game.gridSize)
        var clearedSpheres: [Sphere] = []
        
        for col in 0..<AppConstants.Game.gridSize {
            if let sphere = gameBoard[randomRow][col] {
                clearedSpheres.append(sphere)
            }
        }
        
        processMatches(clearedSpheres, patterns: [])
    }
    
    private func useTransformPowerUp() {
        // Transform all spheres of a random type to another random type
        let fromType = SphereType.random()
        var toType = SphereType.random()
        while toType == fromType {
            toType = SphereType.random()
        }
        
        for row in 0..<AppConstants.Game.gridSize {
            for col in 0..<AppConstants.Game.gridSize {
                if gameBoard[row][col]?.type == fromType {
                    gameBoard[row][col]?.type = toType
                    gameBoard[row][col]?.state = .transforming
                }
            }
        }
    }
    
    private func useTimeBoostPowerUp() {
        timeRemaining += 15.0
        if let levelData = currentLevelData {
            timeRemaining = min(timeRemaining, levelData.timeLimit)
        }
    }
    
    private func useMultiplierPowerUp() {
        let powerUp = ActivePowerUp(type: .multiplier, remainingTime: 30.0, multiplier: 2.0)
        activePowerUps.append(powerUp)
        startPowerUpTimer(for: .multiplier, duration: 30.0)
    }
    
    private func useBombPowerUp() {
        // Clear a 3x3 area around a random position
        let centerRow = Int.random(in: 1..<AppConstants.Game.gridSize - 1)
        let centerCol = Int.random(in: 1..<AppConstants.Game.gridSize - 1)
        var clearedSpheres: [Sphere] = []
        
        for row in (centerRow - 1)...(centerRow + 1) {
            for col in (centerCol - 1)...(centerCol + 1) {
                if let sphere = gameBoard[row][col] {
                    clearedSpheres.append(sphere)
                }
            }
        }
        
        processMatches(clearedSpheres, patterns: [])
    }
    
    private func useFreezePowerUp() {
        let powerUp = ActivePowerUp(type: .freeze, remainingTime: 10.0, multiplier: 1.0)
        activePowerUps.append(powerUp)
        startPowerUpTimer(for: .freeze, duration: 10.0)
    }
    
    private func startPowerUpTimer(for type: PowerUpType, duration: Double) {
        powerUpTimers[type] = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.deactivatePowerUp(type)
            }
        }
    }
    
    private func deactivatePowerUp(_ type: PowerUpType) {
        activePowerUps.removeAll { $0.type == type }
        powerUpTimers[type]?.invalidate()
        powerUpTimers[type] = nil
    }
    
    private func applyActivePowerUpEffects(matches: [Sphere]) {
        for powerUp in activePowerUps {
            switch powerUp.type {
            case .multiplier:
                // Score multiplier is applied in processMatches
                break
            case .freeze:
                // Timer is frozen, handled in updateTimer
                break
            default:
                break
            }
        }
    }
    
    private func clearPowerUpTimers() {
        for timer in powerUpTimers.values {
            timer.invalidate()
        }
        powerUpTimers.removeAll()
    }
    
    // MARK: - Game End Conditions
    private func checkGameEndConditions() {
        guard let levelData = currentLevelData else { return }
        
        // Check win condition
        if score >= levelData.targetScore {
            endGame(won: true)
        }
        // Check lose conditions
        else if movesLeft <= 0 || timeRemaining <= 0 {
            endGame(won: false)
        }
    }
    
    private func endGame(won: Bool) {
        gameState = won ? .levelComplete : .gameOver
        stopTimer()
        clearPowerUpTimers()
        
        if won {
            showLevelComplete = true
            currentLevel += 1
            saveProgress()
        } else {
            showGameOver = true
        }
    }
    
    private func saveProgress() {
        Task {
            await dataService.saveGameProgress(
                level: currentLevel,
                score: score,
                playTime: AppConstants.Game.timeLimit - timeRemaining
            )
        }
    }
    
    // MARK: - Level Generation
    private func generateLevel(number: Int) -> GameLevel {
        let difficulty: GameLevel.Difficulty
        switch number {
        case 1...10: difficulty = .easy
        case 11...25: difficulty = .medium
        case 26...40: difficulty = .hard
        default: difficulty = .expert
        }
        
        let targetScore = Int(Double(number * 1000) * difficulty.multiplier)
        let timeLimit = max(30.0, AppConstants.Game.timeLimit - Double(number) * 2.0)
        let maxMoves = max(15, 30 - number / 2)
        
        return GameLevel(
            number: number,
            name: "Level \(number)",
            description: "Complete level \(number) by reaching \(targetScore) points",
            targetScore: targetScore,
            timeLimit: timeLimit,
            maxMoves: maxMoves,
            requiredPatterns: [GamePattern.horizontalLine3, GamePattern.verticalLine3],
            initialSpheres: [],
            powerUpsEnabled: PowerUpType.allCases,
            difficulty: difficulty
        )
    }
}

// MARK: - Supporting Types
enum GameState {
    case menu
    case playing
    case paused
    case levelComplete
    case gameOver
}

struct ActivePowerUp: Identifiable {
    let id = UUID()
    let type: PowerUpType
    var remainingTime: Double
    let multiplier: Double
    
    init(type: PowerUpType, remainingTime: Double, multiplier: Double = 1.0) {
        self.type = type
        self.remainingTime = remainingTime
        self.multiplier = multiplier
    }
}
