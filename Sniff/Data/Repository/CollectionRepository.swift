//
//  CollectionRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

final class CollectionRepository: CollectionRepositoryType {
    private static let memoryCacheTTL: TimeInterval = 15
    private static let memoryCacheLock = NSLock()
    private static var collectionMemoryCache: (value: [CollectedPerfume], timestamp: Date)?
    private static var likedMemoryCache: (value: [LikedPerfume], timestamp: Date)?

    private let firestoreService: FirestoreService
    private let cacheStore: CollectedPerfumeCacheStore
    private let usageLimiter: CollectionUsageLimiter

    init(
        firestoreService: FirestoreService? = nil,
        cacheStore: CollectedPerfumeCacheStore = CollectedPerfumeCacheStore(),
        usageLimiter: CollectionUsageLimiter = .shared
    ) {
        self.firestoreService = firestoreService ?? .shared
        self.cacheStore = cacheStore
        self.usageLimiter = usageLimiter
    }

    var monthlyCollectionLimit: Int {
        usageLimiter.monthlyCollectionLimit
    }

    func currentMonthlyCollectionUsage() -> Int {
        usageLimiter.currentMonthlyCollectionUsage()
    }

    func fetchCollection() -> Single<[CollectedPerfume]> {
        if let cached = Self.cachedCollection() {
            return .just(cached)
        }

        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let collection = try await self.firestoreService.fetchCollection()
                    self.cacheStore.save(collection)
                    Self.storeCollectionCache(collection)
                    single(.success(collection))
                } catch {
                    let cached = self.cacheStore.load()
                    if cached.isEmpty {
                        single(.failure(error))
                    } else {
                        Self.storeCollectionCache(cached)
                        single(.success(cached))
                    }
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func saveCollectedPerfume(_ perfume: Perfume, memo: String? = nil) -> Completable {
        makeSaveCollectedPerfumeCompletable(perfume, memo: memo, registrationInfo: nil)
    }

    func saveCollectedPerfume(
        _ perfume: Perfume,
        registrationInfo: CollectedPerfumeRegistrationInfo
    ) -> Completable {
        makeSaveCollectedPerfumeCompletable(
            perfume,
            memo: registrationInfo.memo,
            registrationInfo: registrationInfo
        )
    }

    func updateCollectedPerfumeRegistration(
        id: String,
        registrationInfo: CollectedPerfumeRegistrationInfo
    ) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    try await self.firestoreService.updateCollectedPerfumeRegistration(
                        id: id,
                        registrationInfo: registrationInfo
                    )

                    guard let cached = self.cacheStore.load().first(where: { $0.id == id }) else {
                        Self.invalidateCollectionCache()
                        completable(.completed)
                        return
                    }

                    let updatedPerfume = CollectedPerfume(
                        id: cached.id,
                        name: cached.name,
                        brand: cached.brand,
                        imageUrl: cached.imageUrl,
                        mainAccords: cached.mainAccords,
                        accordStrengths: cached.accordStrengths,
                        memo: registrationInfo.memo,
                        createdAt: cached.createdAt,
                        topNotes: cached.topNotes,
                        middleNotes: cached.middleNotes,
                        baseNotes: cached.baseNotes,
                        generalNotes: cached.generalNotes,
                        seasonRanking: cached.seasonRanking,
                        concentration: cached.concentration,
                        longevity: cached.longevity,
                        sillage: cached.sillage,
                        usageStatus: registrationInfo.usageStatus,
                        usageFrequency: registrationInfo.usageFrequency,
                        preferenceLevel: registrationInfo.preferenceLevel,
                        registrationEditCount: min(
                            cached.registrationEditCount + 1,
                            CollectedPerfumeEditPolicy.maxRegistrationEditCount
                        )
                    )
                    self.cacheStore.upsert(updatedPerfume)
                    Self.upsertCollectionCache(updatedPerfume)
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
                    Self.removeCollectionCacheItem(id: id)
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func fetchLikedPerfumes() -> Single<[LikedPerfume]> {
        if let cached = Self.cachedLikedPerfumes() {
            return .just(cached)
        }

        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let perfumes = try await self.firestoreService.fetchLikedPerfumes()
                    Self.storeLikedCache(perfumes)
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
                    let likedPerfumes = try await self.firestoreService.fetchLikedPerfumes()
                    if likedPerfumes.contains(where: { $0.id == perfume.id }) {
                        try await self.firestoreService.saveLikedPerfume(perfume)
                        Self.invalidateLikedCache()
                        completable(.completed)
                        return
                    }

                    try self.usageLimiter.validateLikeAddition(currentTotalLikes: likedPerfumes.count)
                    try await self.firestoreService.saveLikedPerfume(perfume)
                    self.usageLimiter.recordLikeAddition()
                    Self.invalidateLikedCache()
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
                    Self.invalidateLikedCache()
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
        ids.forEach { Self.removeCollectionCacheItem(id: $0) }
    }
}

private extension CollectionRepository {
    func makeSaveCollectedPerfumeCompletable(
        _ perfume: Perfume,
        memo: String?,
        registrationInfo: CollectedPerfumeRegistrationInfo?
    ) -> Completable {
        Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    try self.usageLimiter.validateCollectionChange()
                    if let registrationInfo {
                        try await self.firestoreService.saveCollectedPerfume(perfume, registrationInfo: registrationInfo)
                    } else {
                        try await self.firestoreService.saveCollectedPerfume(perfume, memo: memo)
                    }
                    self.usageLimiter.recordCollectionChange()

                    let cachedPerfume = CollectedPerfume(
                        id: perfume.collectionDocumentID,
                        name: perfume.name,
                        brand: perfume.brand,
                        imageUrl: perfume.imageUrl,
                        mainAccords: perfume.mainAccords,
                        accordStrengths: perfume.mainAccordStrengths,
                        memo: memo,
                        createdAt: Date(),
                        topNotes: perfume.topNotes,
                        middleNotes: perfume.middleNotes,
                        baseNotes: perfume.baseNotes,
                        generalNotes: perfume.generalNotes,
                        seasonRanking: perfume.seasonRanking,
                        concentration: perfume.concentration,
                        longevity: perfume.longevity,
                        sillage: perfume.sillage,
                        usageStatus: registrationInfo?.usageStatus,
                        usageFrequency: registrationInfo?.usageFrequency,
                        preferenceLevel: registrationInfo?.preferenceLevel,
                        registrationEditCount: 0
                    )
                    self.cacheStore.upsert(cachedPerfume)
                    Self.upsertCollectionCache(cachedPerfume)
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    static func cachedCollection() -> [CollectedPerfume]? {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }

        guard let cache = collectionMemoryCache else { return nil }
        guard Date().timeIntervalSince(cache.timestamp) < memoryCacheTTL else {
            collectionMemoryCache = nil
            return nil
        }
        return cache.value
    }

