//
//  PerfumeScorer.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//


import Foundation

struct PerfumeScoreBreakdown {
    let familyScores: [(family: String, profileScore: Double, accordWeight: Double, weightedScore: Double)]
    let intensityBonus: Double
    let total: Double
}

struct PerfumeScorer {

    func score(
        perfume: FragellaPerfume,
        profile: UserTasteProfile
    ) -> Double {
        breakdown(perfume: perfume, profile: profile).total
    }

    func breakdown(
        perfume: FragellaPerfume,
        profile: UserTasteProfile
    ) -> PerfumeScoreBreakdown {
        let families = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)

            // 향수 accord 가중치 정규화 (합 = 1.0)
        let rawAccordWeights = families.reduce(into: [String: Double]()) { dict, family in
            dict[family] = perfume.mainAccordStrengths[family]?.weight ?? AccordStrength.subtle.weight
        }
        let accordTotal = rawAccordWeights.values.reduce(0, +)
        let normalizedAccordWeights: [String: Double] = accordTotal > 0
        ? rawAccordWeights.mapValues { $0 / accordTotal }
        : rawAccordWeights

            // scentVector (정규화 취향 벡터) × normalizedAccordWeights = 코사인 유사도 근사
        let familyScores = families.map { family -> (family: String, profileScore: Double, accordWeight: Double, weightedScore: Double) in
            let profileScore = profile.scentVector[family, default: 0]
            let accordWeight = normalizedAccordWeights[family, default: 0]
            return (
                family: family,
                profileScore: profileScore,
                accordWeight: accordWeight,
                weightedScore: profileScore * accordWeight
            )
        }

            // 강도 보너스 — scentVector 기반으로 조정
        var intensityBonus: Double = 0
        let woodyFamilySet: Set<String> = ["Amber", "Woody", "Woody Amber", "Dry Woods"]
        let freshFamilySet: Set<String> = ["Fresh", "Citrus", "Water"]

        if profile.intensityLevel.contains("강") {
            let woodyScore = familyScores
                .filter { woodyFamilySet.contains($0.family) }
                .map { $0.weightedScore }
                .reduce(0, +)
            if woodyScore > 0 { intensityBonus += 0.1 * woodyScore }
        }

        if profile.intensityLevel.contains("약") {
            let freshScore = familyScores
                .filter { freshFamilySet.contains($0.family) }
                .map { $0.weightedScore }
                .reduce(0, +)
            if freshScore > 0 { intensityBonus += 0.1 * freshScore }
        }

        let total = familyScores.reduce(0) { $0 + $1.weightedScore } + intensityBonus

        return PerfumeScoreBreakdown(
            familyScores: familyScores,
            intensityBonus: intensityBonus,
            total: total
        )
    }
}
