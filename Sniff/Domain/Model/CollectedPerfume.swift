//
//  CollectedPerfume.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

enum CollectedPerfumeUsageStatus: String, CaseIterable, Codable {
    case inUse = "사용중"
    case unopened = "새상품"
    case finished = "다 쓴 향수"

    nonisolated var displayName: String { rawValue }
}

enum CollectedPerfumeUsageFrequency: String, CaseIterable, Codable {
    case often = "자주"
    case sometimes = "가끔"
    case rarely = "거의 안 씀"

    nonisolated var displayName: String { rawValue }
}

enum CollectedPerfumePreferenceLevel: String, CaseIterable, Codable {
    case liked = "좋아요"
    case neutral = "보통"
    case disappointed = "아쉬워요"

    nonisolated var displayName: String { rawValue }
}

struct CollectedPerfumeRegistrationInfo: Codable {
    let usageStatus: CollectedPerfumeUsageStatus
    let usageFrequency: CollectedPerfumeUsageFrequency
    let preferenceLevel: CollectedPerfumePreferenceLevel
    let memo: String?

    nonisolated init(
        usageStatus: CollectedPerfumeUsageStatus = .inUse,
        usageFrequency: CollectedPerfumeUsageFrequency = .sometimes,
        preferenceLevel: CollectedPerfumePreferenceLevel = .liked,
        memo: String? = nil
    ) {
        self.usageStatus = usageStatus
        self.usageFrequency = usageFrequency
        self.preferenceLevel = preferenceLevel
        let trimmedMemo = memo?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.memo = (trimmedMemo?.isEmpty ?? true) ? nil : trimmedMemo
    }
}

struct CollectedPerfume {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let accordStrengths: [String: AccordStrength]
    let memo: String?
    let createdAt: Date?
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let generalNotes: [String]?
    let seasonRanking: [SeasonRankingEntry]
    let concentration: String?
    let longevity: String?
    let sillage: String?
    let usageStatus: CollectedPerfumeUsageStatus?
    let usageFrequency: CollectedPerfumeUsageFrequency?
    let preferenceLevel: CollectedPerfumePreferenceLevel?

    var scentFamilies: [String] {
        mainAccords.filter { !$0.isEmpty }
    }

    nonisolated init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength] = [:],
        memo: String? = nil,
        createdAt: Date? = nil,
        topNotes: [String]? = nil,
        middleNotes: [String]? = nil,
        baseNotes: [String]? = nil,
        generalNotes: [String]? = nil,
        seasonRanking: [SeasonRankingEntry] = [],
        concentration: String? = nil,
        longevity: String? = nil,
        sillage: String? = nil,
        usageStatus: CollectedPerfumeUsageStatus? = nil,
        usageFrequency: CollectedPerfumeUsageFrequency? = nil,
        preferenceLevel: CollectedPerfumePreferenceLevel? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageUrl = imageUrl
        self.mainAccords = mainAccords
        self.accordStrengths = accordStrengths
        self.memo = memo
        self.createdAt = createdAt
        self.topNotes = topNotes
        self.middleNotes = middleNotes
        self.baseNotes = baseNotes
        self.generalNotes = generalNotes
        self.seasonRanking = seasonRanking
        self.concentration = concentration
        self.longevity = longevity
        self.sillage = sillage
        self.usageStatus = usageStatus
        self.usageFrequency = usageFrequency
        self.preferenceLevel = preferenceLevel
    }

    nonisolated init(
        id: String,
        name: String,
        brand: String,
        scentFamily: String?,
        scentFamily2: String?,
        imageURL: String?,
        createdAt: Date?
    ) {
        let legacyFamilies: [String?] = [scentFamily, scentFamily2]
        let mainAccords = legacyFamilies.compactMap { rawValue -> String? in
            guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageURL,
            mainAccords: mainAccords,
            createdAt: createdAt
        )
    }
}

extension CollectedPerfume {
    nonisolated func toPerfume() -> Perfume {
        Perfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            rawMainAccords: mainAccords,
            mainAccords: mainAccords,
            mainAccordStrengths: accordStrengths,
            topNotes: topNotes,
            middleNotes: middleNotes,
            baseNotes: baseNotes,
            generalNotes: generalNotes,
            concentration: concentration,
            gender: nil,
            season: nil,
            seasonRanking: seasonRanking,
            situation: nil,
            longevity: longevity,
            sillage: sillage
        )
    }
}
