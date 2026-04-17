//
//  TastingNoteViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

// MARK: - 목록 로직 + Firestore 연동
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
 
// MARK: - 시향 기록 목록 뷰모델
 
@MainActor
final class TastingNoteViewModel: ObservableObject {
 
    // MARK: - Published
 
    @Published private(set) var notes: [TastingNote] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
 
    @Published var showDeleteAlert: Bool = false
    @Published var noteToDelete: TastingNote?
    @Published var isDeleteMode: Bool = false
    @Published var showFormSheet: Bool = false
    @Published var toastMessage: String?
 
    // MARK: - Computed
 
    var isEmpty: Bool { notes.isEmpty }
 
    private var uid: String? { Auth.auth().currentUser?.uid }
 
    private var collectionRef: CollectionReference? {
        guard let uid else { return nil }
        return Firestore.firestore()
            .collection("users").document(uid)
            .collection("tastingRecords")
    }
 
    // MARK: - Private
 
    private var listenerRegistration: ListenerRegistration?
    private var toastTask: Task<Void, Never>?
 
    // MARK: - Init / Deinit
 
    init() { fetchNotes() }
 
    deinit {
        listenerRegistration?.remove()
        toastTask?.cancel()
    }
 
    // MARK: - 목록 실시간 조회
 
    func fetchNotes() {
        guard let ref = collectionRef else { return }
        isLoading = true
 
        listenerRegistration = ref
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.notes = snapshot?.documents.compactMap {
                    try? $0.data(as: TastingNote.self)
                } ?? []
            }
    }
 
    // MARK: - 삭제 (목록 → 확인 얼럿)
 
    func requestDelete(_ note: TastingNote) {
        noteToDelete = note
        showDeleteAlert = true
    }
 
    func confirmDelete() async {
        guard let note = noteToDelete, let id = note.id,
              let ref = collectionRef else { return }
        do {
            try await ref.document(id).delete()
            noteToDelete = nil
            isDeleteMode = false
        } catch {
            errorMessage = "삭제 중 오류가 발생했어요"
        }
    }
 
    // MARK: - 삭제 (상세 화면에서 직접)
 
    func deleteNote(_ note: TastingNote) async {
        guard let id = note.id, let ref = collectionRef else { return }
        do {
            try await ref.document(id).delete()
        } catch {
            errorMessage = "삭제 중 오류가 발생했어요"
        }
    }
 
    // MARK: - 삭제 모드 토글
 
    func toggleDeleteMode() { isDeleteMode.toggle() }
 
    // MARK: - 저장 완료 토스트
 
    func showToast(perfumeName: String) {
        toastMessage = "\(perfumeName) 시향기가 등록되었습니다"
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }
 
    func clearError() { errorMessage = nil }
}
