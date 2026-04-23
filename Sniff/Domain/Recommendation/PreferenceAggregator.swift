    //
    //  PreferenceAggregator.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.15.
    //
    //  벡터 기반 취향 분석 시스템
    //
    //  핵심 원리:
    //  각 소스(온보딩/컬렉션/시향)를 독립적인 정규화 벡터로 만들고
    //  사용자 단계 가중치로 합산한 뒤 최종 정규화.
    //  결과 scentVector는 PerfumeScorer의 코사인 유사도 계산에 직접 사용됨.
    //

import Foundation

struct PreferenceWeights {
    let onboarding: Double
    let collection: Double
    let tasting: Double
}

struct PreferenceAggregator {

    func aggregate(
        onboarding: TasteAnalysisResult,
        collection: [CollectedPerfume],
        tastingRecords: [TastingRecord]
    ) -> UserTasteProfile {

        let stage = determineStage(
            collectionCount: collection.count,
            tastingCount: tastingRecords.count
        )
        let weights = weights(for: stage)

        let onboardingVec              = onboardingVector(from: onboarding)
        let collectionVec              = collectionVector(from: collection)
        let (positiveVec, negativeVec) = tastingVectors(from: tastingRecords)

        let scentVector = buildScentVector(
            onboardingVec: onboardingVec,
            collectionVec: collectionVec,
            positiveVec: positiveVec,
            negativeVec: negativeVec,
            weights: weights
        )

        let legacyScores = scentVector.mapValues { $0 * 100 }

        let sortedFamilies = scentVector
            .sorted { $0.value > $1.value }
            .map(\.key)

        return UserTasteProfile(
            analysisSummary: onboarding.analysisSummary,
            preferredImpressions: onboarding.recommendationDirection.preferredImpression,
            preferredFamilies: Array(sortedFamilies.prefix(5)),
            intensityLevel: onboarding.recommendationDirection.intensityLevel,
            safeStartingPoint: onboarding.recommendationDirection.safeStartingPoint,
            familyScores: legacyScores,
            scentVector: scentVector,
            stage: stage
        )
    }
}

    // MARK: - 사용자 단계 판정

private extension PreferenceAggregator {

    func determineStage(
        collectionCount: Int,
        tastingCount: Int
    ) -> RecommendationStage {
        if tastingCount >= 3 { return .heavyTasting }
        if tastingCount >= 1 { return .earlyTasting }
        if collectionCount >= 1 { return .onboardingCollection }
        return .onboardingOnly
    }

    func weights(for stage: RecommendationStage) -> PreferenceWeights {
        switch stage {
            case .onboardingOnly:       return .init(onboarding: 1.0, collection: 0.0, tasting: 0.0)
            case .onboardingCollection: return .init(onboarding: 0.7, collection: 0.3, tasting: 0.0)
            case .earlyTasting:         return .init(onboarding: 0.5, collection: 0.2, tasting: 0.3)
            case .heavyTasting:         return .init(onboarding: 0.2, collection: 0.2, tasting: 0.6)
        }
    }
}

    // MARK: - 소스별 벡터 생성

private extension PreferenceAggregator {

        /// 온보딩 → 정규화 벡터
        /// preferredFamilies 순서에 따라 우선순위 가중치 부여
    func onboardingVector(from onboarding: TasteAnalysisResult) -> [String: Double] {
        let families = ScentFamilyNormalizer.canonicalNames(
            for: onboarding.recommendationDirection.preferredFamilies
        )

        let priorityWeights: [Double] = [0.35, 0.25, 0.20, 0.12, 0.08]

        var raw: [String: Double] = [:]
        for (index, family) in families.enumerated() {
            let weight = index < priorityWeights.count ? priorityWeights[index] : 0.04
            raw[family, default: 0] += weight
        }

        return normalize(raw)
    }

