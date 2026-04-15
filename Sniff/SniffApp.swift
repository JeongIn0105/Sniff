//
//  SwiftUI.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import FirebaseCore

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

    @State private var appState: AppState = .splash

    // MARK: - Firebase 초기화
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
                            appState = .login
                        }
                    }
                }
        case .login:
            LoginView(
                onNewUser: { appState = .onboardingIntro },      // 신규 사용자 → 온보딩
                onExistingUser: { appState = .main }             // 기존 사용자 → 홈
            )
        case .onboardingIntro:
            OnboardingIntroView {
                appState = .onboarding
            }
        case .onboarding:
            OnboardingContainerView()
        case .main:
            MainTabView()
        }
    }
}
