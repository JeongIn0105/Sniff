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

    struct PerfumeCardItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let isLiked: Bool
    }

    @Published private(set) var perfumes: [PerfumeCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEditMode = false
    @Published private(set) var selectedPerfumeIDs = Set<String>()
    @Published var toastMessage: String?

    var isEmpty: Bool { perfumes.isEmpty }
    var perfumeCount: Int { perfumes.count }
    var hasSelection: Bool { !selectedPerfumeIDs.isEmpty }

    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private var toastTask: Task<Void, Never>?

    init(
        collectionRepository: CollectionRepositoryType,
        tastingRepository: TastingRecordRepositoryType
    ) {
        self.collectionRepository = collectionRepository
        self.tastingRepository = tastingRepository
    }

    deinit {
        toastTask?.cancel()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let collection = try await fetchCollection()

            let tastingKeys: Set<String>
            do {
                let tastingRecords = try await fetchTastingRecords()
                tastingKeys = Set(
                    tastingRecords.map { record in
                        PerfumePresentationSupport.recordKey(
                            perfumeName: record.perfumeName,
                            brandName: record.brandName
                        )
                    }
                )
            } catch {
                tastingKeys = []
            }

            let likedIDs: Set<String>
            do {
                let likedPerfumes = try await collectionRepository.fetchLikedPerfumes().async()
                likedIDs = Set(likedPerfumes.map(\.id))
            } catch {
                likedIDs = []
            }

            perfumes = collection.map { perfume in
                PerfumeCardItem(
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
                    ),
                    isLiked: likedIDs.contains(perfume.id)
                )
            }

            selectedPerfumeIDs = selectedPerfumeIDs.intersection(Set(perfumes.map(\.id)))
        } catch {
            errorMessage = error.localizedDescription
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
            showToast(message: "\(deletedCount)개의 보유 향수가 삭제되었습니다")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

private extension OwnedPerfumeListViewModel {

    func fetchCollection() async throws -> [CollectedPerfume] {
        try await collectionRepository.fetchCollection().async()
    }

    func fetchTastingRecords() async throws -> [TastingRecord] {
        try await tastingRepository.fetchTastingRecords().async()
    }

    func showToast(message: String) {
        toastMessage = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }
}
