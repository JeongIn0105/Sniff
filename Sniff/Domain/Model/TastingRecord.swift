//
//  TastingRecord.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation

struct TastingRecord {
    let id: String
    let perfumeName: String
    let brandName: String
    let mainAccords: [String]
    let accordStrengths: [String: AccordStrength]
    let rating: Int
    let moodTags: [String]
    let memo: String?
    let wantToRevisit: String?
    let revisitDesire: String?
    let createdAt: Date
    let updatedAt: Date
}

extension TastingRecord {
    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        rating: Int,
        moodTags: [String],
        memo: String?,
        wantToRevisit: String?,
        updatedAt: Date
    ) {
        self.init(
            id: id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            rating: rating,
            moodTags: moodTags,
            memo: memo,
            wantToRevisit: wantToRevisit,
            revisitDesire: wantToRevisit,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        rating: Int,
        moodTags: [String],
        revisitDesire: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.init(
            id: id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            accordStrengths: [:],
            rating: rating,
            moodTags: moodTags,
            memo: nil,
            wantToRevisit: revisitDesire,
            revisitDesire: revisitDesire,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        rating: Int,
        moodTags: [String],
        updatedAt: Date
    ) {
        self.init(
            id: id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            accordStrengths: [:],
            rating: rating,
            moodTags: moodTags,
            memo: nil,
            wantToRevisit: nil,
            revisitDesire: nil,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }
}

extension TastingRecord {
    static let revisitOptions: [String] = [
        "매일 뿌리고 싶어",
        "가끔 꺼내고 싶어",
        "기억에 남아, 근데 내 향은 아니야",
        "다시 맡고 싶지 않아"
    ]
}
