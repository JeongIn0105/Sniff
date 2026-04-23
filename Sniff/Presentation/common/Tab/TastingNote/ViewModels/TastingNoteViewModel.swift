//
//  TastingNoteViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

// MARK: - 목록 로직 + Firestore 연동
import Foundation
import FirebaseAuth
import Combine

// MARK: - 시향 기록 필터 타입

enum TastingNoteFilter: Equatable {
    case all
    case owned  // 보유 향수
    case liked  // LIKE 향수
}

struct TastingNotePerfumeScope: Equatable {
    let perfumeName: String
    let brandName: String

    var title: String {
        "\(PerfumePresentationSupport.displayPerfumeName(perfumeName)) 시향 기록"
    }
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
    @Published private(set) var selectedNoteIDs: Set<String> = []

    /// 현재 선택된 필터
    @Published private(set) var selectedFilter: TastingNoteFilter = .all

    // MARK: - 필터 키 캐시 (보유/LIKE 향수 브랜드|이름 소문자 Set)

    @Published private var ownedKeys: Set<String> = []
    @Published private var likedKeys: Set<String> = []
    let perfumeScope: TastingNotePerfumeScope?

    // MARK: - Computed

    /// 필터 적용 후 표시할 시향 기록 목록
    var filteredNotes: [TastingNote] {
        let scopedNotes = notes.filter { note in
            guard let perfumeScope else { return true }
            return !noteKeys(note).isDisjoint(with: perfumeKeys(
                perfumeName: perfumeScope.perfumeName,
                brandName: perfumeScope.brandName
            ))
        }

        let filtered: [TastingNote]

        switch selectedFilter {
        case .all:
            filtered = scopedNotes
        case .owned:
            filtered = scopedNotes.filter { !noteKeys($0).isDisjoint(with: ownedKeys) }
        case .liked:
            filtered = scopedNotes.filter { !noteKeys($0).isDisjoint(with: likedKeys) }
        }

        return uniqueLatestNotes(from: filtered)
    }

    /// 전체 목록이 비어있는지 (삭제 버튼 활성화 기준)
    var isEmpty: Bool { notes.isEmpty }

    /// 필터 적용 후 결과가 없는지 (빈 상태 뷰 표시 기준)
    var isFilteredEmpty: Bool { filteredNotes.isEmpty }

    var hasSelectedNotes: Bool { !selectedNoteIDs.isEmpty }

    private var uid: String? { Auth.auth().currentUser?.uid }
 
    // MARK: - Private
 
    private var toastTask: Task<Void, Never>?
    private let firestoreService: FirestoreService
    private let localRepository: LocalTastingNoteRepository
    private let collectionCacheStore = CollectedPerfumeCacheStore()
 
    // MARK: - Init / Deinit
 
    init(
        firestoreService: FirestoreService,
        localRepository: LocalTastingNoteRepository,
        perfumeScope: TastingNotePerfumeScope? = nil
    ) {
        self.firestoreService = firestoreService
        self.localRepository = localRepository
        self.perfumeScope = perfumeScope
        fetchNotes()
        Task { await loadFilterKeys() }
    }
 
    deinit {
        toastTask?.cancel()
    }
 
    // MARK: - 목록 실시간 조회

    func fetchNotes() {
        Task { await reload() }
    }

    // MARK: - 단발성 새로고침 (폼 닫힐 때, 리스너 실패 시 fallback)

