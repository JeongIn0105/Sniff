//
//  RecommendationEngine.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import CryptoKit
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
    private let cacheStore: RecommendationResultCacheStoreType

    init(
        perfumeCatalogRepository: PerfumeCatalogRepositoryType,
        cacheStore: RecommendationResultCacheStoreType = RecommendationResultCacheStore()
    ) {
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.cacheStore = cacheStore
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
        let ownedExclusion = OwnedPerfumeRecommendationExclusion(
            collection: collection
        )
        let cacheKey = RecommendationCacheKeyBuilder.makeKey(
            profile: profile,
            queries: queries,
            ownedPerfumeKeys: ownedExclusion.cacheKeys
        )
        if let cachedResult = cacheStore.loadResult(forKey: cacheKey) {
            return .just(cachedResult)
        }

        let searchRequests = queries.map { query in
            perfumeCatalogRepository.search(query: query, limit: 30)
                .catchAndReturn([])
        }

        return Single.zip(searchRequests)
            .map { [weak self] responses in
                guard let self else {
                    return RecommendationResult(profile: profile, perfumes: [], popularPerfumes: [])
                }

                let flattenedPerfumes = responses.flatMap { $0 }
                let uniquePerfumes = self.uniquePerfumes(from: flattenedPerfumes)
                    .filter { !ownedExclusion.contains($0) }
                guard !uniquePerfumes.isEmpty else {
                    return RecommendationResult(profile: profile, perfumes: [], popularPerfumes: [])
                }

                let recommendations = uniquePerfumes
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
                let visibleTasteKeys = tasteRecommendations
                    .prefix(5)
                    .reduce(into: Set<String>()) { result, recommendation in
                        result.formUnion(self.dedupeKeys(for: recommendation.perfume))
                    }
                let popularCandidates = self.popularRecommendationCandidates(
                    from: tasteQualifiedRecommendations,
                    excluding: visibleTasteKeys,
                    profile: profile
                )
                let popularRecommendations = popularCandidates
                    .filter { visibleTasteKeys.isDisjoint(with: self.dedupeKeys(for: $0.perfume)) }
                    .sorted { lhs, rhs in
                        let lhsScore = self.accessibleTasteScore(lhs, profile: profile)
                        let rhsScore = self.accessibleTasteScore(rhs, profile: profile)
                        if lhsScore == rhsScore {
                            return lhs.perfume.name < rhs.perfume.name
                        }
                        return lhsScore > rhsScore
                    }

                let result = RecommendationResult(
                    profile: profile,
                    perfumes: tasteRecommendations,
                    popularPerfumes: self.limitBrandDuplication(
                        popularRecommendations,
                        maxPerBrand: 2,
                        limit: 10
                    )
                )

                if !result.perfumes.isEmpty || !result.popularPerfumes.isEmpty {
                    self.cacheStore.save(result, forKey: cacheKey)
                    return result
                }

                return result
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

    private func popularRecommendationCandidates(
        from recommendations: [RecommendedPerfume],
        excluding visibleTasteKeys: Set<String>,
        profile: UserTasteProfile
    ) -> [RecommendedPerfume] {
        let remainingRecommendations = recommendations
            .filter { visibleTasteKeys.isDisjoint(with: dedupeKeys(for: $0.perfume)) }
        let roleMatchedRecommendations = remainingRecommendations.filter {
            normalizedAvailability(for: $0.perfume) >= 0.45
                || normalizedPopularity(for: $0.perfume) >= 0.45
                || recentLaunchScore(for: $0.perfume) >= 0.70
        }
        let selectedRecommendations = roleMatchedRecommendations.count >= 5
            ? roleMatchedRecommendations
            : remainingRecommendations

        return selectedRecommendations.map {
            makePopularRecommendedPerfume(from: $0.perfume, profile: profile)
        }
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

    private func dedupeKeys(for perfume: Perfume) -> Set<String> {
        RecommendationPerfumeIdentity.keys(for: perfume)
    }
}

struct OwnedPerfumeRecommendationExclusion {
    let cacheKeys: [String]
    private let ownedKeys: Set<String>

    init(
        collection: [CollectedPerfume]
    ) {
        var keys = Set<String>()

        collection.forEach {
            keys.formUnion(RecommendationPerfumeIdentity.keys(id: $0.id, name: $0.name, brand: $0.brand))
        }

        self.ownedKeys = keys
        self.cacheKeys = keys.sorted()
    }

    func contains(_ perfume: Perfume) -> Bool {
        !ownedKeys.isDisjoint(with: RecommendationPerfumeIdentity.keys(for: perfume))
    }
}

enum RecommendationPerfumeIdentity {
    static func keys(for perfume: Perfume) -> Set<String> {
        var keys = keys(id: perfume.id, name: perfume.name, brand: perfume.brand)

        nameVariants(for: perfume).forEach { name in
            brandVariants(for: perfume).forEach { brand in
                keys.insert(recordKey(name: name, brand: brand))
                keys.insert(coreRecordKey(name: name, brand: brand))
            }
        }

        return Set(keys.filter { !$0.isEmpty })
    }

    static func keys(id: String, name: String, brand: String) -> Set<String> {
        var keys = Set<String>()
        keys.insert(normalizedID(id))
        keys.insert(normalizedID(Perfume.collectionDocumentID(from: id)))
        keys.formUnion(recordKeys(name: name, brand: brand))
        return Set(keys.filter { !$0.isEmpty })
    }

    static func recordKeys(name: String, brand: String) -> Set<String> {
        var keys = Set<String>()
        let nameVariants = [
            name,
            PerfumeKoreanTranslator.koreanPerfumeName(for: name)
        ]
        let brandVariants = [
            brand,
            PerfumeKoreanTranslator.koreanBrand(for: brand)
        ]

        nameVariants.forEach { name in
            brandVariants.forEach { brand in
                keys.insert(recordKey(name: name, brand: brand))
                keys.insert(coreRecordKey(name: name, brand: brand))
            }
        }

        return Set(keys.filter { !$0.isEmpty })
    }

    private static func recordKey(name: String, brand: String) -> String {
        "\(normalizeText(brand))|\(normalizeText(name))"
    }

    private static func coreRecordKey(name: String, brand: String) -> String {
        "\(normalizeText(brand))|\(normalizePerfumeNameCore(name))"
    }

    private static func nameVariants(for perfume: Perfume) -> [String] {
        var variants = [perfume.name]
        variants.append(contentsOf: perfume.nameAliases)
        variants.append(PerfumeKoreanTranslator.koreanPerfumeName(for: perfume.name))
        return uniqueNonEmpty(variants)
    }

    private static func brandVariants(for perfume: Perfume) -> [String] {
        var variants = [perfume.brand]
        variants.append(contentsOf: perfume.brandAliases)
        variants.append(PerfumeKoreanTranslator.koreanBrand(for: perfume.brand))
        return uniqueNonEmpty(variants)
    }

    private static func uniqueNonEmpty(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter {
            let key = normalizeText($0)
            guard !key.isEmpty else { return false }
            return seen.insert(key).inserted
        }
    }

    private static func normalizedID(_ value: String) -> String {
        normalizeText(value)
    }

    private static func normalizeText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private static func normalizePerfumeNameCore(_ value: String) -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")

        let noisePatterns = [
            "\\([^)]*\\)",
            "\\[[^]]*\\]",
            "\\b(eau de parfum|eau de toilette|eau de cologne|extrait de parfum|parfum|edp|edt|edc)\\b",
            "\\b(for women|for men|women|men|woman|man|unisex|pour femme|pour homme|homme|femme)\\b"
        ]

        let stripped = noisePatterns.reduce(normalized) { result, pattern in
            result.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }

        return stripped
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined()
    }
}

private enum RecommendationCacheKeyBuilder {
    static func makeKey(
        profile: UserTasteProfile,
        queries: [String],
        ownedPerfumeKeys: [String]
    ) -> String {
        let payload = [
            "algorithm:owned-exclusion-v6",
            "stage:\(profile.stage.rawValue)",
            "title:\(normalized(profile.tasteTitle ?? ""))",
            "summary:\(normalized(profile.analysisSummary))",
            "impressions:\(normalizedList(profile.preferredImpressions))",
            "families:\(normalizedList(profile.preferredFamilies))",
            "disliked:\(normalizedList(profile.dislikedFamilies))",
            "intensity:\(normalized(profile.intensityLevel))",
            "safe:\(normalized(profile.safeStartingPoint))",
            "scores:\(normalizedScores(profile.familyScores))",
            "vector:\(normalizedScores(profile.scentVector))",
            "queries:\(normalizedList(queries))",
            "owned:\(normalizedList(ownedPerfumeKeys))"
        ].joined(separator: "\u{1F}")

        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func normalizedList(_ values: [String]) -> String {
        values.map(normalized(_:)).joined(separator: "|")
    }

    private static func normalizedScores(_ scores: [String: Double]) -> String {
        scores
            .sorted { lhs, rhs in normalized(lhs.key) < normalized(rhs.key) }
            .map { key, value in
                "\(normalized(key)):\(String(format: "%.5f", value))"
            }
            .joined(separator: "|")
    }
}
