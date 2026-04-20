//
//  WithdrawViewModel.swift
//  Sniff
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - 회원탈퇴 뷰모델

@MainActor
final class WithdrawViewModel: ObservableObject {

    @Published var isAgreed = false
    @Published var isLoading = false
    @Published var didWithdraw = false
    @Published var errorMessage: String?

    /// 닉네임 (화면 상단 표시용)
    let nickname: String

    init(nickname: String) {
        self.nickname = nickname
    }

    // MARK: - 회원탈퇴 실행: Firestore 삭제 → Auth 삭제

    func withdrawAccount() async {
        guard isAgreed else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1단계: 유저 문서 삭제 (닉네임 포함) — 반드시 성공해야 탈퇴 진행
            try await deleteUserDocument()

            // 2단계: 서브컬렉션 삭제 — 실패해도 탈퇴 계속 진행
            await deleteSubcollectionsSilently()

            // 3단계: Firebase Auth 계정 삭제
            try await Auth.auth().currentUser?.delete()
            didWithdraw = true
        } catch {
            let code = (error as NSError).code
            // 17014: requiresRecentLogin — Apple 로그인 재인증 필요
            if code == 17014 {
                errorMessage = "보안을 위해 로그아웃 후 다시 로그인한 뒤 탈퇴를 진행해주세요."
            } else {
                errorMessage = "탈퇴 처리 중 오류가 발생했어요. 다시 시도해주세요."
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Firestore 삭제

private extension WithdrawViewModel {

    /// 유저 문서 삭제 — 닉네임이 담긴 핵심 문서이므로 반드시 성공해야 함
    func deleteUserDocument() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreServiceError.missingAuthenticatedUser
        }
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .delete()
    }

    /// 서브컬렉션 삭제 — 실패해도 탈퇴 흐름에 영향 없음
    func deleteSubcollectionsSilently() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        for subcollection in ["collection", "likes", "tastingRecords"] {
            guard let snapshot = try? await userRef.collection(subcollection).getDocuments() else { continue }
            guard !snapshot.documents.isEmpty else { continue }
            let batch = db.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try? await batch.commit()
        }
    }
}
