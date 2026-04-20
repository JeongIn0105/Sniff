//
//  LoginViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import AuthenticationServices
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
    @Published var showError = false

    // MARK: - Private

    private let authService: AuthService
    private let appleSignInHelper = AppleSignInHelper()
    private let db = Firestore.firestore()

    private let onNewUser: () -> Void
    private let onExistingUser: () -> Void

    // MARK: - Init

    init(
        onNewUser: @escaping () -> Void,
        onExistingUser: @escaping () -> Void,
        authService: AuthService? = nil
    ) {
        self.onNewUser = onNewUser
        self.onExistingUser = onExistingUser
        self.authService = authService ?? .shared
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
#if DEBUG
                    if self.shouldBypassAppleLoginFailureInDebug {
                        try? await self.authService.signInAnonymouslyForDebug()
                        self.errorMessage = "DEBUG 임시 우회: Apple 로그인 실패를 건너뛰고 다음 화면으로 이동합니다."
                        self.showError = true
                        await self.handleSignInSuccessAnonymous()
                        return
                    }
#endif
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    // MARK: - 신규 / 기존 사용자 분기

    @MainActor
    private func handleSignInSuccess(authResult: AuthDataResult) async {
        let uid = authResult.user.uid
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                onExistingUser()    // 기존 사용자 → 홈
            } else {
                onNewUser()         // 신규 사용자 → 닉네임
            }
        } catch {
            // Firestore 조회 실패 시 안전하게 신규 사용자 플로우로
            onNewUser()
        }
    }

    @MainActor
    private func handleSignInSuccessAnonymous() async {
        // DEBUG 우회: 익명 로그인 성공 시 신규 사용자로 처리
        onNewUser()
    }
}
