//
//  SwiftUI.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
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
    private let dependencyContainer = AppDependencyContainer.shared

    // MARK: - Firebase 초기화
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            contentView
                .environmentObject(appStateManager)
                .task {
                    appStateManager.startObservingAuth(
                        userProfileStatusRepository: dependencyContainer.makeUserProfileStatusRepository()
                    )
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch appStateManager.state {
        case .splash:
            SplashView()
                // .task modifier 사용 → View 소멸 시 Task가 자동으로 취소됩니다.
                .task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await appStateManager.completeSplash()
                }
        case .login:
            LoginSceneFactory.makeView(
                onNewUser: { appStateManager.state = .onboardingIntro },
                onExistingUser: { appStateManager.state = .main }
            )
        case .onboardingIntro:
            OnboardingIntroView {
                appStateManager.state = .onboarding
            }
        case .onboarding:
            OnboardingSceneFactory.makeView(
                onBack: { appStateManager.state = .onboardingIntro },
                onComplete: { appStateManager.state = .main }
            )
        case .main:
            MainTabView()
        }
    }
}
