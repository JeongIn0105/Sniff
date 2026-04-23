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
            return "\(strongestMatchedFamily) 계열 선호가 반영된 추천이에요"
        }

        if let impression = profile.preferredImpressions.first {
            return "\(impression) 인상을 살리기 좋은 추천이에요"
        }

        if profile.intensityLevel.contains("강") {
            return "진하고 존재감 있는 무드 선호를 반영한 추천이에요"
        }

        if profile.intensityLevel.contains("약") {
            return "가볍고 산뜻한 무드 선호를 반영한 추천이에요"
        }

        if let fallbackFamily = families.first {
            return "\(fallbackFamily) 무드가 현재 취향과 잘 맞아요"
        }

        return "\(profile.primaryProfileName) 취향 흐름을 반영한 추천이에요"
    }
}
