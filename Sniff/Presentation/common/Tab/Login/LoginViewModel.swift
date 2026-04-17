//
//  LoginViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import AuthenticationServices
import CryptoKit
import Security
import Combine

@MainActor
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

    private func processAppleLoginResult(
        _ result: Result<ASAuthorization, Error>,
        onSuccess: @escaping () -> Void
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let authorization = try result.get()

            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce
            else {
                throw AuthServiceError.missingIdentityToken
            }

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

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Nonce 생성에 실패했어요. OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if Int(random) < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
