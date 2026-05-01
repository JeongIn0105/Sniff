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
import GoogleSignIn

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    /// 구글 로그인의 OAuth 리다이렉트 URL을 처리합니다.
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - 앱 상태

enum AppState {
    case splash
    case login
    case onboardingIntro
    case onboarding
    case main
}

// MARK: - SniffApp

@main
struct SniffApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appStateManager = AppStateManager()
    private let dependencyContainer = AppDependencyContainer.shared

    init() {
        FirebaseApp.configure()
        // Google Sign-In Client ID 설정
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
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
