//
//  RecommendationModels.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

import Foundation

struct RecommendationResult {
    let profile: UserTasteProfile
    let perfumes: [RecommendedPerfume]
}

struct RecommendedPerfume {
    let perfume: FragellaPerfume
    let score: Double
    let reason: String
}
