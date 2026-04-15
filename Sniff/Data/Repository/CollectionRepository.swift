//
//  CollectionRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

protocol CollectionRepositoryType {
    func fetchCollection() -> Single<[CollectedPerfume]>
}

final class CollectionRepository: CollectionRepositoryType {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
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
}
