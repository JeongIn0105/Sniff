//
//  CollectedPerfume.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import Foundation

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
    let seasonRanking: [SeasonRankingEntry]
    let concentration: String?
    let longevity: String?
    let sillage: String?

    var scentFamilies: [String] {
        mainAccords.filter { !$0.isEmpty }
    }
}

extension CollectedPerfume {
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
            guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return nil
            }
            return value
        }

        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageURL,
            mainAccords: mainAccords,
            accordStrengths: [:],
            memo: nil,
            createdAt: createdAt
        )
    }

    nonisolated init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            memo: nil,
            createdAt: createdAt
        )
    }

    nonisolated init(
        id: String,
        name: String,
        brand: String,
        mainAccords: [String],
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: nil,
            mainAccords: mainAccords,
            accordStrengths: [:],
            memo: nil,
            createdAt: createdAt
        )
    }
}

extension CollectedPerfume {
    nonisolated init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        memo: String?,
        createdAt: Date?,
        topNotes: [String]? = nil,
        middleNotes: [String]? = nil,
        baseNotes: [String]? = nil,
        seasonRanking: [SeasonRankingEntry] = [],
        concentration: String? = nil,
        longevity: String? = nil,
        sillage: String? = nil
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
        self.seasonRanking = seasonRanking
        self.concentration = concentration
        self.longevity = longevity
        self.sillage = sillage
    }

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
