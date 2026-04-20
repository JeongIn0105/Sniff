//
//  UserProfileStatusRepository.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import FirebaseFirestore

final class UserProfileStatusRepository: UserProfileStatusRepositoryType {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func hasUserProfile(userID: String) async throws -> Bool {
        let document = try await database.collection("users").document(userID).getDocument()
        return document.exists
    }
}
