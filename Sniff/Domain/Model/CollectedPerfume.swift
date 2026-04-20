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
        [scentFamily, scentFamily2].compactMap { $0 }.filter { !$0.isEmpty }
    }
}

// MARK: - 편의 생성자
extension CollectedPerfume {

    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        memo: String?,
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            memo: memo,
            createdAt: createdAt
        )
    }

    init(
        id: String,
        name: String,
        brand: String,
        scentFamily: String?,
        scentFamily2: String?,
        imageURL: String?,
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            scentFamily: scentFamily,
            scentFamily2: scentFamily2,
            imageUrl: imageURL,
            mainAccords: [],
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

// MARK: - Perfume 변환
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
            situation: nil,
            longevity: nil,
            sillage: nil
        )
    }
}