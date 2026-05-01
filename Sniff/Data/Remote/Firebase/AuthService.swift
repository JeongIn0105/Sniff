//
//  AuthService.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

enum AuthServiceError: LocalizedError {
    case missingIdentityToken
    case invalidIdentityToken
    case missingCurrentUser

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:  return "Apple 로그인 토큰을 받지 못했어요"
        case .invalidIdentityToken:  return "Apple 로그인 토큰을 해석하지 못했어요"
        case .missingCurrentUser:    return "로그인된 사용자 정보를 찾을 수 없어요"
        }
    }
}

final class AuthService: AuthServiceType {

    static let shared = AuthService()
    private init() {}

    // MARK: - Apple 로그인

    func signInWithApple(identityToken: Data?, rawNonce: String) async throws -> AuthSession {
        let credential = try makeAppleCredential(identityToken: identityToken, rawNonce: rawNonce)
        let result = try await Auth.auth().signIn(with: credential)
        return AuthSession(userID: result.user.uid,
                           isNewUser: result.additionalUserInfo?.isNewUser ?? false)
    }

    func reauthenticateWithApple(identityToken: Data?, rawNonce: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthServiceError.missingCurrentUser
        }
        let credential = try makeAppleCredential(identityToken: identityToken, rawNonce: rawNonce)
        try await currentUser.reauthenticate(with: credential)
    }

    // MARK: - 구글 로그인

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> AuthSession {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
        let result = try await Auth.auth().signIn(with: credential)
        return AuthSession(userID: result.user.uid,
                           isNewUser: result.additionalUserInfo?.isNewUser ?? false)
    }

    // MARK: - 로그아웃

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    // MARK: - Private

    private func makeAppleCredential(identityToken: Data?, rawNonce: String) throws -> OAuthCredential {
        guard let identityToken else { throw AuthServiceError.missingIdentityToken }
        guard let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthServiceError.invalidIdentityToken
        }
        return OAuthProvider.appleCredential(withIDToken: idTokenString,
                                             rawNonce: rawNonce,
                                             fullName: nil)
    }
}
