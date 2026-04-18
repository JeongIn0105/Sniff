//
//  AppleSignInHelper.swift
//  Sniff
//
//  Created by 이정인 on 4/14/26.
//

import AuthenticationServices
import CryptoKit

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
            SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
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
           authError.code == .canceled { return }
        onCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return ASPresentationAnchor() }
        return window
    }
}

// MARK: - 커스텀 에러
enum AuthError: LocalizedError {
    case invalidCredential
    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "인증 정보를 처리할 수 없습니다."
        }
    }
}
