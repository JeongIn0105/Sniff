//
//  AuthService.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import Foundation
import FirebaseAuth

enum AuthServiceError: LocalizedError {
    case missingIdentityToken
    case invalidIdentityToken

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:
            return "Apple 로그인 토큰을 받지 못했어요"
        case .invalidIdentityToken:
            return "Apple 로그인 토큰을 해석하지 못했어요"
        }
    }
}

final class AuthService {

    static let shared = AuthService()

    private init() {}

    func signInWithApple(
        identityToken: Data?,
        rawNonce: String
    ) async throws {
        guard let identityToken else {
            throw AuthServiceError.missingIdentityToken
        }

        guard let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthServiceError.invalidIdentityToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: nil
        )

        _ = try await Auth.auth().signIn(with: credential)
    }
}
