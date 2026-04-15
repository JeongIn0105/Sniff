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
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    // MARK: - 콜백
    private let onNewUser: () -> Void
    private let onExistingUser: () -> Void
    
    private let appleSignInHelper = AppleSignInHelper()
    private let db = Firestore.firestore()
    
    init(onNewUser: @escaping () -> Void,
         onExistingUser: @escaping () -> Void) {
        self.onNewUser = onNewUser
        self.onExistingUser = onExistingUser
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
