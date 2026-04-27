//
//  AuthServiceType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

struct AuthSession {
    let userID: String
    let isNewUser: Bool
}

protocol AuthServiceType {
    func signInWithApple(identityToken: Data?, rawNonce: String) async throws -> AuthSession
    /// Apple 자격증명으로 현재 사용자를 재인증합니다.
    /// 계정 삭제 등 민감한 작업 전 requiresRecentLogin(17014) 에러 발생 시 호출합니다.
    func reauthenticateWithApple(identityToken: Data?, rawNonce: String) async throws
    func signOut() throws
}
