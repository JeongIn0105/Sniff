//
//  GeminiTasteAnalysisPayloads.swift
//  Sniff
//

import Foundation

struct TasteAnalysisInput {
    let experience: String
    let vibes: [String]
    let images: [String]
    let aggregatedProfile: AggregatedProfileForGemini?
    let records: [TastingRecordForGemini]

    init(
        experience: String,
        vibes: [String],
        images: [String],
        aggregatedProfile: AggregatedProfileForGemini? = nil,
        records: [TastingRecordForGemini] = []
    ) {
        self.experience = experience
        self.vibes = vibes
        self.images = images
        self.aggregatedProfile = aggregatedProfile
        self.records = records
    }
}

struct AggregatedProfileForGemini: Codable {
    let topFamilies: [String]
    let topMoods: [String]
    let avoidedFamilies: [String]

    nonisolated init(profile: UserTasteProfile) {
        let rankedFamilies = profile.scentVector
            .sorted { $0.value > $1.value }
            .map(\.key)
        let displayFamilies = rankedFamilies.isEmpty ? profile.preferredFamilies : rankedFamilies

        topFamilies = Array(displayFamilies.prefix(3))
        topMoods = Array(profile.preferredImpressions.prefix(3))
        avoidedFamilies = profile.scentVector
            .filter { $0.value > 0 }
            .sorted { $0.value < $1.value }
            .prefix(3)
            .map(\.key)
    }
}

extension AggregatedProfileForGemini {
    nonisolated init(
        familyRatios: [String: Double],
        moods: [String]
    ) {
        topFamilies = familyRatios
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)
        topMoods = Array(moods.prefix(3))
        avoidedFamilies = familyRatios
            .filter { $0.value > 0 }
            .sorted { $0.value < $1.value }
            .prefix(3)
            .map(\.key)
    }
}

struct TastingRecordForGemini: Codable {
    let perfumeName: String
    let brandName: String
    let mainAccords: [String]
    let moodTags: [String]
    let revisitDesire: String?

    nonisolated init(record: TastingRecord) {
        perfumeName = record.perfumeName
        brandName = record.brandName
        mainAccords = Array(record.mainAccords.prefix(3))
        moodTags = record.moodTags
        if let trimmedRevisitDesire = record.revisitDesire?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmedRevisitDesire.isEmpty {
            revisitDesire = trimmedRevisitDesire
        } else {
            revisitDesire = nil
        }
    }

    nonisolated static func supportingRecords(
        from records: [TastingRecord],
        limit: Int = 5
    ) -> [TastingRecordForGemini] {
        records
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map(TastingRecordForGemini.init(record:))
    }
}
