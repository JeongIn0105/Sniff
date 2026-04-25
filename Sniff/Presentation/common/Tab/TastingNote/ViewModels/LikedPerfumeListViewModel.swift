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
    private let localTastingNoteRepository: LocalTastingNoteRepository

    init(
        firestoreService: FirestoreService,
        tastingRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository
    ) {
        self.firestoreService = firestoreService
        self.tastingRepository = tastingRepository
        self.localTastingNoteRepository = localTastingNoteRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 좋아요 향수와 보유 향수를 동시에 패치
            // (보유 향수는 이미지 URL fallback 용도)
            async let likedFetch = firestoreService.fetchLikedPerfumes()
            async let collectionFetch = firestoreService.fetchCollection()

            let likedPerfumes = try await likedFetch
            let collection = (try? await collectionFetch) ?? []

            let tastingKeys = await fetchTastingKeys()

            // 보유 향수 기반 이미지 URL fallback 맵 구성
            // ID 기반: likes doc ID == collection doc ID (동일 Fragella ID)
            let imageURLByID: [String: String] = collection.reduce(into: [:]) { map, item in
                guard let url = item.imageUrl else { return }
                map[item.id] = url
            }

            // 이름+브랜드 기반 fallback (ID가 다른 경우 대비)
            let imageURLByRecordKey: [String: String] = collection.reduce(into: [:]) { map, item in
                guard let url = item.imageUrl else { return }
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: item.name,
                    brandName: item.brand
                ).forEach { key in
                    if map[key] == nil { map[key] = url }
                }
            }

            perfumes = Array(likedPerfumes.prefix(DisplayLimit.maxItems)).map { liked in
                // 이미지 URL 우선순위: likes doc → collection ID 매칭 → 이름+브랜드 매칭
                let resolvedImageURL: String? = liked.imageURL
                    ?? imageURLByID[liked.id]
                    ?? PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: liked.name,
                        brandName: liked.brand
                    ).compactMap { imageURLByRecordKey[$0] }.first

                // 정확한 이미지 URL을 sourcePerfume에도 반영 (상세 화면 진입 시 사용)
                let sourcePerfume = Perfume(
                    id: liked.id,
                    name: liked.name,
                    brand: liked.brand,
                    imageUrl: resolvedImageURL,
                    rawMainAccords: liked.mainAccords,
                    mainAccords: liked.mainAccords,
                    mainAccordStrengths: [:],
                    topNotes: liked.topNotes,
                    middleNotes: liked.middleNotes,
                    baseNotes: liked.baseNotes,
                    concentration: liked.concentration,
                    gender: nil,
                    season: nil,
                    seasonRanking: liked.seasonRanking,
                    situation: nil,
                    longevity: liked.longevity,
                    sillage: liked.sillage
                )

                return PerfumeRowItem(
                    id: liked.id,
                    name: liked.name,
                    brand: liked.brand,
                    imageURL: resolvedImageURL,
                    accordTags: PerfumePresentationSupport.previewAccords(
                        mainAccords: liked.mainAccords,
                        fallback: liked.scentFamilies
                    ),
                    hasTastingRecord: tastingKeys.contains(
                        PerfumePresentationSupport.recordKey(
                            perfumeName: liked.name,
                            brandName: liked.brand
                        )
                    ) || !tastingKeys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: liked.name,
                        brandName: liked.brand
                    )),
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
            let tastingRecords = try await tastingRepository.fetchTastingRecords().async()
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
}
