//
//  LoginViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import AuthenticationServices
import UIKit

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authService: AuthServiceType
    private let userProfileStatusRepository: UserProfileStatusRepositoryType
    private let appleSignInHelper: AppleSignInHelper
    private let googleSignInHelper: GoogleSignInHelper
    private let onNewUser: () -> Void
    private let onExistingUser: () -> Void

    init(
        authService: AuthServiceType,
        userProfileStatusRepository: UserProfileStatusRepositoryType,
        appleSignInHelper: AppleSignInHelper,
        googleSignInHelper: GoogleSignInHelper,
        onNewUser: @escaping () -> Void,
        onExistingUser: @escaping () -> Void
    ) {
        self.authService = authService
        self.userProfileStatusRepository = userProfileStatusRepository
        self.appleSignInHelper = appleSignInHelper
        self.googleSignInHelper = googleSignInHelper
        self.onNewUser = onNewUser
        self.onExistingUser = onExistingUser
    }

    // MARK: - Apple 로그인

    func signInWithApple(presentationAnchor: ASPresentationAnchor) {
        isLoading = true
        appleSignInHelper.startSignIn(presentationAnchor: presentationAnchor) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success(let payload):
                    do {
                        let session = try await self.authService.signInWithApple(
                            identityToken: payload.identityToken,
                            rawNonce: payload.rawNonce
                        )
                        await self.handleSessionSuccess(userID: session.userID)
                    } catch {
                        self.handleError(error)
                    }
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    // MARK: - 구글 로그인

    func signInWithGoogle(presentingWindow: UIWindow) {
        isLoading = true
        Task {
            do {
                let payload = try await googleSignInHelper.startSignIn(presentingWindow: presentingWindow)
                let session = try await authService.signInWithGoogle(
                    idToken: payload.idToken,
                    accessToken: payload.accessToken
                )
                await handleSessionSuccess(userID: session.userID)
            } catch let error as GoogleSignInError where error == .canceled {
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }

    // MARK: - Private

    private func handleSessionSuccess(userID: String) async {
        do {
            let hasProfile = try await userProfileStatusRepository.hasUserProfile(userID: userID)
            isLoading = false
            hasProfile ? onExistingUser() : onNewUser()
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
        showError = true
    }
}
