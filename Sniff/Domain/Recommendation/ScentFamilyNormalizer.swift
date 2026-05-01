//
//  ScentFamilyNormalizer.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.16.
//

import Foundation

enum ScentFamilyNormalizer {

    nonisolated static func canonicalName(for value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedKey = trimmed
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        switch normalizedKey {
        case "citrus", "fresh citrus", "lemon", "bergamot", "orange", "시트러스":
            return "Citrus"
        case "water", "aquatic", "marine", "ozonic", "watery", "aqua", "ocean",
             "워터", "워터리", "아쿠아틱", "마린":
            return "Water"
        case "green", "fresh", "clean fresh", "vegetal", "grass", "그린", "프레시", "프레쉬":
            return "Green"
        case "floral", "white floral", "yellow floral", "rose", "jasmine", "bloom",
             "플로럴", "화이트 플로럴", "로즈":
            return "Floral"
        case "soft floral", "powdery", "aldehydic", "iris", "violet", "soapy", "clean",
             "musk", "musky", "white musk", "soft musk", "clean musk",
             "소프트 플로럴", "파우더리", "머스크", "머스키":
            return "Soft Floral"
        case "fruity", "fruit", "tropical", "juicy", "berry", "프루티":
            return "Fruity"
        case "floral amber", "oriental floral", "floriental", "플로럴 앰버":
            return "Floral Amber"
        case "soft amber", "soft oriental", "vanilla", "gourmand", "sweet", "sweet amber",
             "caramel", "creamy", "tonka bean", "chocolate", "ice cream", "candy",
             "소프트 앰버", "소프트 오리엔탈", "바닐라":
            return "Soft Amber"
        case "amber", "oriental", "warm spicy", "resinous", "balsamic", "incense", "spicy", "warm",
             "앰버", "오리엔탈":
            return "Amber"
        case "woody", "woods", "oud", "sandalwood", "cedar", "vetiver", "wood",
             "우디", "우즈", "우드", "샌달우드", "시더":
            return "Woods"
        case "woody amber", "우디 앰버":
            return "Woody Amber"
        case "dry woods", "dry wood", "dry", "leather", "smoky", "tobacco",
             "드라이 우즈", "레더", "스모키":
            return "Dry Woods"
        case "mossy woods", "mossy", "moss", "oakmoss", "chypre", "earthy", "patchouli",
             "모시 우즈", "모씨 우즈", "어시", "파출리":
            return "Mossy Woods"
        case "aromatic", "herbal", "lavender", "fougere", "fresh spicy", "아로마틱", "허벌", "라벤더":
            return "Aromatic"
        default:
            return trimmed
        }
    }

    nonisolated static func canonicalNames(for values: [String]) -> [String] {
        var seen = Set<String>()

        return values
            .compactMap { canonicalName(for: $0) }
            .filter { seen.insert($0).inserted }
    }
}
