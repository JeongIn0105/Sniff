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

    private let firestoreService: FirestoreService
    private let collectionRepository: CollectionRepositoryType

    init(
        firestoreService: FirestoreService? = nil,
        collectionRepository: CollectionRepositoryType? = nil
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.collectionRepository = collectionRepository ?? CollectionRepository()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            profileInfo = try await fetchProfileInfo()

            do {
                let collection = try await fetchCollectionItems()
                ownedCount = collection.count
                ownedPerfumes = Array(collection.prefix(4)).map(makeOwnedPreviewItem)
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
        OwnedPreviewItem(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageURL: perfume.imageURL,
            accordTags: previewAccords(mainAccords: perfume.mainAccords, fallback: perfume.scentFamilies)
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
}
