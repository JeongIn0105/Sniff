//
//  SwiftUI.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {}

// MARK: - 앱 상태
enum AppState {
    case splash
    case login
    case onboardingIntro
    case onboarding
    case main
}

@main
struct SniffApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appStateManager = AppStateManager()

    // MARK: - Firebase 초기화
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            contentView
                .environmentObject(appStateManager)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch appStateManager.state {
        case .splash:
            SplashView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut) {
                            appStateManager.state = .login
                        }
                    }
                }
        case .login:
                LoginView(
                    onNewUser: { appStateManager.state = .onboardingIntro },
                    onExistingUser: { appStateManager.state = .main }
            )
        case .onboardingIntro:
            OnboardingIntroView {
                appStateManager.state = .onboarding
            }
        case .onboarding:
                OnboardingContainerView(
                    onBack: { appStateManager.state = .onboardingIntro },
                    onComplete: { appStateManager.state = .main }
            )
        case .main:
            MainTabView()
        }
    }
}
