//
//  RecommendationEngine+Helpers.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

import Foundation

extension RecommendationEngine {

    func uniquePerfumes(from perfumes: [FragellaPerfume]) -> [FragellaPerfume] {
        var seen = Set<String>()

        return perfumes.filter { perfume in
            seen.insert(perfume.id).inserted
        }
    }

    func fallbackPerfumes(for profile: UserTasteProfile) -> [FragellaPerfume] {
        let catalog = [
            FragellaPerfume(
                id: "local-001",
                name: "Lazy Sunday Morning",
                brand: "Maison Margiela",
                imageUrl: nil,
                mainAccords: ["Soft Floral", "Musk"],
                topNotes: ["Pear", "Lily of the Valley"],
                middleNotes: ["Rose", "Iris"],
                baseNotes: ["White Musk", "Ambrette"],
                concentration: "EDT",
                gender: "Unisex",
                season: ["Spring"],
                situation: ["Daily"],
                longevity: "Medium",
                sillage: "Soft"
            ),
            FragellaPerfume(
                id: "local-002",
                name: "Wood Sage & Sea Salt",
                brand: "Jo Malone",
                imageUrl: nil,
                mainAccords: ["Fresh", "Woody"],
                topNotes: ["Ambrette"],
                middleNotes: ["Sea Salt"],
                baseNotes: ["Sage"],
                concentration: "Cologne",
                gender: "Unisex",
                season: ["Spring", "Summer"],
                situation: ["Daily", "Weekend"],
                longevity: "Light",
                sillage: "Soft"
            ),
            FragellaPerfume(
                id: "local-003",
                name: "Chance Eau Tendre",
                brand: "CHANEL",
                imageUrl: nil,
                mainAccords: ["Fruity", "Floral"],
                topNotes: ["Grapefruit", "Quince"],
                middleNotes: ["Jasmine"],
                baseNotes: ["White Musk"],
                concentration: "EDT",
                gender: "Women",
                season: ["Spring"],
                situation: ["Daily", "Date"],
                longevity: "Medium",
                sillage: "Soft"
            ),
            FragellaPerfume(
                id: "local-004",
                name: "Philosykos",
                brand: "Diptyque",
                imageUrl: nil,
                mainAccords: ["Green", "Woody"],
                topNotes: ["Fig Leaf"],
                middleNotes: ["Fig"],
                baseNotes: ["Cedar"],
                concentration: "EDT",
                gender: "Unisex",
                season: ["Spring", "Summer"],
                situation: ["Daily"],
                longevity: "Medium",
                sillage: "Moderate"
            ),
            FragellaPerfume(
                id: "local-005",
                name: "Santal 33",
                brand: "Le Labo",
                imageUrl: nil,
                mainAccords: ["Woody", "Amber"],
                topNotes: ["Cardamom"],
                middleNotes: ["Iris", "Violet"],
                baseNotes: ["Sandalwood", "Leather"],
                concentration: "EDP",
                gender: "Unisex",
                season: ["Fall"],
                situation: ["Daily", "Night"],
                longevity: "Long",
                sillage: "Moderate"
            ),
            FragellaPerfume(
                id: "local-006",
                name: "Light Blue",
                brand: "Dolce&Gabbana",
                imageUrl: nil,
                mainAccords: ["Citrus", "Fresh"],
                topNotes: ["Sicilian Lemon", "Apple"],
                middleNotes: ["Jasmine", "Bamboo"],
                baseNotes: ["Cedar", "Musk"],
                concentration: "EDT",
                gender: "Women",
                season: ["Summer"],
                situation: ["Daily", "Travel"],
                longevity: "Medium",
                sillage: "Moderate"
            )
        ]

        let ranked = catalog
            .map { makeRecommendedPerfume(from: $0, profile: profile) }
            .sorted { $0.score > $1.score }
            .map { $0.perfume }

        return Array(ranked.prefix(6))
    }
}
