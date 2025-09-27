//
//  FuturoSphereApp.swift
//  FuturoSpherePlin
//
//  Created by Вячеслав on 9/27/25.
//

import SwiftUI

@main
struct FuturoSphereApp: App {
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}
