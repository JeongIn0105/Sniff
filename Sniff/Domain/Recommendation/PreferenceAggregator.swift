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
        let dislikedOnboardingVec      = OnboardingTagMapper.weightedVector(for: onboarding.dislikedTags)
        let collectionVec              = collectionVector(from: collection)
        let tastingSignal = tastingVectors(
            from: tastingRecords,
            collection: collection
        )

        let scentVector = buildScentVector(
            onboardingVec: onboardingVec,
            collectionVec: collectionVec,
            positiveVec: tastingSignal.positive,
            dislikedOnboardingVec: dislikedOnboardingVec,
            negativeTastingVec: tastingSignal.negative,
            tastingPositiveSignal: tastingSignal.positiveSignal,
            tastingNegativeSignal: tastingSignal.negativeSignal,
            weights: weights
        )

        let legacyScores = scentVector.mapValues { $0 * 100 }

        let sortedFamilies = scentVector
            .sorted { $0.value > $1.value }
            .map(\.key)

        return UserTasteProfile(
            tasteTitle: onboarding.tasteTitle,
            analysisSummary: onboarding.analysisSummary,
            preferredImpressions: onboarding.recommendationDirection.preferredImpression,
            preferredFamilies: Array(sortedFamilies.prefix(5)),
            dislikedFamilies: Array(dislikedOnboardingVec.keys),
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
        if tastingCount >= 5 { return .heavyTasting }
        if tastingCount >= 3 { return .earlyTasting }
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
        var totalWeight: Double = 0
        for perfume in collection {
            let ownershipWeight = collectionPreferenceWeight(for: perfume)
            guard ownershipWeight > 0 else { continue }
            let vec = perfumeVector(from: perfume.accordStrengths, fallback: perfume.mainAccords)
            for (family, value) in vec {
                sumVec[family, default: 0] += value * ownershipWeight
            }
            totalWeight += ownershipWeight
        }

        guard totalWeight > 0 else { return [:] }
        let averaged = sumVec.mapValues { $0 / totalWeight }
        return normalize(averaged)
    }

    func collectionPreferenceWeight(for perfume: CollectedPerfume) -> Double {
        let statusWeight: Double
        switch perfume.usageStatus {
        case .finished:
            statusWeight = 1.2
        case .inUse:
            statusWeight = 1.0
        case .unopened:
            statusWeight = 0.25
        case nil:
            statusWeight = 0.8
        }

        let frequencyWeight: Double
        switch perfume.usageFrequency {
        case .often:
            frequencyWeight = 1.25
        case .sometimes:
            frequencyWeight = 0.8
        case .rarely:
            frequencyWeight = 0.25
        case nil:
            frequencyWeight = 1.0
        }

        let preferenceWeight: Double
        switch perfume.preferenceLevel {
        case .liked:
            preferenceWeight = 1.2
        case .neutral:
            preferenceWeight = 0.5
        case .disappointed:
            preferenceWeight = 0.1
        case nil:
            preferenceWeight = 1.0
        }

        return statusWeight * frequencyWeight * preferenceWeight
    }

        /// 시향 기록 → 긍정 벡터 + 부정 벡터
        ///
        /// 세 가지 가중치가 곱해져 최종 영향도가 결정됨:
        ///   ratingWeight   — 별점이 높을수록 강한 신호
        ///   recency        — 최근 시향일수록 더 신뢰
        ///   revisit        — 긍정 기록은 재사용 의향이 클수록 강화,
        ///                    부정 기록은 다시 맡고 싶지 않을수록 감점 강화
        ///
        /// 별점이 같아도 재사용 의향에 따라 취향 벡터 반영 정도가 달라지는 것이 핵심.
    func tastingVectors(
        from records: [TastingRecord],
        collection: [CollectedPerfume]
    ) -> (
        positive: [String: Double],
        negative: [String: Double],
        positiveSignal: Double,
        negativeSignal: Double
    ) {
        var positiveWeightedSum: [String: Double] = [:]
        var positiveTotal: Double = 0
        var positiveBaseTotal: Double = 0
        var negativeWeightedSum: [String: Double] = [:]
        var negativeTotal: Double = 0
        var negativeBaseTotal: Double = 0
        let ownedPerfumesByKey = ownedPerfumeLookup(from: collection)

        for record in records {
            let vec     = perfumeVector(from: record.accordStrengths, fallback: record.mainAccords)
            let recency = recencyMultiplier(for: record.updatedAt)
            let ownedPerfume = matchingOwnedPerfume(for: record, in: ownedPerfumesByKey)
            let isOwnedUsageRecord = ownedPerfume != nil || hasUsageRecordSignals(record)

            if record.rating >= 3 {
                let baseWeight = positiveRatingWeight(for: record.rating)
                    * recency
                    * positiveRevisitMultiplier(for: record.revisitDesire)
                    * positiveSkinChemistryMultiplier(for: record.skinChemistry)
                    * positiveUsageRecordMultiplier(for: record, isOwnedUsageRecord: isOwnedUsageRecord)
                let ratingWeight = baseWeight
                    * ownedPositiveMultiplier(for: ownedPerfume)

                for (family, value) in vec {
                    positiveWeightedSum[family, default: 0] += value * ratingWeight
                }
                positiveTotal += ratingWeight
                positiveBaseTotal += baseWeight

                    // mood tag 보정 — 선호 계열을 소폭 강화
                for tag in record.moodTags {
                    for family in mapMoodTagToFamilies(tag) {
                        let tagWeight = ownedPerfume == nil ? 0.02 : 0.03
                        positiveWeightedSum[family, default: 0] += tagWeight * ratingWeight
                    }
                }

                addUsageContextBoosts(
                    from: record,
                    to: &positiveWeightedSum,
                    ratingWeight: ratingWeight,
                    isOwnedUsageRecord: isOwnedUsageRecord,
                    polarity: .positive
                )

            } else {
                let baseWeight = negativeRatingWeight(for: record.rating)
                    * recency
                    * negativeRevisitMultiplier(for: record.revisitDesire)
                    * negativeSkinChemistryMultiplier(for: record.skinChemistry)
                    * negativeUsageRecordMultiplier(for: record, isOwnedUsageRecord: isOwnedUsageRecord)
                let ratingWeight = baseWeight
                    * ownedNegativeMultiplier(for: ownedPerfume)

                for (family, value) in vec {
                    negativeWeightedSum[family, default: 0] += value * ratingWeight
                }
                addUsageContextBoosts(
                    from: record,
                    to: &negativeWeightedSum,
                    ratingWeight: ratingWeight,
                    isOwnedUsageRecord: isOwnedUsageRecord,
                    polarity: .negative
                )
                negativeTotal += ratingWeight
                negativeBaseTotal += baseWeight
            }
        }

        let positive = positiveTotal > 0
        ? normalize(positiveWeightedSum.mapValues { $0 / positiveTotal })
        : [String: Double]()

        let negative = negativeTotal > 0
        ? normalize(negativeWeightedSum.mapValues { $0 / negativeTotal })
        : [String: Double]()

        return (
            positive,
            negative,
            signalMultiplier(total: positiveTotal, baseline: positiveBaseTotal, lowerBound: 0.9, upperBound: 1.6),
            signalMultiplier(total: negativeTotal, baseline: negativeBaseTotal, lowerBound: 0.9, upperBound: 1.8)
        )
    }

    func ownedPerfumeLookup(from collection: [CollectedPerfume]) -> [String: CollectedPerfume] {
        collection.reduce(into: [String: CollectedPerfume]()) { result, perfume in
            for key in recordMatchingKeys(perfumeName: perfume.name, brandName: perfume.brand) {
                result[key] = perfume
            }
        }
    }

    func matchingOwnedPerfume(
        for record: TastingRecord,
        in lookup: [String: CollectedPerfume]
    ) -> CollectedPerfume? {
        recordMatchingKeys(perfumeName: record.perfumeName, brandName: record.brandName)
            .lazy
            .compactMap { lookup[$0] }
            .first
    }

    func recordMatchingKeys(perfumeName: String, brandName: String) -> Set<String> {
        [
            recordKey(perfumeName: perfumeName, brandName: brandName),
            recordKey(
                perfumeName: PerfumeKoreanTranslator.koreanPerfumeName(for: perfumeName),
                brandName: PerfumeKoreanTranslator.koreanBrand(for: brandName)
            )
        ]
    }

    func recordKey(perfumeName: String, brandName: String) -> String {
        "\(normalizeRecordText(brandName))|\(normalizeRecordText(perfumeName))"
    }

    func normalizeRecordText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }

    func ownedPositiveMultiplier(for perfume: CollectedPerfume?) -> Double {
        guard let perfume else { return 1.0 }

        var multiplier = 1.35

        switch perfume.usageStatus {
        case .finished:
            multiplier *= 1.15
        case .inUse:
            multiplier *= 1.1
        case .unopened:
            multiplier *= 0.75
        case nil:
            multiplier *= 1.0
        }

        switch perfume.usageFrequency {
        case .often:
            multiplier *= 1.2
        case .sometimes:
            multiplier *= 1.0
        case .rarely:
            multiplier *= 0.85
        case nil:
            multiplier *= 1.0
        }

        switch perfume.preferenceLevel {
        case .liked:
            multiplier *= 1.2
        case .neutral:
            multiplier *= 0.95
        case .disappointed:
            multiplier *= 0.7
        case nil:
            multiplier *= 1.0
        }

        return min(1.8, max(0.8, multiplier))
    }

    func ownedNegativeMultiplier(for perfume: CollectedPerfume?) -> Double {
        guard let perfume else { return 1.0 }

        var multiplier = 1.35

        switch perfume.usageStatus {
        case .finished:
            multiplier *= 1.1
        case .inUse:
            multiplier *= 1.15
        case .unopened:
            multiplier *= 0.75
        case nil:
            multiplier *= 1.0
        }

        switch perfume.usageFrequency {
        case .often:
            multiplier *= 1.2
        case .sometimes:
            multiplier *= 1.05
        case .rarely:
            multiplier *= 0.95
        case nil:
            multiplier *= 1.0
        }

        switch perfume.preferenceLevel {
        case .liked:
            multiplier *= 0.8
        case .neutral:
            multiplier *= 1.05
        case .disappointed:
            multiplier *= 1.35
        case nil:
            multiplier *= 1.0
        }

        return min(2.0, max(0.9, multiplier))
    }

    func signalMultiplier(
        total: Double,
        baseline: Double,
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        guard baseline > 0 else { return 1.0 }
        return min(upperBound, max(lowerBound, total / baseline))
    }
}

    // MARK: - 벡터 결합

