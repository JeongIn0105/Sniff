//
//  LikedPerfumeListViewModel.swift
//  Sniff
//

// MARK: - LIKE 향수 목록 뷰모델
import Foundation
import Combine
import RxSwift

@MainActor
final class LikedPerfumeListViewModel: ObservableObject {

    private enum DisplayLimit {
        static let maxItems = 50
    }

    struct PerfumeRowItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let sourcePerfume: Perfume
    }

    @Published private(set) var perfumes: [PerfumeRowItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    var isEmpty: Bool { perfumes.isEmpty }
    var perfumeCount: Int { perfumes.count }

    private let firestoreService: FirestoreService
    private let tastingRepository: TastingRecordRepositoryType
    init(
        firestoreService: FirestoreService,
        tastingRepository: TastingRecordRepositoryType
    ) {
        self.firestoreService = firestoreService
        self.tastingRepository = tastingRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let likedPerfumes = try await firestoreService.fetchLikedPerfumes()

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

            perfumes = Array(likedPerfumes.prefix(DisplayLimit.maxItems)).map { perfume in
                let sourcePerfume = perfume.toPerfume()

                return PerfumeRowItem(
                    id: perfume.id,
                    name: perfume.name,
                    brand: perfume.brand,
                    imageURL: perfume.imageURL,
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
                    sourcePerfume: sourcePerfume
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeLike(id: String) async {
        let previousItems = perfumes
        perfumes.removeAll { $0.id == id }

        do {
            try await firestoreService.removeLikedPerfume(id: id)
        } catch {
            perfumes = previousItems
            errorMessage = error.localizedDescription
        }
    }

    func clearError() { errorMessage = nil }
}

private extension LikedPerfumeListViewModel {

    func fetchTastingRecords() async throws -> [TastingRecord] {
        try await tastingRepository.fetchTastingRecords().async()
    }

}
