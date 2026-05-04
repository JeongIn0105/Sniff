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

    func tasteMatchScore(
        perfume: Perfume,
        profile: UserTasteProfile
    ) -> Double {
        let families = ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords)
        let rawAccordWeights = families.reduce(into: [String: Double]()) { dict, family in
            dict[family] = perfume.mainAccordStrengths[family]?.weight
                ?? AccordStrength.subtle.weight
        }
        let accordTotal = rawAccordWeights.values.reduce(0, +)
        let normalizedAccordWeights: [String: Double] = accordTotal > 0
            ? rawAccordWeights.mapValues { $0 / accordTotal }
            : rawAccordWeights

        let accordScore = families.reduce(0.0) { partialResult, family in
            partialResult + profile.scentVector[family, default: 0] * normalizedAccordWeights[family, default: 0]
        }
        let noteVector = NoteToFamilyMapper.noteVector(
            topNotes: perfume.topNotes,
            middleNotes: perfume.middleNotes,
            baseNotes: perfume.baseNotes,
            generalNotes: perfume.generalNotes
        )
        let noteScore = noteVector.reduce(0.0) { partialResult, pair in
            partialResult + profile.scentVector[pair.key, default: 0] * pair.value
        }

        return min(1, accordScore + noteScore)
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
            baseNotes: perfume.baseNotes,
            generalNotes: perfume.generalNotes
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
        let preferredScore = min(1, accordScore + noteRawScore)
        let impressionScore = impressionScore(perfume: perfume, profile: profile)
        let seasonScore = seasonScore(perfume: perfume, profile: profile)
        let availabilityScore = min(1.0, Double(PerfumeKoreanTranslator.koreaBrandAvailabilityScore(for: perfume)) / 100.0)
        let recentLaunchScore = recentLaunchScore(perfume: perfume)
        let popularityScore = popularityScore(perfume: perfume)
        let dislikedScore = dislikedScore(perfume: perfume, profile: profile)

        let weightedTotal =
            preferredScore * 35
            + impressionScore * 17
            + seasonScore * 12
            + availabilityScore * 18
            + recentLaunchScore * 12
            + popularityScore * 6
            - dislikedScore * 45

        let total = weightedTotal + intensityBonus

        return PerfumeScoreBreakdown(
            familyScores: familyScores,
            noteBonus: noteBonus,
            intensityBonus: intensityBonus,
            total: total
        )
    }

    private func dislikedScore(perfume: Perfume, profile: UserTasteProfile) -> Double {
        guard !profile.dislikedFamilies.isEmpty else { return 0 }
        let disliked = Set(profile.dislikedFamilies)
        let families = Set(ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords))
        let noteFamilies = Set(
            NoteToFamilyMapper.noteVector(
                topNotes: perfume.topNotes,
                middleNotes: perfume.middleNotes,
                baseNotes: perfume.baseNotes,
                generalNotes: perfume.generalNotes
            ).keys
        )
        let matchedCount = disliked.intersection(families.union(noteFamilies)).count
        guard matchedCount > 0 else { return 0 }
        return min(1, 0.65 + Double(matchedCount) * 0.2)
    }

    private func impressionScore(perfume: Perfume, profile: UserTasteProfile) -> Double {
        let textTokens = searchableTokens(for: perfume)
        let preferredKeywords = profile.preferredImpressions
            .flatMap { OnboardingTagMapper.searchKeywords(for: $0) }
            .map { $0.lowercased() }
        let preferredFamilies = Set(
            profile.preferredImpressions
                .flatMap { OnboardingTagMapper.families(for: $0) }
                .compactMap { ScentFamilyNormalizer.canonicalName(for: $0) }
        )
        let perfumeFamilies = Set(ScentFamilyNormalizer.canonicalNames(for: perfume.mainAccords))

        let keywordMatch = preferredKeywords.contains { keyword in
            textTokens.contains(keyword)
        }
        let familyMatch = !preferredFamilies.intersection(perfumeFamilies).isEmpty

        if keywordMatch && familyMatch { return 1 }
        if keywordMatch || familyMatch { return 0.75 }
        return 0
    }

    private func seasonScore(perfume: Perfume, profile: UserTasteProfile) -> Double {
        let preferred = profile.preferredImpressions.joined(separator: " ")
        let seasons = (perfume.season ?? []) + perfume.seasonRanking.map(\.name)
        let normalized = seasons.joined(separator: " ").lowercased()

        if preferred.contains("산뜻") || preferred.contains("시원") {
            return normalized.contains("spring") || normalized.contains("summer") ? 1 : 0
        }
        if preferred.contains("차분") || preferred.contains("포근") {
            return normalized.contains("fall") || normalized.contains("winter") ? 1 : 0
        }
        return seasons.isEmpty ? 0.4 : 0.7
    }

    private func popularityScore(perfume: Perfume) -> Double {
        if let popularity = perfume.popularity {
            if popularity > 100 {
                return 1
            }
            if popularity > 1 {
                return min(1, popularity / 100)
            }
            return max(0, popularity)
        }

        if !perfume.seasonRanking.isEmpty {
            return min(1, perfume.seasonRanking.map(\.score).reduce(0, +) / Double(perfume.seasonRanking.count))
        }
        return 0.5
    }

    private func recentLaunchScore(perfume: Perfume) -> Double {
        guard let releaseYear = perfume.releaseYear else {
            return 0.35
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        let age = max(0, currentYear - releaseYear)
        switch age {
        case 0...1:
            return 1
        case 2:
            return 0.85
        case 3:
            return 0.7
        case 4:
            return 0.55
        case 5:
            return 0.4
        default:
            return 0.2
        }
    }

    private func searchableTokens(for perfume: Perfume) -> String {
        var tokens: [String] = []
        tokens.append(perfume.name)
        tokens.append(perfume.brand)
        tokens.append(contentsOf: perfume.mainAccords)
        tokens.append(contentsOf: perfume.topNotes ?? [])
        tokens.append(contentsOf: perfume.middleNotes ?? [])
        tokens.append(contentsOf: perfume.baseNotes ?? [])
        tokens.append(contentsOf: perfume.generalNotes ?? [])
        tokens.append(contentsOf: perfume.season ?? [])
        tokens.append(contentsOf: perfume.seasonRanking.map(\.name))

        return tokens
            .joined(separator: " ")
            .lowercased()
    }
}
