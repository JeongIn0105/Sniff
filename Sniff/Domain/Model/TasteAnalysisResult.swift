//
//  TasteAnalysisResult.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

struct TasteAnalysisResult: Codable {
    let primaryProfileCode: String
    let primaryProfileName: String
    let secondaryProfileCode: String
    let secondaryProfileName: String
    let analysisSummary: String
    let evidenceTags: EvidenceTags
    let recommendationDirection: RecommendationDirection
    
    enum CodingKeys: String, CodingKey {
        case primaryProfileCode = "primary_profile_code"
        case primaryProfileName = "primary_profile_name"
        case secondaryProfileCode = "secondary_profile_code"
        case secondaryProfileName = "secondary_profile_name"
        case analysisSummary = "analysis_summary"
        case evidenceTags = "evidence_tags"
        case recommendationDirection = "recommendation_direction"
    }
}

struct EvidenceTags: Codable {
    let experience: String
    let vibes: [String]
    let images: [String]
}

struct RecommendationDirection: Codable {
    let preferredImpression: [String]
    let preferredFamilies: [String]
    let intensityLevel: String
    let safeStartingPoint: String
    
    enum CodingKeys: String, CodingKey {
        case preferredImpression = "preferred_impression"
        case preferredFamilies = "preferred_families"
        case intensityLevel = "intensity_level"
        case safeStartingPoint = "safe_starting_point"
    }
}