        /// 컬렉션 → 정규화 벡터
        /// 각 향수를 정규화 벡터로 변환 후 평균
    func collectionVector(from collection: [CollectedPerfume]) -> [String: Double] {
        guard !collection.isEmpty else { return [:] }

        var sumVec: [String: Double] = [:]
        for perfume in collection {
            let vec = perfumeVector(from: perfume.accordStrengths, fallback: perfume.mainAccords)
            for (family, value) in vec {
                sumVec[family, default: 0] += value
            }
        }

        let averaged = sumVec.mapValues { $0 / Double(collection.count) }
        return normalize(averaged)
    }

        /// 시향 기록 → 긍정 벡터 + 부정 벡터
        ///
        /// 세 가지 가중치가 곱해져 최종 영향도가 결정됨:
        ///   ratingWeight   — 별점이 높을수록 강한 신호
        ///   recency        — 최근 시향일수록 더 신뢰
        ///   revisit        — "매일 뿌리고 싶어"면 1.4배, "기억에 남아, 근데 내 향은 아니야"면 0.3배
        ///
        /// 별점이 같아도 재사용 의향에 따라 취향 벡터 반영 정도가 달라지는 것이 핵심.
    func tastingVectors(
        from records: [TastingRecord]
    ) -> (positive: [String: Double], negative: [String: Double]) {
        var positiveWeightedSum: [String: Double] = [:]
        var positiveTotal: Double = 0
        var negativeWeightedSum: [String: Double] = [:]
        var negativeTotal: Double = 0

        for record in records {
            let vec     = perfumeVector(from: record.accordStrengths, fallback: record.mainAccords)
            let recency = recencyMultiplier(for: record.updatedAt)
            let revisit = revisitMultiplier(for: record.revisitDesire)

            if record.rating >= 3 {
                let ratingWeight = positiveRatingWeight(for: record.rating) * recency * revisit

                for (family, value) in vec {
                    positiveWeightedSum[family, default: 0] += value * ratingWeight
                }
                positiveTotal += ratingWeight

                    // mood tag 보정 — 선호 계열을 소폭 강화
                for tag in record.moodTags {
                    for family in mapMoodTagToFamilies(tag) {
                        positiveWeightedSum[family, default: 0] += 0.02 * ratingWeight
                    }
                }

            } else {
                let ratingWeight = negativeRatingWeight(for: record.rating) * recency * revisit

                for (family, value) in vec {
                    negativeWeightedSum[family, default: 0] += value * ratingWeight
                }
                negativeTotal += ratingWeight
            }
        }

        let positive = positiveTotal > 0
        ? normalize(positiveWeightedSum.mapValues { $0 / positiveTotal })
        : [String: Double]()

        let negative = negativeTotal > 0
        ? normalize(negativeWeightedSum.mapValues { $0 / negativeTotal })
        : [String: Double]()

        return (positive, negative)
    }
}

    // MARK: - 벡터 결합

private extension PreferenceAggregator {

        /// 소스 벡터들을 가중 합산하고 부정 벡터를 차감
        /// negativePenalty: 싫어하는 계열을 얼마나 강하게 피할지
    func buildScentVector(
        onboardingVec: [String: Double],
        collectionVec: [String: Double],
        positiveVec: [String: Double],
        negativeVec: [String: Double],
        weights: PreferenceWeights,
        negativePenalty: Double = 1.5
    ) -> [String: Double] {

        let positiveKeys = Set(onboardingVec.keys)
            .union(collectionVec.keys)
            .union(positiveVec.keys)

        var result: [String: Double] = [:]

        for key in positiveKeys {
            result[key] =
            onboardingVec[key, default: 0] * weights.onboarding
            + collectionVec[key, default: 0] * weights.collection
            + positiveVec[key, default: 0]   * weights.tasting
        }

        for (key, negValue) in negativeVec {
            result[key, default: 0] -= negValue * negativePenalty * weights.tasting
        }

        result = result.filter { $0.value > 0 }
        return normalize(result)
    }
}

    // MARK: - 향수 벡터 변환

