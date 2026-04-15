//
//  PreferenceAggregator.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
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

        let onboardingScores = onboardingFamilyScores(from: onboarding)
        let collectionScores = collectionFamilyScores(from: collection)
        let tastingScores = tastingFamilyScores(from: tastingRecords)

        let mergedScores = mergeScores(
            onboardingScores: onboardingScores,
            collectionScores: collectionScores,
            tastingScores: tastingScores,
            weights: weights
        )

        let sortedFamilies = mergedScores
            .sorted { $0.value > $1.value }
            .map(\.key)

        return UserTasteProfile(
            primaryProfileCode: onboarding.primaryProfileCode,
            primaryProfileName: onboarding.primaryProfileName,
            secondaryProfileCode: onboarding.secondaryProfileCode,
            secondaryProfileName: onboarding.secondaryProfileName,
            analysisSummary: onboarding.analysisSummary,
            preferredFamilies: Array(sortedFamilies.prefix(5)),
            intensityLevel: onboarding.recommendationDirection.intensityLevel,
            familyScores: mergedScores,
            stage: stage
        )
    }
}

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
            case .onboardingOnly:
                return .init(onboarding: 1.0, collection: 0.0, tasting: 0.0)
            case .onboardingCollection:
                return .init(onboarding: 0.7, collection: 0.3, tasting: 0.0)
            case .earlyTasting:
                return .init(onboarding: 0.5, collection: 0.2, tasting: 0.3)
            case .heavyTasting:
                return .init(onboarding: 0.2, collection: 0.2, tasting: 0.6)
        }
    }

    func onboardingFamilyScores(from onboarding: TasteAnalysisResult) -> [String: Double] {
        var scores: [String: Double] = [:]

        for family in onboarding.recommendationDirection.preferredFamilies {
            scores[family, default: 0] += 10
        }

        switch onboarding.primaryProfileCode {
            case "P1":
                add(["Fresh", "Citrus", "Water"], to: &scores, value: 4)
            case "P2":
                add(["Citrus", "Fruity", "Fresh"], to: &scores, value: 4)
            case "P3":
                add(["Soft Floral", "Amber"], to: &scores, value: 4)
            case "P4":
                add(["Floral", "Soft Floral"], to: &scores, value: 4)
            case "P5":
                add(["Woody", "Amber", "Aromatic"], to: &scores, value: 4)
            case "P6":
                add(["Green", "Aromatic", "Woody"], to: &scores, value: 4)
            case "P7":
                add(["Amber", "Mossy Woods", "Woody"], to: &scores, value: 4)
            case "P8":
                add(["Dry Woods", "Woody Amber"], to: &scores, value: 4)
            default:
                break
        }

        return scores
    }

    func collectionFamilyScores(from collection: [CollectedPerfume]) -> [String: Double] {
        var scores: [String: Double] = [:]

        for perfume in collection {
            let families = [perfume.scentFamily, perfume.scentFamily2]
                .compactMap { $0 }
                .filter { !$0.isEmpty }

            for family in families {
                scores[family, default: 0] += 5
            }
        }

        return scores
    }

    func tastingFamilyScores(from records: [TastingRecord]) -> [String: Double] {
        var scores: [String: Double] = [:]

        for record in records {
            for family in record.mainAccords {
                scores[family, default: 0] += baseScore(for: record.rating)
                scores[family, default: 0] += recencyBonus(for: record.updatedAt)
            }

            for tag in record.moodTags {
                for family in mapMoodTagToFamilies(tag) {
                    scores[family, default: 0] += 2
                }
            }
        }

        return scores
    }

    func mergeScores(
        onboardingScores: [String: Double],
        collectionScores: [String: Double],
        tastingScores: [String: Double],
        weights: PreferenceWeights
    ) -> [String: Double] {

        let allKeys = Set(onboardingScores.keys)
            .union(collectionScores.keys)
            .union(tastingScores.keys)

        var result: [String: Double] = [:]

        for key in allKeys {
            let onboardingValue = onboardingScores[key, default: 0] * weights.onboarding
            let collectionValue = collectionScores[key, default: 0] * weights.collection
            let tastingValue = tastingScores[key, default: 0] * weights.tasting
            result[key] = onboardingValue + collectionValue + tastingValue
        }

        return result
    }

    func add(_ families: [String], to scores: inout [String: Double], value: Double) {
        for family in families {
            scores[family, default: 0] += value
        }
    }

    func baseScore(for rating: Int) -> Double {
        switch rating {
            case 5: return 10
            case 4: return 8
            case 3: return 5
            case 2: return 1
            case 1: return -2
            default: return 0
        }
    }

    func recencyBonus(for date: Date) -> Double {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 999

        switch days {
            case 0...7: return 2
            case 8...30: return 1
            default: return 0
        }
    }

    func mapMoodTagToFamilies(_ tag: String) -> [String] {
        switch tag {
            case "상큼한": return ["Citrus", "Fresh"]
            case "시원한": return ["Water", "Fresh"]
            case "싱그러운": return ["Green", "Fresh"]
            case "은은한": return ["Soft Floral", "Floral"]
            case "보송보송한": return ["Soft Floral", "Floral"]
            case "따뜻한": return ["Amber", "Woody Amber"]
            case "묵직한": return ["Amber", "Mossy Woods", "Dry Woods"]
            case "무거운": return ["Woody Amber", "Dry Woods"]
            default: return []
        }
    }
}
