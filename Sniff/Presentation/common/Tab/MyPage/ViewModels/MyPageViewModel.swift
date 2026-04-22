//
//  MyPageViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import Combine
import FirebaseAuth
import RxSwift

@MainActor
final class MyPageViewModel: ObservableObject {

    struct ProfileInfo {
        let nickname: String
        let email: String?
    }

    struct OwnedPreviewItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let hasTastingRecord: Bool
        let isLiked: Bool
        let sourcePerfume: Perfume
    }

    struct LikedPreviewItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
        let sourcePerfume: Perfume
    }

    @Published private(set) var profileInfo: ProfileInfo?
    @Published private(set) var ownedPerfumes: [OwnedPreviewItem] = []
    @Published private(set) var likedPerfumes: [LikedPreviewItem] = []
    @Published private(set) var ownedCount: Int = 0
    @Published private(set) var likedCount: Int = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private enum DisplayLimit {
        static let ownedPreview = 5
        static let likedPreview = 10
    }

    /// Preview 전용 플래그 — true이면 load()를 실행하지 않음
    var isMock = false

    private let firestoreService: FirestoreService
    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private var allOwnedPerfumes: [OwnedPreviewItem] = []
    private var allLikedPerfumes: [LikedPreviewItem] = []

    init(
        firestoreService: FirestoreService,
        collectionRepository: CollectionRepositoryType,
        tastingRepository: TastingRecordRepositoryType
    ) {
        self.firestoreService = firestoreService
        self.collectionRepository = collectionRepository
        self.tastingRepository = tastingRepository
    }

    func load() async {
        // Preview 목 데이터 사용 시 Firebase 호출 생략
        guard !isMock else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            profileInfo = try await fetchProfileInfo()

            do {
                let collection = try await fetchCollectionItems()
                let tastingKeys = await fetchTastingKeys()
                let likedIDs = await fetchLikedIDs()
                allOwnedPerfumes = collection.map {
                    makeOwnedPreviewItem(from: $0, tastingKeys: tastingKeys, likedIDs: likedIDs)
                }
                ownedCount = allOwnedPerfumes.count
                ownedPerfumes = Array(allOwnedPerfumes.prefix(DisplayLimit.ownedPreview))
            } catch {
                ownedCount = 0
                allOwnedPerfumes = []
                ownedPerfumes = []
            }

            do {
                let liked = try await collectionRepository.fetchLikedPerfumes().async()
                allLikedPerfumes = liked.map(makeLikedPreviewItem)
                likedCount = allLikedPerfumes.count
                likedPerfumes = Array(allLikedPerfumes.prefix(DisplayLimit.likedPreview))
            } catch {
                likedCount = 0
                allLikedPerfumes = []
                likedPerfumes = []
            }
        } catch {
            errorMessage = error.localizedDescription
            if profileInfo == nil {
                profileInfo = fallbackProfileInfo()
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func toggleOwnedPerfumeLike(id: String) async {
        guard let ownedIndex = allOwnedPerfumes.firstIndex(where: { $0.id == id }) else { return }

        let ownedItem = allOwnedPerfumes[ownedIndex]
        let willLike = !ownedItem.isLiked
        let previousOwned = allOwnedPerfumes
        let previousLiked = allLikedPerfumes
        let previousLikedCount = likedCount

        allOwnedPerfumes[ownedIndex] = OwnedPreviewItem(
            id: ownedItem.id,
            name: ownedItem.name,
            brand: ownedItem.brand,
            imageURL: ownedItem.imageURL,
            accordTags: ownedItem.accordTags,
            hasTastingRecord: ownedItem.hasTastingRecord,
            isLiked: willLike,
            sourcePerfume: ownedItem.sourcePerfume
        )

        if willLike {
            if !allLikedPerfumes.contains(where: { $0.id == ownedItem.id }) {
                allLikedPerfumes.insert(makeLikedPreviewItem(from: ownedItem.sourcePerfume), at: 0)
            }
            likedCount += 1
        } else {
            allLikedPerfumes.removeAll { $0.id == ownedItem.id }
            likedCount = max(0, likedCount - 1)
        }
        applyPreviewLimits()

        do {
            if willLike {
                try await collectionRepository.saveLikedPerfume(ownedItem.sourcePerfume).async()
            } else {
                try await collectionRepository.deleteLikedPerfume(id: ownedItem.id).async()
            }
        } catch {
            allOwnedPerfumes = previousOwned
            allLikedPerfumes = previousLiked
            likedCount = previousLikedCount
            applyPreviewLimits()
            errorMessage = error.localizedDescription
        }
    }

    func removeLikedPerfume(id: String) async {
        let previousLiked = allLikedPerfumes
        let previousLikedCount = likedCount
        let previousOwned = allOwnedPerfumes

        allLikedPerfumes.removeAll { $0.id == id }
        likedCount = max(0, likedCount - 1)

        if let ownedIndex = allOwnedPerfumes.firstIndex(where: { $0.id == id }) {
            let item = allOwnedPerfumes[ownedIndex]
            allOwnedPerfumes[ownedIndex] = OwnedPreviewItem(
                id: item.id,
                name: item.name,
                brand: item.brand,
                imageURL: item.imageURL,
                accordTags: item.accordTags,
                hasTastingRecord: item.hasTastingRecord,
                isLiked: false,
                sourcePerfume: item.sourcePerfume
            )
        }
        applyPreviewLimits()

        do {
            try await collectionRepository.deleteLikedPerfume(id: id).async()
        } catch {
            allLikedPerfumes = previousLiked
            likedCount = previousLikedCount
            allOwnedPerfumes = previousOwned
            applyPreviewLimits()
            errorMessage = error.localizedDescription
        }
    }
}

private extension MyPageViewModel {

    func fetchProfileInfo() async throws -> ProfileInfo {
        do {
            let user = try await firestoreService.fetchUserProfile()
            return ProfileInfo(nickname: user.nickname, email: user.email)
        } catch FirestoreServiceError.invalidUserProfile {
            return fallbackProfileInfo()
        }
    }

    func fallbackProfileInfo() -> ProfileInfo {
        let email = Auth.auth().currentUser?.email
        let nickname = email?.split(separator: "@").first.map(String.init).flatMap {
            $0.isEmpty ? nil : $0
        } ?? "사용자"

        return ProfileInfo(nickname: nickname, email: email)
    }

    func fetchCollectionItems() async throws -> [CollectedPerfume] {
        try await collectionRepository.fetchCollection().async()
    }

    func makeOwnedPreviewItem(from perfume: CollectedPerfume) -> OwnedPreviewItem {
        makeOwnedPreviewItem(from: perfume, tastingKeys: [], likedIDs: [])
    }

    func makeOwnedPreviewItem(
        from perfume: CollectedPerfume,
        tastingKeys: Set<String>,
        likedIDs: Set<String>
    ) -> OwnedPreviewItem {
        let sourcePerfume = perfume.toPerfume()

        return OwnedPreviewItem(
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
            isLiked: likedIDs.contains(perfume.id),
            sourcePerfume: sourcePerfume
        )
    }

    func makeLikedPreviewItem(from perfume: LikedPerfume) -> LikedPreviewItem {
        makeLikedPreviewItem(from: perfume.toPerfume())
    }

    func makeLikedPreviewItem(from perfume: Perfume) -> LikedPreviewItem {
        return LikedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: perfume.imageUrl,
            accordTags: PerfumePresentationSupport.previewAccords(
                mainAccords: perfume.mainAccords,
                fallback: perfume.mainAccords
            ),
            sourcePerfume: perfume
        )
    }

    func fetchTastingKeys() async -> Set<String> {
        do {
            let records = try await tastingRepository.fetchTastingRecords().async()

            return Set(
                records.map { record in
                    PerfumePresentationSupport.recordKey(
                        perfumeName: record.perfumeName,
                        brandName: record.brandName
                    )
                }
            )
        } catch {
            return []
        }
    }

    func fetchLikedIDs() async -> Set<String> {
        do {
            let likedPerfumes = try await collectionRepository.fetchLikedPerfumes().async()
            return Set(likedPerfumes.map(\.id))
        } catch {
            return []
        }
    }

    func applyPreviewLimits() {
        ownedPerfumes = Array(allOwnedPerfumes.prefix(DisplayLimit.ownedPreview))
        likedPerfumes = Array(allLikedPerfumes.prefix(DisplayLimit.likedPreview))
    }
}

