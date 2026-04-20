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
    }

    struct LikedPreviewItem: Identifiable {
        let id: String
        let name: String
        let brand: String
        let imageURL: String?
        let accordTags: [String]
    }

    @Published private(set) var profileInfo: ProfileInfo?
    @Published private(set) var ownedPerfumes: [OwnedPreviewItem] = []
    @Published private(set) var likedPerfumes: [LikedPreviewItem] = []
    @Published private(set) var ownedCount: Int = 0
    @Published private(set) var likedCount: Int = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    /// Preview 전용 플래그 — true이면 load()를 실행하지 않음
    var isMock = false

    private let firestoreService: FirestoreService
    private let collectionRepository: CollectionRepositoryType
    private let tastingRepository: TastingRecordRepositoryType
    private let disposeBag = DisposeBag()

    nonisolated init(
        firestoreService: FirestoreService? = nil,
        collectionRepository: CollectionRepositoryType? = nil,
        tastingRepository: TastingRecordRepositoryType? = nil
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.collectionRepository = collectionRepository ?? CollectionRepository()
        self.tastingRepository = tastingRepository ?? TastingRecordRepository()
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
                ownedCount = collection.count
                ownedPerfumes = Array(collection.prefix(4)).map {
                    makeOwnedPreviewItem(from: $0, tastingKeys: tastingKeys, likedIDs: likedIDs)
                }
            } catch {
                ownedCount = 0
                ownedPerfumes = []
            }

            do {
                let liked = try await firestoreService.fetchLikedPerfumes()
                likedCount = liked.count
                likedPerfumes = Array(liked.prefix(6)).map(makeLikedPreviewItem)
            } catch {
                likedCount = 0
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
        try await withCheckedThrowingContinuation { continuation in
            let disposable = collectionRepository.fetchCollection().subscribe(
                onSuccess: { items in
                    continuation.resume(returning: items)
                },
                onFailure: { error in
                    continuation.resume(throwing: error)
                }
            )

            _ = disposable
        }
    }

    func makeOwnedPreviewItem(from perfume: CollectedPerfume) -> OwnedPreviewItem {
        makeOwnedPreviewItem(from: perfume, tastingKeys: [], likedIDs: [])
    }

    func makeOwnedPreviewItem(
        from perfume: CollectedPerfume,
        tastingKeys: Set<String>,
        likedIDs: Set<String>
    ) -> OwnedPreviewItem {
        OwnedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: perfume.imageURL,
            accordTags: previewAccords(mainAccords: perfume.mainAccords, fallback: perfume.scentFamilies),
            hasTastingRecord: tastingKeys.contains(
                makeRecordKey(perfumeName: perfume.name, brandName: perfume.brand)
            ),
            isLiked: likedIDs.contains(perfume.id)
        )
    }

    func makeLikedPreviewItem(from perfume: LikedPerfume) -> LikedPreviewItem {
        LikedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: perfume.imageURL,
            accordTags: previewAccords(mainAccords: perfume.mainAccords, fallback: perfume.scentFamilies)
        )
    }

    func previewAccords(mainAccords: [String], fallback: [String]) -> [String] {
        let source = mainAccords.isEmpty ? fallback : mainAccords
        return Array(source.prefix(2))
    }

    func fetchTastingKeys() async -> Set<String> {
        do {
            let records = try await withCheckedThrowingContinuation { continuation in
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

            return Set(
                records.map { record in
                    makeRecordKey(perfumeName: record.perfumeName, brandName: record.brandName)
                }
            )
        } catch {
            return []
        }
    }

    func fetchLikedIDs() async -> Set<String> {
        do {
            let likedPerfumes = try await firestoreService.fetchLikedPerfumes()
            return Set(likedPerfumes.map(\.id))
        } catch {
            return []
        }
    }

    func makeRecordKey(perfumeName: String, brandName: String) -> String {
        "\(brandName.lowercased())|\(perfumeName.lowercased())"
    }
}

// MARK: - Preview 전용 목 데이터

#if DEBUG
extension MyPageViewModel {

    /// SwiftUI Preview 전용 목 뷰모델
    static func mock() -> MyPageViewModel {
        let vm = MyPageViewModel()
        vm.isMock = true
        vm.profileInfo = ProfileInfo(nickname: "강지수", email: "asdgh1423@gmail.com")
        vm.ownedCount = 3
        vm.ownedPerfumes = [
            OwnedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"],
                hasTastingRecord: true, isLiked: false
            ),
            OwnedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"],
                hasTastingRecord: false, isLiked: true
            ),
            OwnedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"],
                hasTastingRecord: true, isLiked: false
            )
        ]
        vm.likedCount = 3
        vm.likedPerfumes = [
            LikedPreviewItem(
                id: "1", name: "어나더 13 오 드 퍼퓸", brand: "르 라보",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.25186.jpg",
                accordTags: ["Floral", "Musky"]
            ),
            LikedPreviewItem(
                id: "2", name: "블랑쉬 오 드 퍼퓸", brand: "바이레도",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.17770.jpg",
                accordTags: ["Musky", "Powdery"]
            ),
            LikedPreviewItem(
                id: "3", name: "포 허 오드 퍼퓸", brand: "나르시소 로드리게스",
                imageURL: "https://fimgs.net/mdimg/perfume/375x500.4880.jpg",
                accordTags: ["Musky", "Woody"]
            )
        ]
        return vm
    }
}
#endif
