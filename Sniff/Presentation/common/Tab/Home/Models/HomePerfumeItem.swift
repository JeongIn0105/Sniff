//
//  HomePerfumeItem.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//
import Foundation

struct HomePerfumeItem {
    let perfume: Perfume
    let id: String
    let brandName: String
    let perfumeName: String
    let accordsText: String
    let recommendationReason: String
    let imageURL: String?
    let hasTastingRecord: Bool

    var parsedAccords: [String] {
        accordsText
            .components(separatedBy: "•")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
