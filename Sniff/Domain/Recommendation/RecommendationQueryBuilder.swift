//
//  RecommendationQueryBuilder.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation
import Combine

struct RecommendationQueryBuilder {

    func buildQueries(from profile: UserTasteProfile) -> [String] {
        buildSearchTerms(from: profile)
    }

    private func mapFamilyToSearchQueries(_ family: String) -> [String] {
        OnboardingTagMapper.searchKeywordsForFamily(family)
    }

    private func buildSearchTerms(from profile: UserTasteProfile) -> [String] {
        let mapped = profile.preferredFamilies.flatMap(mapFamilyToSearchQueries(_:))
        let unique = uniquePreservingOrder(mapped)
        let terms = Array(unique.prefix(3))

        if !terms.isEmpty {
            return terms
        }

        if let impression = profile.preferredImpressions.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !impression.isEmpty {
            return [impression]
        }

        return ["perfume"]
    }

    private func uniquePreservingOrder(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
