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

    struct PerfumeRowItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
    }

    @Published private(set) var perfumes: [PerfumeRowItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    var isEmpty: Bool { perfumes.isEmpty }
    var perfumeCount: Int { perfumes.count }

    private let firestoreService: FirestoreService
    private let tastingRepository: TastingRecordRepositoryType
    private let disposeBag = DisposeBag()

    init(
        firestoreService: FirestoreService? = nil,
        tastingRepository: TastingRecordRepositoryType? = nil
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.tastingRepository = tastingRepository ?? TastingRecordRepository()
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
                        makeRecordKey(perfumeName: record.perfumeName, brandName: record.brandName)
                    }
                )
            } catch {
                tastingKeys = []
            }

            perfumes = likedPerfumes.map { perfume in
                PerfumeRowItem(
                    id: perfume.id,
                    name: perfume.name,
                    brand: perfume.brand,
                    imageURL: perfume.imageURL,
                    accordTags: previewAccords(mainAccords: perfume.mainAccords, fallback: perfume.scentFamilies),
                    hasTastingRecord: tastingKeys.contains(
                        makeRecordKey(perfumeName: perfume.name, brandName: perfume.brand)
                    )
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
        try await withCheckedThrowingContinuation { continuation in
            tastingRepository.fetchTastingRecords()
                .subscribe(
                    onSuccess: { items in
                        continuation.resume(returning: items)
                    },
                    onFailure: { error in
                        continuation.resume(throwing: error)
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    func previewAccords(mainAccords: [String], fallback: [String]) -> [String] {
        let source = mainAccords.isEmpty ? fallback : mainAccords
        return Array(source.prefix(2))
    }

    func makeRecordKey(perfumeName: String, brandName: String) -> String {
        "\(brandName.lowercased())|\(perfumeName.lowercased())"
    }
}
