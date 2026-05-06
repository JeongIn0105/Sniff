//
//  AppleSignInHelper.swift
//  Sniff
//
//  Created by 이정인 on 4/14/26.
//

import AuthenticationServices
import CryptoKit
import Security

struct AppleSignInPayload {
    let identityToken: Data
    let rawNonce: String
}

// MARK: - Apple 로그인 헬퍼
final class AppleSignInHelper: NSObject {
    
    private(set) var currentNonce: String?
    var onCompletion: ((Result<AppleSignInPayload, Error>) -> Void)?
    
    // MARK: - Nonce 생성
    func generateNonce() -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = 32
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else {
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - 로그인 요청
    func startSignIn(presentationAnchor: ASPresentationAnchor,
                     completion: @escaping (Result<AppleSignInPayload, Error>) -> Void) {
        let nonce = generateNonce()
        currentNonce = nonce
        onCompletion = completion
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken
        else {
            onCompletion?(.failure(AuthError.invalidCredential))
            return
        }

        onCompletion?(.success(AppleSignInPayload(identityToken: appleIDToken, rawNonce: nonce)))
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            onCompletion?(.failure(AuthError.canceled))
            return
        }
        onCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let keyWindow = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) {
            return keyWindow
        }

        return scenes
            .flatMap(\.windows)
            .first ?? ASPresentationAnchor()
    }
}

// MARK: - 커스텀 에러
enum AuthError: LocalizedError, Equatable {
    case invalidCredential
    case canceled

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return AppStrings.AppShell.Login.invalidCredential
        case .canceled: return nil
        }
    }
}
