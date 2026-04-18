//
//  FetchHomeFeedUseCase.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

typealias HomeFeedData = (
    tasteAnalysis: TasteAnalysisResult,
    collection: [CollectedPerfume],
    tastingRecords: [TastingRecord]
)

protocol FetchHomeFeedUseCaseType {
    func execute() -> Single<HomeFeedData>
}

final class FetchHomeFeedUseCase: FetchHomeFeedUseCaseType {

    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType

    init(
        userTasteRepository: UserTasteRepositoryType,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType
    ) {
        self.userTasteRepository = userTasteRepository
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
    }

    func execute() -> Single<HomeFeedData> {
        Single.zip(
            userTasteRepository.fetchTasteAnalysis(),
            collectionRepository.fetchCollection().catchAndReturn([]),
            tastingRecordRepository.fetchTastingRecords().catchAndReturn([])
        )
        .map { tasteAnalysis, collection, tastingRecords in
            (
                tasteAnalysis: tasteAnalysis,
                collection: collection,
                tastingRecords: tastingRecords
            )
        }
    }
}
