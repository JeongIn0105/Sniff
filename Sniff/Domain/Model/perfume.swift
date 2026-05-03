//
//  perfume.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation

enum AccordStrength: String {
    case dominant
    case prominent
    case moderate
    case subtle

    nonisolated init?(rawDescription: String) {
        switch rawDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "dominant":
            self = .dominant
        case "prominent", "strong":
            self = .prominent
        case "moderate":
            self = .moderate
        case "subtle", "light":
            self = .subtle
        default:
            return nil
        }
    }

    nonisolated var weight: Double {
        switch self {
        case .dominant:
            return 1.0
        case .prominent:
            return 0.8
        case .moderate:
            return 0.55
        case .subtle:
            return 0.3
        }
    }
}

struct SeasonRankingEntry {
    let name: String
    let score: Double
}

struct Perfume {
    let id: String
    let name: String
    let brand: String
    let nameAliases: [String]
    let brandAliases: [String]
    let imageUrl: String?
    let rawMainAccords: [String]
    let mainAccords: [String]
    let mainAccordStrengths: [String: AccordStrength]
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let generalNotes: [String]?
    let concentration: String?
    let gender: String?
    let season: [String]?
    let seasonRanking: [SeasonRankingEntry]
    let popularity: Double?
    let situation: [String]?
    let longevity: String?
    let sillage: String?

    nonisolated init(
        id: String,
        name: String,
        brand: String,
        nameAliases: [String] = [],
        brandAliases: [String] = [],
        imageUrl: String?,
        rawMainAccords: [String] = [],
        mainAccords: [String],
        mainAccordStrengths: [String: AccordStrength] = [:],
        topNotes: [String]?,
        middleNotes: [String]?,
        baseNotes: [String]?,
        generalNotes: [String]? = nil,
        concentration: String?,
        gender: String?,
        season: [String]?,
        seasonRanking: [SeasonRankingEntry] = [],
        popularity: Double? = nil,
        situation: [String]?,
        longevity: String?,
        sillage: String?
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.nameAliases = Self.normalizeAliases(nameAliases)
        self.brandAliases = Self.normalizeAliases(brandAliases)
        self.imageUrl = Self.normalizeImageURL(imageUrl)
        self.rawMainAccords = Self.normalizeAliases(rawMainAccords)

        let canonicalMainAccords = ScentFamilyNormalizer.canonicalNames(for: mainAccords)
        self.mainAccords = canonicalMainAccords
        self.mainAccordStrengths = Self.normalizeAccordStrengths(
            from: mainAccordStrengths,
            orderedMainAccords: canonicalMainAccords
        )
        self.topNotes = topNotes
        self.middleNotes = middleNotes
        self.baseNotes = baseNotes
        self.generalNotes = generalNotes
        self.concentration = concentration
        self.gender = gender
        self.season = season
        self.seasonRanking = seasonRanking
        self.popularity = popularity
        self.situation = situation
        self.longevity = longevity
        self.sillage = sillage
    }

    nonisolated private static func normalizeAccordStrengths(
        from rawStrengths: [String: AccordStrength],
        orderedMainAccords: [String]
    ) -> [String: AccordStrength] {
        var normalized: [String: AccordStrength] = [:]

        for (rawAccord, strength) in rawStrengths {
            guard let canonical = ScentFamilyNormalizer.canonicalName(for: rawAccord) else { continue }
            let existing = normalized[canonical]?.weight ?? -1
            if strength.weight > existing {
                normalized[canonical] = strength
            }
        }

        let fallbackStrengths: [AccordStrength] = [.dominant, .prominent, .moderate, .subtle]

        for (index, accord) in orderedMainAccords.enumerated() {
            guard normalized[accord] == nil else { continue }
            normalized[accord] = index < fallbackStrengths.count ? fallbackStrengths[index] : .subtle
        }

        return normalized
    }

    nonisolated private static func normalizeImageURL(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized: String
        if trimmed.hasPrefix("//") {
            normalized = "https:\(trimmed)"
        } else if trimmed.hasPrefix("http://") {
            normalized = "https://" + trimmed.dropFirst("http://".count)
        } else {
            normalized = trimmed
        }

        let webPURL = normalized.replacingOccurrences(
            of: ".jpg",
            with: ".webp",
            options: [.caseInsensitive]
        )

        return webPURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? webPURL
    }

    nonisolated private static func normalizeAliases(_ values: [String]) -> [String] {
        var seen = Set<String>()

        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }
}

extension Perfume {
    var collectionDocumentID: String {
        Self.collectionDocumentID(from: id)
    }

    static func collectionDocumentID(from id: String) -> String {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "unknown-perfume" }
        guard trimmed.contains("/") else { return trimmed }

        return trimmed.replacingOccurrences(of: "/", with: "%2F")
    }
}
