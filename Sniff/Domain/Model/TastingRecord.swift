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
    let revisitDesire: String?
    let longevityExperience: String?
    let sillageExperience: String?
    let drydownChange: String?
    let skinChemistry: String?
    let wearSituations: [String]
    let weatherContexts: [String]
    let applicationAreas: [String]
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
        revisitDesire: String?,
        longevityExperience: String? = nil,
        sillageExperience: String? = nil,
        drydownChange: String? = nil,
        skinChemistry: String? = nil,
        wearSituations: [String] = [],
        weatherContexts: [String] = [],
        applicationAreas: [String] = [],
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
            revisitDesire: revisitDesire,
            longevityExperience: longevityExperience,
            sillageExperience: sillageExperience,
            drydownChange: drydownChange,
            skinChemistry: skinChemistry,
            wearSituations: wearSituations,
            weatherContexts: weatherContexts,
            applicationAreas: applicationAreas,
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
            revisitDesire: revisitDesire,
            longevityExperience: nil,
            sillageExperience: nil,
            drydownChange: nil,
            skinChemistry: nil,
            wearSituations: [],
            weatherContexts: [],
            applicationAreas: [],
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
            revisitDesire: nil,
            longevityExperience: nil,
            sillageExperience: nil,
            drydownChange: nil,
            skinChemistry: nil,
            wearSituations: [],
            weatherContexts: [],
            applicationAreas: [],
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }
}

extension TastingRecord {
    static let revisitOptions: [String] = AppStrings.DomainDisplay.TastingNoteData.revisitDesireList
}
