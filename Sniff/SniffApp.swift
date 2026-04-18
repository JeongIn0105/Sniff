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
            LoginSceneFactory.makeView(
                onNewUser: { appState = .onboardingIntro },
                onExistingUser: { appState = .main }
            )
        case .onboardingIntro:
            OnboardingIntroView {
                appState = .onboarding
            }
        case .onboarding:
            OnboardingSceneFactory.makeView(
                onBack: { appState = .onboardingIntro },
                onComplete: { appState = .main }
            )
        case .main:
            MainTabView()
        }
    }
}
