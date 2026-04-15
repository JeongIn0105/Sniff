//
//  SwiftUI.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

private enum AppStorageKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

enum AppState {
    case splash
    case login
    case onboardingIntro
    case onboarding
    case main
}

@main
struct SniffApp: App {

    @State private var appState: AppState = .splash

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch appState {
        case .splash:
            SplashView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut) {
                            appState = initialAppState()
                        }
                    }
                }
        case .login:
            LoginView {
                appState = UserDefaults.standard.bool(forKey: AppStorageKey.hasCompletedOnboarding)
                    ? .main
                    : .onboardingIntro
            }
        case .onboardingIntro:
            OnboardingIntroView {
                appState = .onboarding
            }
        case .onboarding:
            OnboardingContainerView(onBack: {
                appState = .onboardingIntro
            }, onComplete: {
                UserDefaults.standard.set(true, forKey: AppStorageKey.hasCompletedOnboarding)
                appState = .main
            })
        case .main:
            MainTabView()
        }
    }

    private func initialAppState() -> AppState {
        guard Auth.auth().currentUser != nil else {
            return .login
        }

        return UserDefaults.standard.bool(forKey: AppStorageKey.hasCompletedOnboarding)
            ? .main
            : .onboardingIntro
    }
}
