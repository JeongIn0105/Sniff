//
//  RecommendPerfumesUseCase.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol RecommendPerfumesUseCaseType {
    func execute(
        onboarding: TasteAnalysisResult,
        collection: [CollectedPerfume],
        tastingRecords: [TastingRecord]
    ) -> Single<RecommendationResult>
}

final class RecommendPerfumesUseCase: RecommendPerfumesUseCaseType {

    private let recommendationEngine: RecommendationEngine

    init(recommendationEngine: RecommendationEngine) {
        self.recommendationEngine = recommendationEngine
    }

    func execute(
        onboarding: TasteAnalysisResult,
        collection: [CollectedPerfume],
        tastingRecords: [TastingRecord]
    ) -> Single<RecommendationResult> {
        recommendationEngine.recommend(
            onboarding: onboarding,
            collection: collection,
            tastingRecords: tastingRecords
        )
    }
}
