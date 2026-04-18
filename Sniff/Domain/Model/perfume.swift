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

    init?(rawDescription: String) {
        switch rawDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "dominant":
            self = .dominant
        case "prominent":
            self = .prominent
        case "moderate":
            self = .moderate
        case "subtle":
            self = .subtle
        default:
            return nil
        }
    }

    var weight: Double {
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

struct Perfume {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let mainAccordStrengths: [String: AccordStrength]
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let concentration: String?
    let gender: String?
    let season: [String]?
    let situation: [String]?
    let longevity: String?
    let sillage: String?

    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String?,
        mainAccords: [String],
        mainAccordStrengths: [String: AccordStrength] = [:],
        topNotes: [String]?,
        middleNotes: [String]?,
        baseNotes: [String]?,
        concentration: String?,
        gender: String?,
        season: [String]?,
        situation: [String]?,
        longevity: String?,
        sillage: String?
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageUrl = Self.normalizeImageURL(imageUrl)

        let canonicalMainAccords = ScentFamilyNormalizer.canonicalNames(for: mainAccords)
        self.mainAccords = canonicalMainAccords
        self.mainAccordStrengths = Self.normalizeAccordStrengths(
            from: mainAccordStrengths,
            orderedMainAccords: canonicalMainAccords
        )
        self.topNotes = topNotes
        self.middleNotes = middleNotes
        self.baseNotes = baseNotes
        self.concentration = concentration
        self.gender = gender
        self.season = season
        self.situation = situation
        self.longevity = longevity
        self.sillage = sillage
    }

    private static func normalizeAccordStrengths(
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

    private static func normalizeImageURL(_ value: String?) -> String? {
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

        return normalized.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? normalized
    }
}