private extension PreferenceAggregator {

        /// 소스 벡터들을 가중 합산하고 온보딩/시향의 부정 신호를 각각 차감
    func buildScentVector(
        onboardingVec: [String: Double],
        collectionVec: [String: Double],
        positiveVec: [String: Double],
        dislikedOnboardingVec: [String: Double],
        negativeTastingVec: [String: Double],
        tastingPositiveSignal: Double,
        tastingNegativeSignal: Double,
        weights: PreferenceWeights,
        onboardingNegativePenalty: Double = 1.5,
        tastingNegativePenalty: Double = 1.5
    ) -> [String: Double] {

        let positiveKeys = Set(onboardingVec.keys)
            .union(collectionVec.keys)
            .union(positiveVec.keys)

        var result: [String: Double] = [:]

        for key in positiveKeys {
            result[key] =
            onboardingVec[key, default: 0] * weights.onboarding
            + collectionVec[key, default: 0] * weights.collection
            + positiveVec[key, default: 0]   * weights.tasting * tastingPositiveSignal
        }

        for (key, negValue) in dislikedOnboardingVec {
            result[key, default: 0] -= negValue * onboardingNegativePenalty * weights.onboarding
        }

        for (key, negValue) in negativeTastingVec {
            result[key, default: 0] -= negValue * tastingNegativePenalty * weights.tasting * tastingNegativeSignal
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
    func positiveRevisitMultiplier(for tag: String?) -> Double {
        switch tag {
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[0]:
                return 1.4   // 소장 의향 최강 — 별점 이상의 신호
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[1]:
                return 1.1   // 긍정이되 일상향은 아님
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[2]:
                return 0.3   // 아름답지만 나의 향은 아님 — 약하게만 반영
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[3]:
                return 0.0   // 별점 무관하게 취향 벡터 반영 차단
            default:
                return 1.0   // 태그 없으면 기존 동작 그대로
        }
    }

    func negativeRevisitMultiplier(for tag: String?) -> Double {
        switch tag {
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[0]:
                return 0.3   // 낮은 별점이어도 재사용 의향이 있으면 감점을 완화
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[1]:
                return 0.6
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[2]:
                return 1.1
            case AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[3]:
                return 1.4   // 다시 맡고 싶지 않은 향은 강한 부정 신호
            default:
                return 1.0
        }
    }

    func positiveSkinChemistryMultiplier(for value: String?) -> Double {
        switch value {
        case TastingSkinChemistry.blooms.displayName:
            return 1.2
        case TastingSkinChemistry.neutral.displayName:
            return 1.0
        case TastingSkinChemistry.fades.displayName:
            return 0.75
        default:
            return 1.0
        }
    }

    func negativeSkinChemistryMultiplier(for value: String?) -> Double {
        switch value {
        case TastingSkinChemistry.blooms.displayName:
            return 0.8
        case TastingSkinChemistry.neutral.displayName:
            return 1.0
        case TastingSkinChemistry.fades.displayName:
            return 1.2
        default:
            return 1.0
        }
    }

    enum UsageSignalPolarity: Equatable {
        case positive
        case negative
    }

    func hasUsageRecordSignals(_ record: TastingRecord) -> Bool {
        record.longevityExperience != nil
            || record.sillageExperience != nil
            || record.drydownChange != nil
            || record.skinChemistry != nil
            || !record.wearSituations.isEmpty
            || !record.weatherContexts.isEmpty
            || !record.applicationAreas.isEmpty
    }

    func positiveUsageRecordMultiplier(for record: TastingRecord, isOwnedUsageRecord: Bool) -> Double {
        guard isOwnedUsageRecord else { return 1.0 }

        var multiplier = usageContextReliabilityMultiplier(for: record)

        switch record.longevityExperience {
        case TastingLongevityExperience.overSixHours.displayName:
            multiplier *= 1.12
        case TastingLongevityExperience.fourToSixHours.displayName:
            multiplier *= 1.06
        case TastingLongevityExperience.twoToFourHours.displayName:
            multiplier *= 0.98
        case TastingLongevityExperience.underTwoHours.displayName:
            multiplier *= 0.82
        default:
            break
        }

        switch record.sillageExperience {
        case TastingSillageExperience.roomFilling.displayName:
            multiplier *= 1.08
        case TastingSillageExperience.oneMeter.displayName:
            multiplier *= 1.04
        case TastingSillageExperience.skinClose.displayName:
            multiplier *= 0.96
        default:
            break
        }

        return min(1.35, max(0.75, multiplier))
    }

    func negativeUsageRecordMultiplier(for record: TastingRecord, isOwnedUsageRecord: Bool) -> Double {
        guard isOwnedUsageRecord else { return 1.0 }

        var multiplier = usageContextReliabilityMultiplier(for: record)

        switch record.longevityExperience {
        case TastingLongevityExperience.underTwoHours.displayName:
            multiplier *= 1.15
        case TastingLongevityExperience.twoToFourHours.displayName:
            multiplier *= 1.05
        case TastingLongevityExperience.fourToSixHours.displayName:
            multiplier *= 1.0
        case TastingLongevityExperience.overSixHours.displayName:
            multiplier *= 1.1
        default:
            break
        }

        switch record.sillageExperience {
        case TastingSillageExperience.roomFilling.displayName:
            multiplier *= 1.25
        case TastingSillageExperience.oneMeter.displayName:
            multiplier *= 1.05
        case TastingSillageExperience.skinClose.displayName:
            multiplier *= 0.9
        default:
            break
        }

        return min(1.45, max(0.75, multiplier))
    }

    func usageContextReliabilityMultiplier(for record: TastingRecord) -> Double {
        let contextSignalCount = record.wearSituations.count
            + record.weatherContexts.count
            + record.applicationAreas.count

        switch contextSignalCount {
        case 3...:
            return 1.06
        case 2:
            return 1.04
        case 1:
            return 1.02
        default:
            return 1.0
        }
    }

    func addUsageContextBoosts(
        from record: TastingRecord,
        to scores: inout [String: Double],
        ratingWeight: Double,
        isOwnedUsageRecord: Bool,
        polarity: UsageSignalPolarity
    ) {
        guard isOwnedUsageRecord else { return }

        let baseBoost = polarity == .positive ? 0.026 : 0.018
        let boosts = usageContextFamilyBoosts(for: record, polarity: polarity)

        for (family, weight) in boosts {
            guard let canonical = ScentFamilyNormalizer.canonicalName(for: family) else { continue }
            scores[canonical, default: 0] += baseBoost * weight * ratingWeight
        }
    }

    func usageContextFamilyBoosts(
        for record: TastingRecord,
        polarity: UsageSignalPolarity
    ) -> [(family: String, weight: Double)] {
        var boosts: [(String, Double)] = []

        for situation in record.wearSituations {
            switch situation {
            case TastingWearSituation.daily.displayName:
                boosts += [("Water", 1.0), ("Aromatic", 0.85), ("Soft Floral", 0.75), ("Citrus", 0.65)]
            case TastingWearSituation.date.displayName:
                boosts += [("Floral Amber", 1.0), ("Amber", 0.85), ("Soft Floral", 0.8), ("Floral", 0.65)]
            case TastingWearSituation.work.displayName:
                boosts += [("Aromatic", 1.0), ("Water", 0.85), ("Woods", 0.75), ("Soft Floral", 0.6)]
            case TastingWearSituation.special.displayName:
                boosts += [("Amber", 1.0), ("Woody Amber", 0.95), ("Floral Amber", 0.85), ("Dry Woods", 0.65)]
            default:
                break
            }
        }

        for weather in record.weatherContexts {
            switch weather {
            case TastingWeatherContext.hotHumid.displayName:
                boosts += [("Citrus", 1.0), ("Water", 0.95), ("Green", 0.85), ("Aromatic", 0.65)]
            case TastingWeatherContext.dryWinter.displayName:
                boosts += [("Soft Amber", 1.0), ("Amber", 0.9), ("Woods", 0.8), ("Woody Amber", 0.65)]
            case TastingWeatherContext.mild.displayName:
                boosts += [("Floral", 0.9), ("Green", 0.85), ("Aromatic", 0.75), ("Soft Floral", 0.7)]
            case TastingWeatherContext.rainy.displayName:
                boosts += [("Water", 1.0), ("Green", 0.85), ("Mossy Woods", 0.75), ("Aromatic", 0.55)]
            default:
                break
            }
        }

        for area in record.applicationAreas {
            switch area {
            case TastingApplicationArea.wrist.displayName:
                boosts += [("Citrus", 0.6), ("Aromatic", 0.55)]
            case TastingApplicationArea.neck.displayName:
                boosts += [("Soft Floral", 0.75), ("Floral Amber", 0.65), ("Amber", 0.55)]
            case TastingApplicationArea.clothes.displayName:
                boosts += [("Woods", 0.8), ("Soft Amber", 0.7), ("Amber", 0.65)]
            case TastingApplicationArea.hair.displayName:
                boosts += [("Soft Floral", 0.75), ("Floral", 0.65), ("Aromatic", 0.55)]
            default:
                break
            }
        }

        switch record.drydownChange {
        case TastingDrydownChange.subtle.displayName:
            boosts += [("Water", 0.75), ("Aromatic", 0.65), ("Soft Floral", 0.55)]
        case TastingDrydownChange.moderate.displayName:
            boosts += [("Floral", 0.65), ("Woods", 0.65), ("Soft Amber", 0.6)]
        case TastingDrydownChange.dramatic.displayName:
            boosts += [("Amber", 0.85), ("Woody Amber", 0.8), ("Floral Amber", 0.75), ("Dry Woods", 0.55)]
        default:
            break
        }

        if polarity == .negative {
            return boosts.map { ($0.0, $0.1 * 0.85) }
        }

        return boosts
    }

    func mapMoodTagToFamilies(_ tag: String) -> [String] {
        switch tag {
            case AppStrings.DomainDisplay.TastingNoteData.sophisticatedTag:
                return ["Water", "Aromatic", "Citrus"]
            case AppStrings.DomainDisplay.TastingNoteData.naturalTag:
                return ["Green", "Mossy Woods", "Aromatic"]
            case AppStrings.DomainDisplay.TastingNoteData.mysteriousTag:
                return ["Water", "Amber", "Woody Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.vibrantTag:
                return ["Citrus", "Fruity", "Green"]
            case AppStrings.DomainDisplay.TastingNoteData.relaxedTag:
                return ["Soft Amber", "Soft Floral", "Woods"]
            case AppStrings.DomainDisplay.TastingNoteData.pureTag:
                return ["Soft Floral", "Floral", "Water"]
            case AppStrings.DomainDisplay.TastingNoteData.sensualTag:
                return ["Amber", "Woody Amber", "Floral Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.calmTag:
                return ["Woods", "Soft Amber", "Aromatic"]
            case AppStrings.DomainDisplay.TastingNoteData.chicTag:
                return ["Woods", "Dry Woods", "Woody Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.warmTag:
                return ["Soft Amber", "Amber", "Woody Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.coolTag:
                return ["Water", "Citrus", "Green"]
            case AppStrings.DomainDisplay.TastingNoteData.freshTag:
                return ["Citrus", "Fruity"]
            case AppStrings.DomainDisplay.TastingNoteData.sweetTag:
                return ["Fruity", "Floral Amber", "Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.cleanTag:
                return ["Water", "Aromatic", "Soft Floral"]
            case AppStrings.DomainDisplay.TastingNoteData.softTag:
                return ["Soft Floral", "Soft Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.subtleTag:
                return ["Soft Floral", "Floral"]
            case AppStrings.DomainDisplay.TastingNoteData.clearTag:
                return ["Water", "Citrus", "Aromatic"]
            case AppStrings.DomainDisplay.TastingNoteData.deepTag:
                return ["Amber", "Woody Amber", "Dry Woods"]
            case AppStrings.DomainDisplay.TastingNoteData.airyGreenTag:
                return ["Green", "Aromatic"]
            case AppStrings.DomainDisplay.TastingNoteData.powderyTag:
                return ["Soft Floral", "Soft Amber"]
            case AppStrings.DomainDisplay.TastingNoteData.heavyTag:
                return ["Amber", "Mossy Woods", "Dry Woods"]
            case AppStrings.DomainDisplay.TastingNoteData.heavierTag:
                return ["Woody Amber", "Dry Woods"]
            case "강렬한":
                return ["Amber", "Dry Woods", "Woody Amber"]
            case "가벼운":
                return ["Citrus", "Water", "Floral"]
            case "포근한":
                return ["Soft Amber", "Soft Floral"]
            case "고급스러운":
                return ["Amber", "Woody Amber", "Floral Amber", "Woods"]
            case "중성적인":
                return ["Soft Floral", "Woods", "Aromatic", "Water"]
            default:
                return []
        }
    }
}
