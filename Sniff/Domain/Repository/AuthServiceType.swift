//
//  AuthServiceType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

protocol AuthServiceType {
    func signInWithApple(identityToken: Data?, rawNonce: String) async throws -> String
    func signOut() throws
}
