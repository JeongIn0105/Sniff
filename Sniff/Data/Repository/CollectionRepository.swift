//
//  CollectionRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//
import Foundation
import RxSwift

final class CollectionRepository: CollectionRepositoryType {
    private let firestoreService: FirestoreService
    private let cacheStore: CollectedPerfumeCacheStore

    init(
        firestoreService: FirestoreService? = nil,
        cacheStore: CollectedPerfumeCacheStore = CollectedPerfumeCacheStore()
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.cacheStore = cacheStore
    }

    func fetchCollection() -> Single<[CollectedPerfume]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    let collection = try await self.firestoreService.fetchCollection()
                    self.cacheStore.save(collection)
                    single(.success(collection))
                } catch {
                    let cached = self.cacheStore.load()
                    if cached.isEmpty {
                        single(.failure(error))
                    } else {
                        single(.success(cached))
                    }
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func saveCollectedPerfume(_ perfume: Perfume, memo: String? = nil) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    try await self.firestoreService.saveCollectedPerfume(perfume, memo: memo)
                    self.cacheStore.upsert(
                        CollectedPerfume(
                            id: perfume.id,
                            name: perfume.name,
                            brand: perfume.brand,
                            imageUrl: perfume.imageUrl,
                            mainAccords: perfume.mainAccords,
                            accordStrengths: perfume.mainAccordStrengths,
                            memo: memo,
                            createdAt: Date()
                        )
                    )
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func deleteCollectedPerfume(id: String) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    try await self.firestoreService.deleteCollectedPerfume(id: id)
                    self.cacheStore.delete(id: id)
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func fetchLikedPerfumes() -> Single<[LikedPerfume]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    let perfumes = try await self.firestoreService.fetchLikedPerfumes()
                    single(.success(perfumes))
                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func saveLikedPerfume(_ perfume: Perfume) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    try await self.firestoreService.saveLikedPerfume(perfume)
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func deleteLikedPerfume(id: String) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }
            let task = Task {
                do {
                    try await self.firestoreService.removeLikedPerfume(id: id)
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func deleteCollectionItems(ids: [String]) async throws {
        try await firestoreService.deleteCollectionItems(ids: ids)
        ids.forEach { cacheStore.delete(id: $0) }
    }
}
