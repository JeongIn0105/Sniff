//
//  RecommendationEngine+Scoring.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

import Foundation

extension RecommendationEngine {

    func makeRecommendedPerfume(
        from perfume: Perfume,
        profile: UserTasteProfile
    ) -> RecommendedPerfume {
        RecommendedPerfume(
            perfume: perfume,
            score: scorer.score(perfume: perfume, profile: profile),
            reason: makeRecommendationReason(for: perfume, profile: profile)
        )
    }

    func makeRecommendationReason(
        for perfume: Perfume,
        profile: UserTasteProfile
    ) -> String {
        let families = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)

        let strongestMatchedFamily = families
            .filter { profile.preferredFamilies.contains($0) }
            .max { lhs, rhs in
                let lhsScore = profile.familyScores[lhs, default: 0] * (perfume.mainAccordStrengths[lhs]?.weight ?? 0)
                let rhsScore = profile.familyScores[rhs, default: 0] * (perfume.mainAccordStrengths[rhs]?.weight ?? 0)
                return lhsScore < rhsScore
            }

        if let strongestMatchedFamily {
            return AppStrings.Recommendation.familyPreference(strongestMatchedFamily)
        }

        if let impression = profile.preferredImpressions.first {
            return AppStrings.Recommendation.impressionPreference(impression)
        }

        if profile.intensityLevel.contains("강") {
            return AppStrings.Recommendation.strongPresence
        }

        if profile.intensityLevel.contains("약") {
            return AppStrings.Recommendation.lightFresh
        }

        if let fallbackFamily = families.first {
            return AppStrings.Recommendation.familyMoodMatch(fallbackFamily)
        }

        return AppStrings.Recommendation.profileFlow(profile.displayTitle)
    }
}
