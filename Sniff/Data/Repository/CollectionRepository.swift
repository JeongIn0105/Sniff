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

    init(firestoreService: FirestoreService? = nil) {
        self.firestoreService = firestoreService ?? .shared
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
                    single(.success(collection))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
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
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
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
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
