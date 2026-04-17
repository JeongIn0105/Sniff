//
//  RecommendationEngine.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

final class RecommendationEngine {

    private let aggregator = PreferenceAggregator()
    private let queryBuilder = RecommendationQueryBuilder()
    let scorer = PerfumeScorer()

    func recommend(
        onboarding: TasteAnalysisResult,
        collection: [CollectedPerfume],
        tastingRecords: [TastingRecord]
    ) -> Single<RecommendationResult> {

        let profile = aggregator.aggregate(
            onboarding: onboarding,
            collection: collection,
            tastingRecords: tastingRecords
        )

        let queries = queryBuilder.buildQueries(from: profile)
        let searchRequests = queries.map {
            FragellaService.shared
                .search(query: $0, limit: 10)
                .catchAndReturn([])
        }

        return Single.zip(searchRequests)
            .map { [weak self] responses in
                guard let self else {
                    return RecommendationResult(profile: profile, perfumes: [])
                }

                let flattenedPerfumes = responses.flatMap { $0 }
                let uniquePerfumes = self.uniquePerfumes(from: flattenedPerfumes)
                let candidatePerfumes = uniquePerfumes.isEmpty
                    ? self.fallbackPerfumes(for: profile)
                    : uniquePerfumes

                let recommendations = candidatePerfumes
                    .map { self.makeRecommendedPerfume(from: $0, profile: profile) }
                    .sorted { lhs, rhs in
                        if lhs.score == rhs.score {
                            return lhs.perfume.name < rhs.perfume.name
                        }
                        return lhs.score > rhs.score
                    }

                return RecommendationResult(
                    profile: profile,
                    perfumes: Array(recommendations.prefix(10))
                )
            }
    }
}
