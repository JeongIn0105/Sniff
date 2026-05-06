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
            reason: makeRecommendationReason(for: perfume, profile: profile, role: .taste)
        )
    }

    func makePopularRecommendedPerfume(
        from perfume: Perfume,
        profile: UserTasteProfile
    ) -> RecommendedPerfume {
        RecommendedPerfume(
            perfume: perfume,
            score: scorer.score(perfume: perfume, profile: profile),
            reason: makeRecommendationReason(for: perfume, profile: profile, role: .popular)
        )
    }

    func makeRecommendationReason(
        for perfume: Perfume,
        profile: UserTasteProfile,
        role: RecommendationReasonRole = .taste
    ) -> String {
        let families = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)
        let noteFamilies = Set(
            NoteToFamilyMapper.noteVector(
                topNotes: perfume.topNotes,
                middleNotes: perfume.middleNotes,
                baseNotes: perfume.baseNotes,
                generalNotes: perfume.generalNotes
            ).keys
        )

        let strongestMatchedFamily = families
            .filter { profile.preferredFamilies.contains($0) }
            .max { lhs, rhs in
                let lhsScore = profile.familyScores[lhs, default: 0] * (perfume.mainAccordStrengths[lhs]?.weight ?? 0)
                let rhsScore = profile.familyScores[rhs, default: 0] * (perfume.mainAccordStrengths[rhs]?.weight ?? 0)
                return lhsScore < rhsScore
            }

        if let strongestMatchedFamily {
            let family = PerfumeKoreanTranslator.koreanFamily(for: strongestMatchedFamily)
            if role == .popular, koreaBrandAvailabilityScore(for: perfume) >= 55 {
                return "\(family) 취향에 맞으면서 국내 접근성도 좋아 시도해보기 쉬워요"
            }
            return "\(family) 계열이 현재 취향과 가장 잘 맞아서 추천했어요"
        }

        if let noteFamily = profile.preferredFamilies.first(where: { noteFamilies.contains($0) }) {
            let family = PerfumeKoreanTranslator.koreanFamily(for: noteFamily)
            if role == .popular {
                return "노트에서 \(family) 무드가 보이고, 대중성도 함께 고려했어요"
            }
            return "노트 구성에서 \(family) 무드가 보여 취향과 잘 맞아요"
        }

        if role == .popular {
            if let releaseYear = perfume.releaseYear, releaseYear >= Calendar.current.component(.year, from: Date()) - 3 {
                return "최근 출시 흐름과 취향 점수를 함께 보고 골랐어요"
            }
            if normalizedPopularity(for: perfume) >= 0.45 {
                return "인기도가 높고 취향 흐름에서도 무리 없이 이어져요"
            }
        }

        if koreaBrandAvailabilityScore(for: perfume) > 0 {
            return "국내에서 찾기 쉬운 브랜드라 취향에 맞는 향을 시도해보기 좋아요"
        }

        if let impression = profile.preferredImpressions.first {
            return "\(impression) 느낌을 원하신 선택이 반영된 추천이에요"
        }

        if profile.intensityLevel.contains("강") {
            return AppStrings.Recommendation.strongPresence
        }

        if profile.intensityLevel.contains("약") {
            return AppStrings.Recommendation.lightFresh
        }

        if let fallbackFamily = families.first {
            let family = PerfumeKoreanTranslator.koreanFamily(for: fallbackFamily)
            return "\(family) 무드가 취향 흐름과 자연스럽게 이어져요"
        }

        return AppStrings.Recommendation.profileFlow(profile.displayTitle)
    }

    private func koreaBrandAvailabilityScore(for perfume: Perfume) -> Int {
        PerfumeKoreanTranslator.koreaBrandAvailabilityScore(for: perfume)
    }

    private func normalizedPopularity(for perfume: Perfume) -> Double {
        if let popularity = perfume.popularity {
            if popularity > 100 { return 1 }
            if popularity > 1 { return min(1, popularity / 100) }
            return max(0, popularity)
        }

        return 0
    }
}

enum RecommendationReasonRole {
    case taste
    case popular
}
