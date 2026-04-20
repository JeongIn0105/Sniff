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

// MARK: - 시향 기록 필터 타입

enum TastingNoteFilter: Equatable {
    case all
    case owned  // 보유 향수
    case liked  // LIKE 향수
}

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

    /// 현재 선택된 필터
    @Published private(set) var selectedFilter: TastingNoteFilter = .all

    // MARK: - 필터 키 캐시 (보유/LIKE 향수 브랜드|이름 소문자 Set)

    private var ownedKeys: Set<String> = []
    private var likedKeys: Set<String> = []

    // MARK: - Computed

    /// 필터 적용 후 표시할 시향 기록 목록
    var filteredNotes: [TastingNote] {
        switch selectedFilter {
        case .all:
            return notes
        case .owned:
            return notes.filter { ownedKeys.contains(noteKey($0)) }
        case .liked:
            return notes.filter { likedKeys.contains(noteKey($0)) }
        }
    }

    /// 전체 목록이 비어있는지 (삭제 버튼 활성화 기준)
    var isEmpty: Bool { notes.isEmpty }

    /// 필터 적용 후 결과가 없는지 (빈 상태 뷰 표시 기준)
    var isFilteredEmpty: Bool { filteredNotes.isEmpty }

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
                    // 권한 오류 등 리스너 에러는 조용히 무시하고 단발성 조회로 대체
                    Task { await self.reload() }
                    return
                }
                let decoded = snapshot?.documents.compactMap {
                    try? $0.data(as: TastingNote.self)
                } ?? []
                self.notes = decoded
            }
    }

    // MARK: - 단발성 새로고침 (폼 닫힐 때, 리스너 실패 시 fallback)

    func reload() async {
        guard let ref = collectionRef else { return }
        do {
            let snapshot = try await ref
                .order(by: "createdAt", descending: true)
                .getDocuments()
            notes = snapshot.documents.compactMap { try? $0.data(as: TastingNote.self) }
        } catch {
            errorMessage = error.localizedDescription
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

    // MARK: - 필터 선택 / 해제

    /// 동일 필터를 다시 탭하면 전체(.all)로 해제, 다른 필터 탭하면 해당 필터로 전환
    func selectFilter(_ filter: TastingNoteFilter) {
        if selectedFilter == filter {
            selectedFilter = .all
        } else {
            selectedFilter = filter
            Task { await loadFilterKeys() }
        }
    }

    // MARK: - 필터 키 로딩 (보유/LIKE 향수 → 브랜드|이름 소문자 Set)

    private func loadFilterKeys() async {
        do {
            async let ownedFetch = FirestoreService.shared.fetchCollection()
            async let likedFetch = FirestoreService.shared.fetchLikedPerfumes()
            let (owned, liked) = try await (ownedFetch, likedFetch)
            ownedKeys = Set(owned.map { "\($0.brand.lowercased())|\($0.name.lowercased())" })
            likedKeys = Set(liked.map { "\($0.brand.lowercased())|\($0.name.lowercased())" })
        } catch {
            // 로딩 실패 시 빈 Set 유지 (필터 결과 없음으로 표시)
            ownedKeys = []
            likedKeys = []
        }
    }

    // MARK: - 시향 기록 키 생성 (브랜드|이름 소문자)

    private func noteKey(_ note: TastingNote) -> String {
        "\(note.brandName.lowercased())|\(note.perfumeName.lowercased())"
    }
}
