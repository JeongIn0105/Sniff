//
//  LoginViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import AuthenticationServices

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authService: AuthServiceType
    private let userProfileStatusRepository: UserProfileStatusRepositoryType
    private let appleSignInHelper: AppleSignInHelper
    private let onNewUser: () -> Void
    private let onExistingUser: () -> Void

    init(
        authService: AuthServiceType,
        userProfileStatusRepository: UserProfileStatusRepositoryType,
        appleSignInHelper: AppleSignInHelper,
        onNewUser: @escaping () -> Void,
        onExistingUser: @escaping () -> Void
    ) {
        self.authService = authService
        self.userProfileStatusRepository = userProfileStatusRepository
        self.appleSignInHelper = appleSignInHelper
        self.onNewUser = onNewUser
        self.onExistingUser = onExistingUser
    }

    func signInWithApple(presentationAnchor: ASPresentationAnchor) {
        isLoading = true

        appleSignInHelper.startSignIn(presentationAnchor: presentationAnchor) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let payload):
                    await self.handleSignInSuccess(payload: payload)
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    private func handleSignInSuccess(payload: AppleSignInPayload) async {
        do {
            let session = try await authService.signInWithApple(
                identityToken: payload.identityToken,
                rawNonce: payload.rawNonce
            )
            isLoading = false
            let hasProfile = try await userProfileStatusRepository.hasUserProfile(userID: session.userID)
            if hasProfile || !session.isNewUser {
                onExistingUser()
            } else {
                onNewUser()
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
