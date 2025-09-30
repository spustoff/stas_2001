//
//  OnboardingView.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    @State private var currentStep = 0
    @State private var animateElements = false
    @State private var demoSpheres: [DemoSphere] = []
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppConstants.Colors.darkBackground, AppConstants.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background spheres
            ForEach(demoSpheres, id: \.id) { sphere in
                Circle()
                    .fill(sphere.color.opacity(0.3))
                    .frame(width: sphere.size, height: sphere.size)
                    .position(sphere.position)
                    .blur(radius: 2)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true),
                        value: animateElements
                    )
            }
            
            VStack(spacing: AppConstants.Dimensions.largePadding) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? AppConstants.Colors.accentCyan : AppConstants.Colors.textSecondary.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(AppConstants.Animations.bounceAnimation, value: currentStep)
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case 0:
                        WelcomeStepView()
                    case 1:
                        GameMechanicsStepView()
                    case 2:
                        PowerUpsStepView()
                    case 3:
                        FinalStepView()
                    default:
                        WelcomeStepView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: AppConstants.Dimensions.standardPadding) {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(AppConstants.Animations.bounceAnimation) {
                                currentStep -= 1
                            }
                        }
                        .futuristicButton(color: AppConstants.Colors.textSecondary.opacity(0.3))
                    }
                    
                    Spacer()
                    
                    Button(currentStep == totalSteps - 1 ? "Start Playing" : "Next") {
                        withAnimation(AppConstants.Animations.bounceAnimation) {
                            if currentStep == totalSteps - 1 {
                                onboardingCompleted = true
                            } else {
                                currentStep += 1
                            }
                        }
                    }
                    .futuristicButton(color: AppConstants.Colors.primaryBlue)
                }
                .padding(.horizontal, AppConstants.Dimensions.largePadding)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupBackgroundSpheres()
            withAnimation(Animation.easeInOut(duration: AppConstants.Animations.slowDuration)) {
                animateElements = true
            }
        }
    }
    
    private func setupBackgroundSpheres() {
        demoSpheres = (0..<8).map { _ in
            DemoSphere(
                id: UUID(),
                color: AppConstants.Colors.sphereColors.randomElement() ?? AppConstants.Colors.accentCyan,
                size: CGFloat.random(in: 40...120),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                )
            )
        }
    }
}

// MARK: - Onboarding Steps

struct WelcomeStepView: View {
    @State private var logoScale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.largePadding) {
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(AppConstants.Colors.primaryBlue)
                    .frame(width: 120, height: 120)
                    .glowEffect(color: AppConstants.Colors.primaryBlue, radius: 8)
                
                Image(systemName: "sphere.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppConstants.Colors.textPrimary)
            }
            .scaleEffect(logoScale)
            .onAppear {
                withAnimation(AppConstants.Animations.pulseAnimation) {
                    logoScale = 1.0
                }
            }
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                
                Text("FuturoSpherePlin")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                    .glowEffect(color: AppConstants.Colors.accentCyan, radius: 2)
                
                Text("A captivating puzzle game where you manipulate futuristic spheres to create amazing patterns and solve challenging levels.")
                    .font(.body)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.Dimensions.standardPadding)
            }
        }
    }
}

struct GameMechanicsStepView: View {
    @State private var demoSphereOffset: CGFloat = 0
    @State private var showPattern = false
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.largePadding) {
            Text("How to Play")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppConstants.Colors.textPrimary)
            
            // Interactive demo
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppConstants.Colors.sphereColors[index])
                            .frame(width: AppConstants.Dimensions.sphereSize)
                            .offset(y: index == 1 ? demoSphereOffset : 0)
                            .glowEffect(color: AppConstants.Colors.sphereColors[index], radius: 4)
                    }
                }
                
                if showPattern {
                    Text("Pattern Matched!")
                        .font(.headline)
                        .foregroundColor(AppConstants.Colors.neonGreen)
                        .glowEffect(color: AppConstants.Colors.neonGreen, radius: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(AppConstants.Dimensions.largePadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                    .fill(AppConstants.Colors.cardBackground.opacity(0.5))
            )
            
            VStack(spacing: 12) {
                Text("• Tap and drag spheres to move them")
                Text("• Align spheres to create patterns")
                Text("• Clear levels by matching all patterns")
                Text("• Think fast - time is limited!")
            }
            .font(.body)
            .foregroundColor(AppConstants.Colors.textSecondary)
            .multilineTextAlignment(.leading)
        }
        .onAppear {
            startDemo()
        }
    }
    
    private func startDemo() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(AppConstants.Animations.bounceAnimation) {
                demoSphereOffset = demoSphereOffset == 0 ? -20 : 0
                showPattern.toggle()
            }
        }
    }
}

struct PowerUpsStepView: View {
    @State private var selectedPowerUp = 0
    
    private let powerUps = [
        ("bolt.fill", "Lightning", "Instantly clear a row", AppConstants.Colors.neonGreen),
        ("wand.and.stars", "Transform", "Change sphere colors", AppConstants.Colors.purpleGlow),
        ("timer", "Time Boost", "Add extra seconds", AppConstants.Colors.accentCyan),
        ("sparkles", "Multiplier", "Double your score", AppConstants.Colors.sphereColors[3])
    ]
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.largePadding) {
            Text("Power-Ups")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppConstants.Colors.textPrimary)
            
            // Power-up showcase
            TabView(selection: $selectedPowerUp) {
                ForEach(0..<powerUps.count, id: \.self) { index in
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(powerUps[index].3)
                                .frame(width: 80, height: 80)
                                .glowEffect(color: powerUps[index].3, radius: 6)
                            
                            Image(systemName: powerUps[index].0)
                                .font(.system(size: 40))
                                .foregroundColor(AppConstants.Colors.textPrimary)
                        }
                        
                        Text(powerUps[index].1)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Text(powerUps[index].2)
                            .font(.body)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 200)
            
            Text("Collect power-ups during gameplay to gain special abilities and boost")
                .font(.body)
                .foregroundColor(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.Dimensions.standardPadding)
        }
    }
}

struct FinalStepView: View {
    @State private var celebrationScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: AppConstants.Dimensions.largePadding) {
            // Celebration animation
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(AppConstants.Colors.sphereColors[index])
                        .frame(width: 30, height: 30)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * 60,
                            y: sin(Double(index) * .pi / 3) * 60
                        )
                        .scaleEffect(celebrationScale)
                        .glowEffect(color: AppConstants.Colors.sphereColors[index], radius: 3)
                }
                
                Text("🎮")
                    .font(.system(size: 60))
            }
            .onAppear {
                withAnimation(AppConstants.Animations.pulseAnimation) {
                    celebrationScale = 1.2
                }
            }
            
            VStack(spacing: 16) {
                Text("Ready to Play!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                    .glowEffect(color: AppConstants.Colors.accentCyan, radius: 2)
                
                Text("You're all set to begin your journey through the futuristic world.")
                    .font(.body)
                    .foregroundColor(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.Dimensions.standardPadding)
                
                VStack(spacing: 8) {
                    Text("• 50 challenging levels await")
                    Text("• Compete on global leaderboards")
                    Text("• Unlock achievements and rewards")
                    Text("• Customize your gaming experience")
                }
                .font(.body)
                .foregroundColor(AppConstants.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Supporting Models

struct DemoSphere {
    let id: UUID
    let color: Color
    let size: CGFloat
    let position: CGPoint
}

#Preview {
    OnboardingView()
}
