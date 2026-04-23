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
    @State private var didResolveInitialRoute = false
    private let dependencyContainer = AppDependencyContainer.shared

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
                    guard !didResolveInitialRoute else { return }
                    didResolveInitialRoute = true

                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        let nextState = await resolveInitialState()
                        await MainActor.run {
                            withAnimation(.easeInOut) {
                                appStateManager.state = nextState
                            }
                        }
                    }
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

    private func resolveInitialState() async -> AppState {
        guard let userID = Auth.auth().currentUser?.uid else {
            return .login
        }

        do {
            let hasProfile = try await dependencyContainer
                .makeUserProfileStatusRepository()
                .hasUserProfile(userID: userID)
            return hasProfile ? .main : .onboardingIntro
        } catch {
            return .login
        }
    }
}
