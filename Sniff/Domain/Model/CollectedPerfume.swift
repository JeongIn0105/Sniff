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

    var scentFamilies: [String] {
        mainAccords.filter { !$0.isEmpty }
    }
}

extension CollectedPerfume {
    init(
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

    init(
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

    init(
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
    func toPerfume() -> Perfume {
        Perfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            rawMainAccords: mainAccords,
            mainAccords: mainAccords,
            mainAccordStrengths: accordStrengths,
            topNotes: nil,
            middleNotes: nil,
            baseNotes: nil,
            concentration: nil,
            gender: nil,
            season: nil,
            seasonRanking: [],
            situation: nil,
            longevity: nil,
            sillage: nil
        )
    }
}
