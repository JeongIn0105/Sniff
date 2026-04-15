//
//  RecommendationQueryBuilder.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation

struct RecommendationQueryBuilder {

    func buildQueries(from profile: UserTasteProfile) -> [String] {
        let mapped = profile.preferredFamilies.map(mapFamilyToQuery(_:))
        let unique = Array(Set(mapped))
        return Array(unique.prefix(5))
    }

    private func mapFamilyToQuery(_ family: String) -> String {
        switch family {
            case "Fresh": return "fresh"
            case "Citrus": return "citrus"
            case "Water": return "aquatic"
            case "Green": return "green"
            case "Floral": return "floral"
            case "Soft Floral": return "soft floral"
            case "Fruity": return "fruity"
            case "Amber": return "amber"
            case "Woody": return "woody"
            case "Woody Amber": return "woody"
            case "Dry Woods": return "dry woods"
            case "Mossy Woods": return "mossy woods"
            case "Aromatic": return "aromatic"
            default: return "perfume"
        }
    }
}
