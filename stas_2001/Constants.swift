//
//  Constants.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

struct AppConstants {
    // MARK: - Colors
    struct Colors {
        // Futuristic color scheme
        static let primaryBlue = Color(red: 0.0, green: 0.4, blue: 0.8)
        static let secondaryBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let accentCyan = Color(red: 0.0, green: 0.8, blue: 0.9)
        static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.5)
        static let purpleGlow = Color(red: 0.6, green: 0.2, blue: 1.0)
        static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
        static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.9)
        
        // Game-specific colors
        static let sphereColors = [
            Color(red: 0.0, green: 0.8, blue: 0.9),   // Cyan
            Color(red: 0.0, green: 1.0, blue: 0.5),   // Neon Green
            Color(red: 0.6, green: 0.2, blue: 1.0),   // Purple
            Color(red: 1.0, green: 0.3, blue: 0.0),   // Orange
            Color(red: 1.0, green: 0.8, blue: 0.0),   // Yellow
            Color(red: 1.0, green: 0.0, blue: 0.5)    // Pink
        ]
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let standardPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
        static let sphereSize: CGFloat = 60
        static let buttonHeight: CGFloat = 50
    }
    
    // MARK: - Animations
    struct Animations {
        static let standardDuration: Double = 0.3
        static let slowDuration: Double = 0.6
        static let fastDuration: Double = 0.15
        static let bounceAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let pulseAnimation = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }
    
    // MARK: - Game Settings
    struct Game {
        static let maxLevels = 50
        static let sphereTypes = 6
        static let gridSize = 8
        static let timeLimit = 60.0
        static let scoreMultiplier = 100
    }
}

// MARK: - Custom View Modifiers
struct FuturisticButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppConstants.Colors.textPrimary)
            .frame(height: AppConstants.Dimensions.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Dimensions.cornerRadius)
                    .fill(color)
                    .shadow(color: color.opacity(0.5), radius: AppConstants.Dimensions.shadowRadius)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppConstants.Animations.bounceAnimation, value: configuration.isPressed)
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
}

extension View {
    func futuristicButton(color: Color = AppConstants.Colors.primaryBlue) -> some View {
        self.buttonStyle(FuturisticButtonStyle(color: color))
    }
    
    func glowEffect(color: Color, radius: CGFloat = 4) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }
}
