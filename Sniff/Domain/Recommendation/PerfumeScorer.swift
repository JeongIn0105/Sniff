//
//  PerfumeScorer.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//


    //
    //  PerfumeScorer.swift
    //  Sniff
    //
    //  노트 유사도 레이어가 추가된 버전.
    //
    //  점수 계산은 세 레이어의 합주야:
    //
    //    1. Accord 레이어 (주선율, 80% 비중)
    //       accord 강도 × 사용자 취향 벡터 → 코사인 유사도 근사
    //
    //    2. Note 레이어 (보조 선율, 20% 비중)
    //       top/middle/base note를 계열로 매핑 → 위치별 가중치 적용
    //       Base note가 향수의 진짜 정체성이므로 가장 높은 가중치
    //
    //    3. 강도 보너스 (마무리 터치)
    //       사용자 강도 선호와 향수 계열의 일치도 보정
    //
    //  같은 Floral이라도 Rose 기반과 Jasmine 기반이 달리 점수 받는 이유가 노트 레이어야.
    //

import Foundation

    // MARK: - Score Breakdown

struct PerfumeScoreBreakdown {
    let familyScores: [(family: String, profileScore: Double, accordWeight: Double, weightedScore: Double)]
    let noteBonus: Double      // 노트 유사도 보너스
    let intensityBonus: Double
    let total: Double
}

    // MARK: - PerfumeScorer

struct PerfumeScorer {

    func score(
        perfume: Perfume,
        profile: UserTasteProfile
    ) -> Double {
        breakdown(perfume: perfume, profile: profile).total
    }

    func breakdown(
        perfume: Perfume,
        profile: UserTasteProfile
    ) -> PerfumeScoreBreakdown {

            // MARK: 레이어 1 — Accord 유사도 (80% 비중)

        let families = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)

        let rawAccordWeights = families.reduce(into: [String: Double]()) { dict, family in
            dict[family] = perfume.mainAccordStrengths[family]?.weight
            ?? AccordStrength.subtle.weight
        }
        let accordTotal = rawAccordWeights.values.reduce(0, +)
        let normalizedAccordWeights: [String: Double] = accordTotal > 0
        ? rawAccordWeights.mapValues { $0 / accordTotal }
        : rawAccordWeights

        let familyScores = families.map { family in
            let profileScore = profile.scentVector[family, default: 0]
            let accordWeight = normalizedAccordWeights[family, default: 0]
            return (
                family: family,
                profileScore: profileScore,
                accordWeight: accordWeight,
                weightedScore: profileScore * accordWeight
            )
        }

        let accordScore = familyScores.reduce(0) { $0 + $1.weightedScore }

            // MARK: 레이어 2 — Note 유사도 (20% 비중)
            //
            // 노트 벡터와 사용자 취향 벡터의 내적.
            // accord만으로는 포착 못하는 섬세한 계열 흐름을 보완해.
            // 예) 같은 Floral이라도 Jasmine이 많으면 Soft Floral 쪽으로 보정.

        let noteVector = NoteToFamilyMapper.noteVector(
            topNotes: perfume.topNotes,
            middleNotes: perfume.middleNotes,
            baseNotes: perfume.baseNotes
        )

        let noteRawScore = noteVector.reduce(0.0) { partialResult, pair in
            let profileScore = profile.scentVector[pair.key, default: 0]
            return partialResult + profileScore * pair.value
        }

            // 노트 레이어는 보조 신호 — 20% 비중으로 합산
        let noteBonus = noteRawScore * 0.2

            // MARK: 레이어 3 — 강도 보너스

        var intensityBonus: Double = 0
        let woodyFamilySet: Set<String> = ["Soft Amber", "Amber", "Woody Amber", "Woods", "Dry Woods", "Mossy Woods"]
        let freshFamilySet: Set<String> = ["Citrus", "Water", "Green", "Aromatic", "Fruity"]

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

            // MARK: 최종 합산
            // accord 80% + note 20% + 강도 보너스
        let total = accordScore * 0.8 + noteBonus + intensityBonus

        return PerfumeScoreBreakdown(
            familyScores: familyScores,
            noteBonus: noteBonus,
            intensityBonus: intensityBonus,
            total: total
        )
    }
}
