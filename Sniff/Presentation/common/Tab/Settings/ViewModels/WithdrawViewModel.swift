//
//  WithdrawViewModel.swift
//  Sniff
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - 회원탈퇴 뷰모델

@MainActor
final class WithdrawViewModel: ObservableObject {

    @Published var isAgreed = false
    @Published var isLoading = false
    @Published var didWithdraw = false
    @Published var errorMessage: String?

    /// 닉네임 (화면 상단 표시용)
    let nickname: String

    private let authService: AuthServiceType
    private let coreDataStack: CoreDataStack

    init(
        nickname: String,
        authService: AuthServiceType,
        coreDataStack: CoreDataStack
    ) {
        self.nickname = nickname
        self.authService = authService
        self.coreDataStack = coreDataStack
    }

    // MARK: - 회원탈퇴 실행: Firestore 삭제 → 로컬 삭제 → 로그아웃

    func withdrawAccount() async {
        guard isAgreed else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // 1단계: 유저 문서 삭제 — 반드시 성공해야 탈퇴 진행
            try await deleteUserDocument()

            // 2단계: 서브컬렉션 삭제 — 실패해도 탈퇴 계속 진행
            await deleteSubcollectionsSilently()

            // 3단계: 기기 내 로컬 Core Data 시향기 데이터 삭제
            try? coreDataStack.deleteAllTastingNotes()

            // 4단계: Firebase 로그아웃 (Apple 재인증 없이 즉시 처리)
            try authService.signOut()

            didWithdraw = true
        } catch {
            errorMessage = AppStrings.ViewModelMessages.Withdraw.failed
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