    func reload() async {
        isLoading = true
        do {
            notes = try localRepository.loadNotes()
            await localRepository.syncPendingChanges()
            await localRepository.refreshFromRemote()
            notes = try localRepository.loadNotes()
            await loadFilterKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reloadFromLocal() async {
        do {
            notes = try localRepository.loadNotes()
            await loadFilterKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
 
    // MARK: - 삭제 (목록 → 확인 얼럿)
 
    func requestDelete(_ note: TastingNote) {
        noteToDelete = note
        showDeleteAlert = true
    }

    func requestDeleteSelected() {
        guard hasSelectedNotes else { return }
        noteToDelete = nil
        showDeleteAlert = true
    }
 
    func confirmDelete() async {
        if noteToDelete == nil {
            await deleteSelectedNotes()
            return
        }

        guard let note = noteToDelete else { return }
        do {
            try await localRepository.delete(note)
            notes = try localRepository.loadNotes()
            noteToDelete = nil
            isDeleteMode = false
        } catch {
            errorMessage = AppStrings.ViewModelMessages.TastingNote.deleteFailed
        }
    }
 
    // MARK: - 삭제 (상세 화면에서 직접)
 
    func deleteNote(_ note: TastingNote) async {
        do {
            try await localRepository.delete(note)
            notes = try localRepository.loadNotes()
        } catch {
            errorMessage = AppStrings.ViewModelMessages.TastingNote.deleteFailed
        }
    }
 
    // MARK: - 삭제 모드 토글
 
    func toggleDeleteMode() {
        isDeleteMode.toggle()
        if !isDeleteMode {
            selectedNoteIDs.removeAll()
            noteToDelete = nil
        }
    }

    func toggleNoteSelection(_ note: TastingNote) {
        guard let id = note.id else { return }
        if selectedNoteIDs.contains(id) {
            selectedNoteIDs.remove(id)
        } else {
            selectedNoteIDs.insert(id)
        }
    }

    func isSelected(_ note: TastingNote) -> Bool {
        guard let id = note.id else { return false }
        return selectedNoteIDs.contains(id)
    }
 
    // MARK: - 저장 완료 토스트
 
    func showToast(perfumeName: String) {
        toastMessage = AppStrings.ViewModelMessages.TastingNote.saved(perfumeName)
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }
 
    func clearError() { errorMessage = nil }

    private func deleteSelectedNotes() async {
        guard !selectedNoteIDs.isEmpty else { return }

        do {
            try await localRepository.delete(ids: selectedNoteIDs)
            notes = try localRepository.loadNotes()
            selectedNoteIDs.removeAll()
            isDeleteMode = false
            showDeleteAlert = false
        } catch {
            errorMessage = "삭제 중 오류가 발생했어요"
        }
    }

    // MARK: - 필터 선택 / 해제

    /// 선택한 필터로 전환한다.
    func selectFilter(_ filter: TastingNoteFilter) {
        selectedFilter = filter
        Task { await loadFilterKeys() }
    }

    // MARK: - 필터 키 로딩 (보유/LIKE 향수 → 브랜드|이름 소문자 Set)

    private func loadFilterKeys() async {
        let cachedOwned = collectionCacheStore.load()
        do {
            async let ownedFetch = firestoreService.fetchCollection()
            async let likedFetch = firestoreService.fetchLikedPerfumes()
            let (owned, liked) = try await (ownedFetch, likedFetch)
            let mergedOwned = mergeCollection(remote: owned, cached: cachedOwned)
            ownedKeys = Set(mergedOwned.flatMap { perfumeKeys(perfumeName: $0.name, brandName: $0.brand) })
            likedKeys = Set(liked.flatMap { perfumeKeys(perfumeName: $0.name, brandName: $0.brand) })
        } catch {
            // 보유 향수는 상세 화면에서 등록 직후 UserDefaults 캐시에 먼저 반영될 수 있다.
            ownedKeys = Set(cachedOwned.flatMap { perfumeKeys(perfumeName: $0.name, brandName: $0.brand) })
            likedKeys = []
        }
    }

    private func mergeCollection(
        remote: [CollectedPerfume],
        cached: [CollectedPerfume]
    ) -> [CollectedPerfume] {
        var seenIDs = Set<String>()
        return (remote + cached).filter { perfume in
            seenIDs.insert(perfume.id).inserted
        }
    }

    // MARK: - 시향 기록 키 생성 (브랜드|이름 소문자)

    private func noteKeys(_ note: TastingNote) -> Set<String> {
        perfumeKeys(perfumeName: note.perfumeName, brandName: note.brandName)
    }

    private func uniqueLatestNotes(from notes: [TastingNote]) -> [TastingNote] {
        var seenKeys = Set<String>()
        return notes.filter { note in
            let key = primaryPerfumeKey(perfumeName: note.perfumeName, brandName: note.brandName)
            return seenKeys.insert(key).inserted
        }
    }

    private func perfumeKeys(perfumeName: String, brandName: String) -> Set<String> {
        [
            primaryPerfumeKey(perfumeName: perfumeName, brandName: brandName),
            primaryPerfumeKey(
                perfumeName: PerfumePresentationSupport.displayPerfumeName(perfumeName),
                brandName: PerfumePresentationSupport.displayBrand(brandName)
            )
        ]
    }

    private func primaryPerfumeKey(perfumeName: String, brandName: String) -> String {
        let normalizedBrand = brandName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedPerfume = perfumeName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(normalizedBrand)|\(normalizedPerfume)"
    }
}
