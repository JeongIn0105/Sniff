//
//  TasteAnalysisResult.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

struct TasteAnalysisResult: Codable {
    let analysisSummary: String
    let evidenceTags: EvidenceTags
    let recommendationDirection: RecommendationDirection

    enum CodingKeys: String, CodingKey {
        case analysisSummary = "analysis_summary"
        case evidenceTags = "evidence_tags"
        case recommendationDirection = "recommendation_direction"
    }

    enum LegacyCodingKeys: String, CodingKey {
        case primaryProfileCode = "primary_profile_code"
        case primaryProfileName = "primary_profile_name"
        case secondaryProfileCode = "secondary_profile_code"
        case secondaryProfileName = "secondary_profile_name"
    }

    init(
        analysisSummary: String,
        evidenceTags: EvidenceTags,
        recommendationDirection: RecommendationDirection
    ) {
        self.analysisSummary = analysisSummary
        self.evidenceTags = evidenceTags
        self.recommendationDirection = recommendationDirection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _ = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        analysisSummary = try container.decode(String.self, forKey: .analysisSummary)
        evidenceTags = try container.decode(EvidenceTags.self, forKey: .evidenceTags)
        recommendationDirection = try container.decode(
            RecommendationDirection.self,
            forKey: .recommendationDirection
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(analysisSummary, forKey: .analysisSummary)
        try container.encode(evidenceTags, forKey: .evidenceTags)
        try container.encode(recommendationDirection, forKey: .recommendationDirection)
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