// MARK: - Preview 전용 목 데이터

#if DEBUG
extension MyPageViewModel {

    /// SwiftUI Preview 전용 목 뷰모델
    @MainActor
    static func mock() -> MyPageViewModel {
        let dependencyContainer = AppDependencyContainer.shared
        let vm = MyPageViewModel(
            firestoreService: dependencyContainer.firestoreService,
            collectionRepository: dependencyContainer.makeCollectionRepository(),
            tastingRepository: dependencyContainer.makeTastingRecordRepository()
        )
        vm.isMock = true
        vm.profileInfo = ProfileInfo(nickname: "강지수", email: "asdgh1423@gmail.com")
        vm.ownedCount = 3
        vm.ownedPerfumes = [
            OwnedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"],
                hasTastingRecord: true, isLiked: false,
                sourcePerfume: Perfume(
                    id: "1", name: "Another 13 Eau de Parfum", brand: "Le Labo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                    rawMainAccords: ["Floral", "Musky"], mainAccords: ["Floral", "Musky"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            OwnedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"],
                hasTastingRecord: false, isLiked: true,
                sourcePerfume: Perfume(
                    id: "2", name: "Blanche Eau de Parfum", brand: "Byredo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                    rawMainAccords: ["Musky", "Powdery"], mainAccords: ["Musky", "Powdery"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            OwnedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"],
                hasTastingRecord: true, isLiked: false,
                sourcePerfume: Perfume(
                    id: "3", name: "For Her Eau de Parfum", brand: "Narciso Rodriguez",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                    rawMainAccords: ["Musky", "Woody"], mainAccords: ["Musky", "Woody"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            )
        ]
        vm.likedCount = 3
        vm.likedPerfumes = [
            LikedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"],
                sourcePerfume: Perfume(
                    id: "1", name: "Another 13 Eau de Parfum", brand: "Le Labo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                    rawMainAccords: ["Floral", "Musky"], mainAccords: ["Floral", "Musky"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            LikedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"],
                sourcePerfume: Perfume(
                    id: "2", name: "Blanche Eau de Parfum", brand: "Byredo",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                    rawMainAccords: ["Musky", "Powdery"], mainAccords: ["Musky", "Powdery"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            ),
            LikedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"],
                sourcePerfume: Perfume(
                    id: "3", name: "For Her Eau de Parfum", brand: "Narciso Rodriguez",
                    imageUrl: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                    rawMainAccords: ["Musky", "Woody"], mainAccords: ["Musky", "Woody"],
                    topNotes: nil, middleNotes: nil, baseNotes: nil,
                    concentration: nil, gender: nil, season: nil, situation: nil,
                    longevity: nil, sillage: nil
                )
            )
        ]
        return vm
    }
}
#endif
