//
//  RecommendationModels.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

import Foundation

struct RecommendationResult: Codable {
    let profile: UserTasteProfile
    let perfumes: [RecommendedPerfume]
    let popularPerfumes: [RecommendedPerfume]
}

struct RecommendedPerfume: Codable {
    let perfume: Perfume
    let score: Double
    let reason: String
}

protocol RecommendationResultCacheStoreType {
    func loadResult(forKey key: String) -> RecommendationResult?
    func save(_ result: RecommendationResult, forKey key: String)
}

final class RecommendationResultCacheStore: RecommendationResultCacheStoreType {
    private let storageKey: String
    private let defaults: UserDefaults
    private let maxEntries: Int

    init(
        storageKey: String = "sniff.recommendation.results.v1",
        defaults: UserDefaults = .standard,
        maxEntries: Int = 12
    ) {
        self.storageKey = storageKey
        self.defaults = defaults
        self.maxEntries = maxEntries
    }

    func loadResult(forKey key: String) -> RecommendationResult? {
        loadCache()[key]?.result
    }

    func save(_ result: RecommendationResult, forKey key: String) {
        let now = Date()
        var cache = loadCache()

        cache[key] = CachedRecommendationResult(
            result: result,
            createdAt: now
        )

        trimCache(&cache)
        saveCache(cache)
    }

    private func loadCache() -> [String: CachedRecommendationResult] {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([String: CachedRecommendationResult].self, from: data)
        else {
            return [:]
        }

        return decoded
    }

    private func saveCache(_ cache: [String: CachedRecommendationResult]) {
        guard let encoded = try? JSONEncoder().encode(cache) else { return }
        defaults.set(encoded, forKey: storageKey)
    }

    private func trimCache(_ cache: inout [String: CachedRecommendationResult]) {
        guard cache.count > maxEntries else { return }

        let keysToRemove = cache
            .sorted { lhs, rhs in lhs.value.createdAt < rhs.value.createdAt }
            .prefix(cache.count - maxEntries)
            .map(\.key)

        keysToRemove.forEach { cache[$0] = nil }
    }
}

private struct CachedRecommendationResult: Codable {
    let result: RecommendationResult
    let createdAt: Date
}
