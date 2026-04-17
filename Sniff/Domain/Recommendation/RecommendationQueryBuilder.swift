//
//  RecommendationQueryBuilder.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation

struct RecommendationQueryBuilder {

    func buildQueries(from profile: UserTasteProfile) -> [String] {
        buildSearchTerms(from: profile)
    }

    private func mapFamilyToSearchQueries(_ family: String) -> [String] {
        switch family {
        case "Fresh": return ["fresh", "citrus"]
        case "Citrus": return ["citrus", "fresh"]
        case "Water": return ["aquatic", "fresh"]
        case "Green": return ["green", "woody"]
        case "Floral": return ["floral"]
        case "Soft Floral": return ["soft floral", "floral"]
        case "Fruity": return ["fruity", "floral"]
        case "Amber": return ["amber"]
        case "Woody": return ["woody"]
        case "Woody Amber": return ["woody", "amber"]
        case "Dry Woods": return ["dry woods", "woody"]
        case "Mossy Woods": return ["mossy woods", "woody"]
        case "Aromatic": return ["aromatic", "fresh"]
        case "Musk": return ["musk", "soft floral"]
        default: return []
        }
    }

    private func buildSearchTerms(from profile: UserTasteProfile) -> [String] {
        let mapped = profile.preferredFamilies.flatMap(mapFamilyToSearchQueries(_:))
        let unique = uniquePreservingOrder(mapped)
        let terms = Array(unique.prefix(5))

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
