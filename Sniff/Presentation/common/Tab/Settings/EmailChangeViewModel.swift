//
//  EmailChangeViewModel.swift
//  Sniff

import Foundation
import Combine
import FirebaseAuth

// MARK: - 이메일 변경 뷰모델
// Firebase Auth의 verifyAndChangeEmail OOB 방식은 Naver 등 일부 메일 서비스의
// 링크 보안 스캐너가 OOB 코드를 즉시 소진시켜 동작하지 않음.
// 연락 이메일은 보안 인증용이 아닌 순수 연락용이므로 Firestore에 직접 저장한다.

@MainActor
final class EmailChangeViewModel: ObservableObject {

    @Published var newEmail: String = ""
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?
    @Published private(set) var currentEmail: String = "정보 없음"

    private let firestoreService = FirestoreService.shared

    init() {
        // Firebase Auth 이메일로 초기값 설정 (Firestore 로드는 task에서 처리)
        currentEmail = Auth.auth().currentUser?.email ?? "정보 없음"
    }

    private var normalizedNewEmail: String {
        newEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// 새 이메일 형식 유효성 검사
    var isEmailValid: Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        guard normalizedNewEmail.range(of: pattern, options: .regularExpression) != nil else { return false }
        // 현재 이메일과 동일하면 비활성화
        guard normalizedNewEmail != currentEmail.lowercased() else { return false }
        return true
    }

    // MARK: - 현재 연락 이메일 로드

    /// Firestore에서 연락 이메일을 불러온다.
    func loadCurrentEmail() async {
        do {
            currentEmail = try await firestoreService.fetchContactEmail() ?? "정보 없음"
        } catch {
            // 실패 시 Firebase Auth 이메일로 폴백
            currentEmail = Auth.auth().currentUser?.email ?? "정보 없음"
        }
    }

    // MARK: - 연락 이메일 변경

    /// 새 연락 이메일을 Firestore에 직접 저장한다.
    func saveContactEmail() async {
        guard !isLoading else { return }

        guard isEmailValid else {
            if normalizedNewEmail == currentEmail.lowercased() {
                errorMessage = "현재 이메일과 동일합니다."
            } else {
                errorMessage = "올바른 이메일 주소를 입력해주세요."
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await firestoreService.updateContactEmail(normalizedNewEmail)
            currentEmail = normalizedNewEmail
            newEmail = ""
            showSuccessAlert = true
        } catch {
            // 디버그용: 실제 에러 메시지 출력
            print("❌ [EmailChange] Firestore 저장 실패: \(error)")
            errorMessage = "이메일 변경에 실패했습니다.\n잠시 후 다시 시도해주세요."
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
