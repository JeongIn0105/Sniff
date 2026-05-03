//
//  FragellaResponseParser.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum FragellaResponseParser {

    static func parsePerfumeList(from data: Data) throws -> [Perfume] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)

        if let array = jsonObject as? [[String: Any]] {
            return array.compactMap { parsePerfume(dictionary: $0) }
        }

        guard let dictionary = jsonObject as? [String: Any] else {
            throw FragellaError.decodingFailed
        }

        for key in ["data", "results", "items", "fragrances", "perfumes"] {
            if let array = dictionary[key] as? [[String: Any]] {
                return array.compactMap { parsePerfume(dictionary: $0) }
            }
        }

        if let perfume = parsePerfume(dictionary: dictionary) {
            return [perfume]
        }

        throw FragellaError.decodingFailed
    }

    static func parsePerfumeDetail(from data: Data) throws -> Perfume {
        guard let perfume = try parsePerfumeList(from: data).first else {
            throw FragellaError.decodingFailed
        }
        return perfume
    }

    private static func parsePerfume(dictionary: [String: Any]) -> Perfume? {
        guard
            let name = stringValue(forKeys: ["name", "Name", "perfume_name", "fragrance_name"], in: dictionary),
            let brand = stringValue(forKeys: ["brand", "Brand", "brand_name", "house"], in: dictionary)
        else { return nil }

        let id = stringValue(forKeys: ["id", "ID", "perfume_id", "fragrance_id"], in: dictionary)
            ?? makeSyntheticID(name: name, brand: brand)

        let rawMainAccords = rawMainAccords(in: dictionary)

        return Perfume(
            id: id,
            name: name,
            brand: brand,
            nameAliases: stringArrayValue(
                forKeys: ["aliases", "name_aliases", "nameAliases", "perfume_aliases"],
                in: dictionary
            ) ?? [],
            brandAliases: stringArrayValue(
                forKeys: ["brand_aliases", "brandAliases", "house_aliases"],
                in: dictionary
            ) ?? [],
            imageUrl: stringValue(
                forKeys: ["image_url", "Image URL", "image", "imageURL", "thumbnail_url", "thumbnail", "photo_url"],
                in: dictionary
            ),
            rawMainAccords: rawMainAccords,
            mainAccords: ScentFamilyNormalizer.canonicalNames(for: rawMainAccords),
            mainAccordStrengths: mainAccordStrengths(in: dictionary),
            topNotes: noteNames(in: dictionary, keys: ["Top", "top"])
                ?? stringArrayValue(forKeys: ["top_notes", "topNotes"], in: dictionary),
            middleNotes: noteNames(in: dictionary, keys: ["Middle", "Heart", "middle", "heart"])
                ?? stringArrayValue(forKeys: ["middle_notes", "middleNotes", "heart_notes"], in: dictionary),
            baseNotes: noteNames(in: dictionary, keys: ["Base", "base"])
                ?? stringArrayValue(forKeys: ["base_notes", "baseNotes"], in: dictionary),
            generalNotes: noteNames(in: dictionary, keys: ["General", "general", "All", "all"])
                ?? stringArrayValue(
                    forKeys: ["general_notes", "generalNotes", "General Notes", "notes", "Notes"],
                    in: dictionary
                ),
            concentration: stringValue(
                forKeys: ["concentration", "Concentration", "OilType", "oilType", "oil_type", "Oil Type"],
                in: dictionary
            ),
            gender: stringValue(forKeys: ["gender", "Gender", "target_gender"], in: dictionary),
            season: seasonRankingNames(in: dictionary)
                ?? stringArrayValue(forKeys: ["season", "seasons"], in: dictionary),
            seasonRanking: seasonRankingEntries(in: dictionary),
            popularity: numericValue(
                forKeys: ["popularity", "Popularity", "popularity_score", "rating", "score", "votes"],
                in: dictionary
            ),
            situation: stringArrayValue(
                forKeys: ["situation", "situations", "occasion", "occasions"],
                in: dictionary
            ),
            longevity: stringValue(forKeys: ["longevity", "Longevity"], in: dictionary),
            sillage: stringValue(forKeys: ["sillage", "Sillage"], in: dictionary)
        )
    }

    private static func rawMainAccords(in dictionary: [String: Any]) -> [String] {
        if let accords = stringArrayValue(forKeys: ["Main Accords", "main_accords"], in: dictionary) {
            return accords
        }

        let fallback = [
            stringValue(forKeys: ["scent_family", "accord", "main_accord"], in: dictionary),
            stringValue(forKeys: ["scent_family2", "secondary_accord", "sub_accord"], in: dictionary)
        ].compactMap { $0 }
        return fallback
    }

    private static func mainAccordStrengths(in dictionary: [String: Any]) -> [String: AccordStrength] {
        guard let rawStrengths = dictionary["Main Accords Percentage"] as? [String: Any] else {
            return [:]
        }

        var result: [String: AccordStrength] = [:]
        for (rawAccord, rawStrength) in rawStrengths {
            guard
                let canonical = ScentFamilyNormalizer.canonicalName(for: rawAccord),
                let strengthString = rawStrength as? String,
                let strength = AccordStrength(rawDescription: strengthString)
            else { continue }

            let existing = result[canonical]?.weight ?? -1
            if strength.weight > existing {
                result[canonical] = strength
            }
        }
        return result
    }

    private static func noteNames(in dictionary: [String: Any], keys: [String]) -> [String]? {
        guard let notesObject = dictionary["Notes"] as? [String: Any] else { return nil }
        for key in keys {
            guard let values = notesObject[key] as? [[String: Any]] else { continue }
            let names = values
                .compactMap { ($0["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !names.isEmpty { return names }
        }
        return nil
    }

    private static func seasonRankingNames(in dictionary: [String: Any]) -> [String]? {
        guard let raw = dictionary["Season Ranking"] as? [[String: Any]] else { return nil }
        let seasons = raw
            .compactMap { ($0["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return seasons.isEmpty ? nil : seasons
    }

    private static func seasonRankingEntries(in dictionary: [String: Any]) -> [SeasonRankingEntry] {
        guard let raw = dictionary["Season Ranking"] as? [[String: Any]] else { return [] }

        return raw.enumerated().compactMap { index, item in
            guard let rawName = item["name"] as? String else { return nil }
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }

            let fallbackScore = Double(max(raw.count - index, 1))
            let score =
                numericValue(forKeys: ["score", "value", "percentage", "percent", "rank", "votes"], in: item)
                ?? fallbackScore

            return SeasonRankingEntry(name: name, score: score)
        }
    }

    private static func stringValue(forKeys keys: [String], in dictionary: [String: Any]) -> String? {
        for key in keys {
            guard let raw = dictionary[key] else { continue }
            if let s = raw as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
            if let n = raw as? NSNumber { return n.stringValue }
        }
        return nil
    }

    private static func stringArrayValue(forKeys keys: [String], in dictionary: [String: Any]) -> [String]? {
        for key in keys {
            guard let raw = dictionary[key] else { continue }
            if let arr = raw as? [String] {
                let filtered = arr
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !filtered.isEmpty { return filtered }
            }
            if let arr = raw as? [Any] {
                let strings = arr.compactMap { value -> String? in
                    if let s = value as? String {
                        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                        return trimmed.isEmpty ? nil : trimmed
                    }
                    if let n = value as? NSNumber { return n.stringValue }
                    return nil
                }
                if !strings.isEmpty { return strings }
            }
            if let s = raw as? String {
                let parts = s.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !parts.isEmpty { return parts }
            }
        }
        return nil
    }

    private static func numericValue(forKeys keys: [String], in dictionary: [String: Any]) -> Double? {
        for key in keys {
            guard let raw = dictionary[key] else { continue }
            if let number = raw as? NSNumber { return number.doubleValue }
            if let string = raw as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if let value = Double(trimmed) { return value }
            }
        }
        return nil
    }

    private static func makeSyntheticID(name: String, brand: String) -> String {
        "\(brand)-\(name)"
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
            .map(String.init)
            .joined()
    }
}
