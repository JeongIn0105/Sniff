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
                onNewUser: { appStateManager.state = .onboardingIntro },      // 신규 사용자 → 온보딩
                onExistingUser: { appStateManager.state = .main }             // 기존 사용자 → 홈
            )
        case .onboardingIntro:
            OnboardingIntroView {
                appStateManager.state = .onboarding
            }
        case .onboarding:
            OnboardingContainerView(
                onBack: { appStateManager.state = .onboardingIntro },   // 뒤로 → 온보딩 인트로
                onComplete: { appStateManager.state = .main }           // 완료 → 홈
            )
        case .main:
            MainTabView()
        }
    }
}
