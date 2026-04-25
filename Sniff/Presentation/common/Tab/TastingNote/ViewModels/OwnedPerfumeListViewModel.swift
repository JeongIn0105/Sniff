//
//  OwnedPerfumeListViewModel.swift
//  Sniff
//

// MARK: - 보유 향수 목록 뷰모델
import Foundation
import Combine
import RxSwift

@MainActor
final class OwnedPerfumeListViewModel: ObservableObject {

    private enum DisplayLimit {
        static let maxItems = 10
    }

    struct PerfumeCardItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let isLiked: Bool
        let sourcePerfume: Perfume
    }

    @Published private(set) var perfumes: [PerfumeCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEditMode = false
    @Published private(set) var selectedPerfumeIDs = Set<String>()
    @Published var toastMessage: String?
    @Published private(set) var monthlyUsageCount: Int = 0

    var isEmpty: Bool { perfumes.isEmpty }
    var perfumeCount: Int { perfumes.count }
    var hasSelection: Bool { !selectedPerfumeIDs.isEmpty }
    var monthlyUsageLimit: Int { collectionRepository.monthlyCollectionLimit }

    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private var toastTask: Task<Void, Never>?

    init(
        collectionRepository: CollectionRepositoryType,
        tastingRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository
    ) {
        self.collectionRepository = collectionRepository
        self.tastingRepository = tastingRepository
        self.localTastingNoteRepository = localTastingNoteRepository
    }

    deinit {
        toastTask?.cancel()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            monthlyUsageCount = collectionRepository.currentMonthlyCollectionUsage()
            let collection = try await fetchCollection()

            let tastingKeys = await fetchTastingKeys()

            let likedIDs: Set<String>
            do {
                let likedPerfumes = try await collectionRepository.fetchLikedPerfumes().async()
                likedIDs = Set(likedPerfumes.map(\.id))
            } catch {
                likedIDs = []
            }

            perfumes = Array(collection.prefix(DisplayLimit.maxItems)).map { perfume in
                let sourcePerfume = perfume.toPerfume()

                return PerfumeCardItem(
                    id: perfume.id,
                    name: perfume.name,
                    brand: perfume.brand,
                    imageURL: perfume.imageUrl,
                    accordTags: PerfumePresentationSupport.previewAccords(
                        mainAccords: perfume.mainAccords,
                        fallback: perfume.scentFamilies
                    ),
                    hasTastingRecord: tastingKeys.contains(
                        PerfumePresentationSupport.recordKey(
                            perfumeName: perfume.name,
                            brandName: perfume.brand
                        )
                    ) || !tastingKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: perfume.name,
                        brandName: perfume.brand
                    )),
                    isLiked: likedIDs.contains(perfume.id),
                    sourcePerfume: sourcePerfume
                )
            }

            selectedPerfumeIDs = selectedPerfumeIDs.intersection(Set(perfumes.map(\.id)))
        } catch {
            handleError(error)
        }
    }

    func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            selectedPerfumeIDs.removeAll()
        }
    }

    func toggleSelection(for id: String) {
        if selectedPerfumeIDs.contains(id) {
            selectedPerfumeIDs.remove(id)
        } else {
            selectedPerfumeIDs.insert(id)
        }
    }

    func deleteSelectedPerfumes() async {
        let ids = Array(selectedPerfumeIDs)
        guard !ids.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await collectionRepository.deleteCollectionItems(ids: ids)

            let deletedCount = ids.count
            selectedPerfumeIDs.removeAll()
            isEditMode = false
            await load()
            showToast(message: AppStrings.ViewModelMessages.TastingNote.deletedOwnedCount(deletedCount))
        } catch {
            handleError(error)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func toggleLike(for id: String) async {
        guard let index = perfumes.firstIndex(where: { $0.id == id }) else { return }

        let item = perfumes[index]
        let willLike = !item.isLiked
        let previousPerfumes = perfumes

        perfumes[index] = PerfumeCardItem(
            id: item.id,
            name: item.name,
            brand: item.brand,
            imageURL: item.imageURL,
            accordTags: item.accordTags,
            hasTastingRecord: item.hasTastingRecord,
            isLiked: willLike,
            sourcePerfume: item.sourcePerfume
        )

        do {
            if willLike {
                try await collectionRepository.saveLikedPerfume(item.sourcePerfume).async()
            } else {
                try await collectionRepository.deleteLikedPerfume(id: item.id).async()
            }
        } catch {
            perfumes = previousPerfumes
            handleError(error)
        }
    }
}

private extension OwnedPerfumeListViewModel {

    func fetchCollection() async throws -> [CollectedPerfume] {
        try await collectionRepository.fetchCollection().async()
    }

    func fetchTastingRecords() async throws -> [TastingRecord] {
        try await tastingRepository.fetchTastingRecords().async()
    }

    func fetchTastingKeys() async -> Set<String> {
        var keys = Set<String>()

        do {
            let localNotes = try localTastingNoteRepository.loadNotes()
            keys.formUnion(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
        } catch {
            // 로컬 시향 기록 로딩 실패 시 원격 기록으로 보완한다.
        }

        do {
            let tastingRecords = try await fetchTastingRecords()
            keys.formUnion(tastingRecords.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
        } catch {
            return keys
        }

        return keys
    }

    func showToast(message: String) {
        toastMessage = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }

    func handleError(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showToast(message: limitError.localizedDescription)
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
