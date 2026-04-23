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
    func signOut() throws
}
