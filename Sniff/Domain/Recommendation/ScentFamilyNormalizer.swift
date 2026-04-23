//
//  ScentFamilyNormalizer.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.16.
//

import Foundation

enum ScentFamilyNormalizer {

    static func canonicalName(for value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedKey = trimmed
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        switch normalizedKey {
        case "citrus":
            return "Citrus"
        case "water", "aquatic", "marine", "ozonic":
            return "Water"
        case "green", "fresh", "clean fresh":
            return "Green"
        case "floral", "white floral", "yellow floral", "rose":
            return "Floral"
        case "soft floral", "powdery", "soapy", "clean", "musk", "musky", "white musk", "soft musk", "clean musk":
            return "Soft Floral"
        case "fruity":
            return "Fruity"
        case "floral amber", "oriental floral":
            return "Floral Amber"
        case "soft amber", "soft oriental", "vanilla", "balsamic", "gourmand", "sweet amber":
            return "Soft Amber"
        case "amber", "oriental", "warm spicy", "resinous":
            return "Amber"
        case "woody", "oud", "sandalwood", "cedar", "wood":
            return "Woods"
        case "woody amber":
            return "Woody Amber"
        case "dry woods", "dry wood", "leather", "smoky":
            return "Dry Woods"
        case "mossy woods", "earthy", "patchouli":
            return "Mossy Woods"
        case "aromatic", "herbal", "lavender", "fresh spicy":
            return "Aromatic"
        default:
            return trimmed
        }
    }

    static func canonicalNames(for values: [String]) -> [String] {
        var seen = Set<String>()

        return values
            .compactMap { canonicalName(for: $0) }
            .filter { seen.insert($0).inserted }
    }
}
