//
//  RecommendationEngine.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import RxSwift

final class RecommendationEngine {
    private enum ScoringPolicy {
        static let minimumTasteMatchScore = 0.18
        static let minimumTasteQualifiedCount = 5
    }

    private let aggregator = PreferenceAggregator()
    private let queryBuilder = RecommendationQueryBuilder()
    let scorer = PerfumeScorer()
    private let perfumeCatalogRepository: PerfumeCatalogRepositoryType

    init(perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeCatalogRepository = perfumeCatalogRepository
    }

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
            perfumeCatalogRepository
                .search(query: $0, limit: 30)
                .catchAndReturn([])
        }

        return Single.zip(searchRequests)
            .map { [weak self] responses in
                guard let self else {
                    return RecommendationResult(profile: profile, perfumes: [], popularPerfumes: [])
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
                let tasteQualifiedRecommendations = self.tasteQualifiedRecommendations(
                    recommendations,
                    profile: profile
                )

                let tasteRecommendations = self.limitBrandDuplication(
                    tasteQualifiedRecommendations,
                    maxPerBrand: 2,
                    limit: 10
                )
                let visibleTasteIDs = Set(tasteRecommendations.prefix(5).map { self.dedupeKey(for: $0.perfume) })
                let popularRecommendations = tasteQualifiedRecommendations
                    .filter { !visibleTasteIDs.contains(self.dedupeKey(for: $0.perfume)) }
                    .sorted { lhs, rhs in
                        let lhsScore = self.accessibleTasteScore(lhs, profile: profile)
                        let rhsScore = self.accessibleTasteScore(rhs, profile: profile)
                        if lhsScore == rhsScore {
                            return lhs.perfume.name < rhs.perfume.name
                        }
                        return lhsScore > rhsScore
                    }

                return RecommendationResult(
                    profile: profile,
                    perfumes: tasteRecommendations,
                    popularPerfumes: self.limitBrandDuplication(
                        popularRecommendations,
                        maxPerBrand: 2,
                        limit: 10
                    )
                )
            }
    }

    private func accessibleTasteScore(
        _ recommendation: RecommendedPerfume,
        profile: UserTasteProfile
    ) -> Double {
        let tasteScore = scorer.tasteMatchScore(perfume: recommendation.perfume, profile: profile)
        return normalizedAvailability(for: recommendation.perfume) * 45
            + recentLaunchScore(for: recommendation.perfume) * 35
            + tasteScore * 15
            + normalizedPopularity(for: recommendation.perfume) * 5
    }

    private func tasteQualifiedRecommendations(
        _ recommendations: [RecommendedPerfume],
        profile: UserTasteProfile
    ) -> [RecommendedPerfume] {
        let qualified = recommendations.filter {
            scorer.tasteMatchScore(perfume: $0.perfume, profile: profile) >= ScoringPolicy.minimumTasteMatchScore
        }

        return qualified.count >= ScoringPolicy.minimumTasteQualifiedCount
            ? qualified
            : recommendations
    }

    private func normalizedPopularity(for perfume: Perfume) -> Double {
        if let popularity = perfume.popularity {
            if popularity > 100 { return 1 }
            if popularity > 1 { return min(1, popularity / 100) }
            return max(0, popularity)
        }

        return 0
    }

    private func normalizedAvailability(for perfume: Perfume) -> Double {
        min(1.0, Double(PerfumeKoreanTranslator.koreaBrandAvailabilityScore(for: perfume)) / 100.0)
    }

    private func recentLaunchScore(for perfume: Perfume) -> Double {
        guard let releaseYear = perfume.releaseYear else {
            return 0.35
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        let age = max(0, currentYear - releaseYear)
        switch age {
        case 0...1:
            return 1
        case 2:
            return 0.85
        case 3:
            return 0.7
        case 4:
            return 0.55
        case 5:
            return 0.4
        default:
            return 0.2
        }
    }

    private func limitBrandDuplication(
        _ recommendations: [RecommendedPerfume],
        maxPerBrand: Int,
        limit: Int
    ) -> [RecommendedPerfume] {
        var counts: [String: Int] = [:]
        var result: [RecommendedPerfume] = []

        for recommendation in recommendations {
            let key = recommendation.perfume.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard counts[key, default: 0] < maxPerBrand else { continue }
            counts[key, default: 0] += 1
            result.append(recommendation)
            if result.count == limit { break }
        }

        return result
    }

    private func dedupeKey(for perfume: Perfume) -> String {
        "\(perfume.brand)|\(perfume.name)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
