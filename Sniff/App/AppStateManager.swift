//
//  AppStateManager.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AppStateManager: ObservableObject {
    @Published var state: AppState = .splash

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var hasCompletedSplash = false
    private var userProfileStatusRepository: UserProfileStatusRepositoryType?

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    func startObservingAuth(userProfileStatusRepository: UserProfileStatusRepositoryType) {
        self.userProfileStatusRepository = userProfileStatusRepository

        guard authStateListenerHandle == nil else { return }

        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            guard self.hasCompletedSplash else { return }

            Task { @MainActor in
                self.state = await self.resolveState(for: user?.uid)
            }
        }
    }

    func completeSplash() async {
        hasCompletedSplash = true
        let resolvedState = await resolveState(for: Auth.auth().currentUser?.uid)
        state = resolvedState
    }

    private func resolveState(for userID: String?) async -> AppState {
        guard let userID else { return .login }
        guard let userProfileStatusRepository else { return .login }

        do {
            let hasProfile = try await userProfileStatusRepository.hasUserProfile(userID: userID)
            return hasProfile ? .main : .onboardingIntro
        } catch {
            return .login
        }
    }
}
