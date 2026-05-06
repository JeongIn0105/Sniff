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

    enum UsageFilter: Hashable, CaseIterable {
        case all
        case status(CollectedPerfumeUsageStatus)

        static var allCases: [UsageFilter] {
            [.all] + CollectedPerfumeUsageStatus.allCases.map { .status($0) }
        }

        var title: String {
            switch self {
            case .all:
                return "전체"
            case .status(let status):
                return status.displayName
            }
        }
    }

    enum SortOrder: Hashable, CaseIterable {
        case latest
        case oldest

        var title: String {
            switch self {
            case .latest:
                return "최신순"
            case .oldest:
                return "오래된순"
            }
        }
    }

    struct PerfumeCardItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let usageStatus: CollectedPerfumeUsageStatus?
        let hasTastingRecord: Bool
        let isLiked: Bool
        let sourcePerfume: Perfume
        let sourceCollectedPerfume: CollectedPerfume
    }

    @Published private(set) var perfumes: [PerfumeCardItem] = []
    @Published private(set) var allPerfumes: [PerfumeCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEditMode = false
    @Published private(set) var selectedPerfumeIDs = Set<String>()
    @Published var toastMessage: String?
    @Published private(set) var monthlyUsageCount: Int = 0
    @Published var selectedFilter: UsageFilter = .all {
        didSet { applyFilter() }
    }
    @Published var selectedSortOrder: SortOrder = .latest {
        didSet { applyFilter() }
    }

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

            allPerfumes = collection.map { perfume in
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
                    usageStatus: perfume.usageStatus,
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
                    sourcePerfume: sourcePerfume,
                    sourceCollectedPerfume: perfume
                )
            }
            applyFilter()

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
            usageStatus: item.usageStatus,
            hasTastingRecord: item.hasTastingRecord,
            isLiked: willLike,
            sourcePerfume: item.sourcePerfume,
            sourceCollectedPerfume: item.sourceCollectedPerfume
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

    func updateOwnedPerfume(
        _ perfume: CollectedPerfume,
        registrationInfo: CollectedPerfumeRegistrationInfo
    ) async -> Bool {
        do {
            try await collectionRepository
                .updateCollectedPerfumeRegistration(id: perfume.id, registrationInfo: registrationInfo)
                .async()
            await load()
            selectedFilter = .status(registrationInfo.usageStatus)
            NotificationCenter.default.postPerfumeCollectionDidChange(scope: .owned)
            showToast(message: "보유 정보가 저장됐어요.")
            return true
        } catch {
            handleError(error)
            return false
        }
    }

    func deleteOwnedPerfume(_ perfume: CollectedPerfume) async -> Bool {
        do {
            try await collectionRepository.deleteCollectedPerfume(id: perfume.id).async()
            selectedPerfumeIDs.remove(perfume.id)
            await load()
            NotificationCenter.default.postPerfumeCollectionDidChange(scope: .owned)
            showToast(message: "보유 향수에서 해제됐어요.")
            return true
        } catch {
            handleError(error)
            return false
        }
    }

    func showEditLimitToast() {
        showToast(message: "보유 정보 수정 가능 횟수를 모두 사용했어요.")
    }
}

private extension OwnedPerfumeListViewModel {

    func applyFilter() {
        let filtered: [PerfumeCardItem]
        switch selectedFilter {
        case .all:
            filtered = allPerfumes
        case .status(let status):
            filtered = allPerfumes.filter { $0.usageStatus == status }
        }

        let sorted = filtered.sorted { lhs, rhs in
            let lhsDate = lhs.sourceCollectedPerfume.createdAt
            let rhsDate = rhs.sourceCollectedPerfume.createdAt

            switch (lhsDate, rhsDate, selectedSortOrder) {
            case let (lhsDate?, rhsDate?, .latest):
                return lhsDate > rhsDate
            case let (lhsDate?, rhsDate?, .oldest):
                return lhsDate < rhsDate
            case (.some, .none, _):
                return true
            case (.none, .some, _):
                return false
            case (.none, .none, _):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }

        perfumes = Array(sorted.prefix(DisplayLimit.maxItems))
    }

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
