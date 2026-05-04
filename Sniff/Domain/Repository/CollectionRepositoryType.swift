//
//  CollectionRepositoryType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol CollectionRepositoryType {
    func fetchCollection() -> Single<[CollectedPerfume]>
    func currentMonthlyCollectionUsage() -> Int
    var monthlyCollectionLimit: Int { get }
    func saveCollectedPerfume(_ perfume: Perfume, memo: String?) -> Completable
    func saveCollectedPerfume(_ perfume: Perfume, registrationInfo: CollectedPerfumeRegistrationInfo) -> Completable
    func deleteCollectedPerfume(id: String) -> Completable
    func fetchLikedPerfumes() -> Single<[LikedPerfume]>
    func saveLikedPerfume(_ perfume: Perfume) -> Completable
    func deleteLikedPerfume(id: String) -> Completable
    func deleteCollectionItems(ids: [String]) async throws
}
