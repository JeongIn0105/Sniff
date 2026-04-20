//
//  TastingRecordRepository.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

final class TastingRecordRepository: TastingRecordRepositoryType {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService? = nil) {
        self.firestoreService = firestoreService ?? .shared
    }

    func fetchTastingRecords() -> Single<[TastingRecord]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(AppSecretsError.missingValue("FIRESTORE_SERVICE")))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let records = try await self.firestoreService.fetchTastingRecords()
                    single(.success(records))
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
