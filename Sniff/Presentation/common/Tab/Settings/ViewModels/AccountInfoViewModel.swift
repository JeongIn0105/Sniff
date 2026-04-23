//
//  AccountInfoViewModel.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AccountInfoViewModel: ObservableObject {

    // MARK: - Published Properties

    /// WithdrawView 에 전달할 닉네임
    @Published private(set) var nickname: String = "사용자"
    @Published private(set) var email: String?

    // MARK: - Dependencies

    private let firestoreService: FirestoreService

    // MARK: - Init

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
        email = Auth.auth().currentUser?.email
        // 닉네임 비동기 로드 (화면 전환 후 표시되면 충분)
        Task { await loadNickname() }
    }
}

// MARK: - Private

private extension AccountInfoViewModel {

    /// Firestore에서 닉네임 로드, 실패 시 이메일 앞부분으로 대체
    func loadNickname() async {
        do {
            let user = try await firestoreService.fetchUserProfile()
            nickname = user.nickname
            email = user.email ?? Auth.auth().currentUser?.email
        } catch {
            // Firestore 로드 실패 시 Auth 이메일 앞부분 사용
            if let email = Auth.auth().currentUser?.email {
                nickname = email.split(separator: "@").first.map(String.init) ?? "사용자"
            }
        }
    }
}
