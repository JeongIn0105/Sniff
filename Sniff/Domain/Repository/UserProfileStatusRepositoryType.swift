//
//  UserProfileStatusRepositoryType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

protocol UserProfileStatusRepositoryType {
    func hasUserProfile(userID: String) async throws -> Bool
}