private extension PreferenceAggregator {

        /// AccordStrength 딕셔너리 → 정규화 벡터
        /// accordStrengths가 비어 있으면 mainAccords 이름으로 균등 분배
    func perfumeVector(
        from strengths: [String: AccordStrength],
        fallback mainAccords: [String]
    ) -> [String: Double] {
        if !strengths.isEmpty {
            let raw = strengths.mapValues { $0.weight }
            let canonical = Dictionary(
                uniqueKeysWithValues: raw.compactMap { rawKey, weight -> (String, Double)? in
                    guard let name = ScentFamilyNormalizer.canonicalName(for: rawKey) else { return nil }
                    return (name, weight)
                }
            )
            return normalize(canonical)
        }

        let families = ScentFamilyNormalizer.canonicalNames(for: mainAccords)
        guard !families.isEmpty else { return [:] }
        let equalWeight = 1.0 / Double(families.count)
        return Dictionary(uniqueKeysWithValues: families.map { ($0, equalWeight) })
    }
}

    // MARK: - 수학 유틸

private extension PreferenceAggregator {

    func normalize(_ scores: [String: Double]) -> [String: Double] {
        let total = scores.values.reduce(0, +)
        guard total > 0 else { return [:] }
        return scores.mapValues { $0 / total }
    }
}

    // MARK: - 최근성 & 별점 & 재사용 의향 가중치

private extension PreferenceAggregator {

    func recencyMultiplier(for date: Date) -> Double {
        let days = Calendar.current
            .dateComponents([.day], from: date, to: Date()).day ?? 999
        switch days {
            case 0...7:  return 1.3
            case 8...30: return 1.1
            default:     return 1.0
        }
    }

    func positiveRatingWeight(for rating: Int) -> Double {
        switch rating {
            case 5: return 1.0
            case 4: return 0.8
            case 3: return 0.5
            default: return 0
        }
    }

    func negativeRatingWeight(for rating: Int) -> Double {
        switch rating {
            case 1: return 1.0
            case 2: return 0.7
            default: return 0
        }
    }

        /// 재사용 의향 태그 → 취향 벡터 반영 배율
        ///
        /// 이 함수가 별점 시스템의 맹점을 메워.
        /// 5점을 줬어도 "기억에 남아, 근데 내 향은 아니야"면
        /// 그 향수의 계열이 내 취향 벡터에 강하게 박히지 않아야 하거든.
        /// 반대로 "매일 뿌리고 싶어"는 별점보다 더 강한 소장 신호야.
    func revisitMultiplier(for tag: String?) -> Double {
        switch tag {
            case "매일 뿌리고 싶어":
                return 1.4   // 소장 의향 최강 — 별점 이상의 신호
            case "가끔 꺼내고 싶어":
                return 1.1   // 긍정이되 일상향은 아님
            case "기억에 남아, 근데 내 향은 아니야":
                return 0.3   // 아름답지만 나의 향은 아님 — 약하게만 반영
            case "다시 맡고 싶지 않아":
                return 0.0   // 별점 무관하게 취향 벡터 반영 차단
            default:
                return 1.0   // 태그 없으면 기존 동작 그대로
        }
    }

    func mapMoodTagToFamilies(_ tag: String) -> [String] {
        switch tag {
            case "상큼한":    return ["Citrus", "Fruity"]
            case "시원한":    return ["Water", "Green"]
            case "싱그러운":  return ["Green", "Aromatic"]
            case "은은한":    return ["Soft Floral", "Floral"]
            case "보송보송한": return ["Soft Floral", "Soft Amber"]
            case "따뜻한":    return ["Soft Amber", "Amber", "Woody Amber"]
            case "묵직한":    return ["Amber", "Mossy Woods", "Dry Woods"]
            case "무거운":    return ["Woody Amber", "Dry Woods"]
            default:         return []
        }
    }
}
