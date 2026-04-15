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
    private let scorer = PerfumeScorer()

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

        let requests = queries.map {
            FragellaService.shared.search(query: $0, limit: 10)
        }

        return Single.zip(requests)
            .map { $0.flatMap { $0 } }
            .map { perfumes in
                Dictionary(grouping: perfumes, by: { $0.id })
                    .compactMap { $0.value.first }
            }
            .map { perfumes in
                perfumes.sorted {
                    self.scorer.score(perfume: $0, profile: profile)
                    >
                    self.scorer.score(perfume: $1, profile: profile)
                }
            }
            .map { sorted in
                RecommendationResult(
                    profile: profile,
                    perfumes: Array(sorted.prefix(10))
                )
            }
    }
}

struct RecommendationResult {
    let profile: UserTasteProfile
    let perfumes: [FragellaPerfume]
}