    static func storeCollectionCache(_ collection: [CollectedPerfume]) {
        memoryCacheLock.lock()
        collectionMemoryCache = (collection, Date())
        memoryCacheLock.unlock()
    }

    static func upsertCollectionCache(_ perfume: CollectedPerfume) {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }

        guard var cache = collectionMemoryCache else { return }
        cache.value.removeAll { $0.id == perfume.id }
        cache.value.insert(perfume, at: 0)
        cache.timestamp = Date()
        collectionMemoryCache = cache
    }

    static func removeCollectionCacheItem(id: String) {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }

        guard var cache = collectionMemoryCache else { return }
        cache.value.removeAll { $0.id == id }
        cache.timestamp = Date()
        collectionMemoryCache = cache
    }

    static func invalidateCollectionCache() {
        memoryCacheLock.lock()
        collectionMemoryCache = nil
        memoryCacheLock.unlock()
    }

    static func cachedLikedPerfumes() -> [LikedPerfume]? {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }

        guard let cache = likedMemoryCache else { return nil }
        guard Date().timeIntervalSince(cache.timestamp) < memoryCacheTTL else {
            likedMemoryCache = nil
            return nil
        }
        return cache.value
    }

    static func storeLikedCache(_ perfumes: [LikedPerfume]) {
        memoryCacheLock.lock()
        likedMemoryCache = (perfumes, Date())
        memoryCacheLock.unlock()
    }

    static func invalidateLikedCache() {
        memoryCacheLock.lock()
        likedMemoryCache = nil
        memoryCacheLock.unlock()
    }
}
