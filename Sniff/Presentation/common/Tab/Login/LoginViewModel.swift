//
//  LoginViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import AuthenticationServices
import CryptoKit
import Security
import Combine
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
// MARK: - 로그인 ViewModel
final class LoginViewModel: ObservableObject {

    // DEBUG 임시 우회:
    // Apple 로그인(Error 1000 등) 이슈가 있을 때도 홈/온보딩 흐름을 확인할 수 있도록,
    // 디버그 빌드에서만 로그인 실패 시 다음 화면으로 진입하게 해둡니다.
    // 실제 로그인 연동이 안정화되면 false 로 바꾸거나 제거하세요.
    private let shouldBypassAppleLoginFailureInDebug = true

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private var currentNonce: String?

    init(authService: AuthService? = nil) {
        self.authService = authService ?? .shared
    }

    func prepareAppleLoginRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleLoginResult(
        _ result: Result<ASAuthorization, Error>,
        onSuccess: @escaping () -> Void
    ) {
        Task {
            await processAppleLoginResult(result, onSuccess: onSuccess)
        }
    }
    
    // MARK: - Apple 로그인
    @MainActor
    func signInWithApple(presentationAnchor: ASPresentationAnchor) {
        isLoading = true
        appleSignInHelper.startSignIn(presentationAnchor: presentationAnchor) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                switch result {
                case .success(let authResult):
                    await self.handleSignInSuccess(authResult: authResult)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
do {
    try await authService.signInWithApple(
        identityToken: appleIDCredential.identityToken,
        rawNonce: nonce
    )

    errorMessage = nil
    onSuccess()
} catch {
#if DEBUG
    if shouldBypassAppleLoginFailureInDebug {
        try? await authService.signInAnonymouslyForDebug()
        errorMessage = "DEBUG 임시 우회: Apple 로그인 실패를 건너뛰고 다음 화면으로 이동합니다."
        onSuccess()
        return
    }
#endif
    errorMessage = error.localizedDescription
}
        }
    }
    
    // MARK: - 신규/기존 사용자 분기
    @MainActor
    private func handleSignInSuccess(authResult: AuthDataResult) async {
        let uid = authResult.user.uid
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                onExistingUser()  // 기존 사용자 → 홈
            } else {
                onNewUser()       // 신규 사용자 → 닉네임
            }
        } catch {
            onNewUser()
        }
    }
}
