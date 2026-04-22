//
//  SearchFilterEngine.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

enum SearchFilterEngine {
    nonisolated static func apply(
        perfumes: [Perfume],
        filter: SearchFilter,
        sort: SortOption = .recommended
    ) -> [Perfume] {
        sortPerfumes(filterPerfumes(perfumes, filter: filter), sort: sort)
    }

    nonisolated static func filterPerfumes(_ perfumes: [Perfume], filter: SearchFilter) -> [Perfume] {
        var result = perfumes

        if !filter.scentFamilies.isEmpty {
            let targetFamilies = Set(filter.scentFamilies.flatMap(\.matchingRawAccords))
            result = result.filter { perfume in
                let accords = Set(perfume.rawMainAccords.map { normalizeString($0) })
                return !accords.isDisjoint(with: targetFamilies)
            }
        }

        if !filter.moodTags.isEmpty {
            let targetAccords = Set(
                filter.moodTags
                    .flatMap { $0.relatedScentFamilies }
                    .flatMap { $0.matchingRawAccords }
                    .map { normalizeString($0) }
            )
            result = result.filter { perfume in
                let accords = Set(perfume.rawMainAccords.map { normalizeString($0) })
                return !accords.isDisjoint(with: targetAccords)
            }
        }

        if !filter.concentrations.isEmpty {
            let targetValues = Set(filter.concentrations.flatMap(\.fragellaValues))
            result = result.filter { perfume in
                guard let concentration = normalizeOptionalString(perfume.concentration) else { return false }
                return targetValues.contains(concentration)
            }
        }

        if !filter.seasons.isEmpty {
            let targetSeasons = Set(
                filter.seasons.flatMap { season in
                    normalizedSeasonTokens(for: season)
                }
            )
            if !targetSeasons.isEmpty {
                result = result.filter { perfume in
                    guard let seasons = perfume.season else { return false }
                    return seasons.contains { seasonValue in
                        normalizedSeasonTokens(for: seasonValue).contains { targetSeasons.contains($0) }
                    }
                }
            }
        }

        return result
    }

    nonisolated static func sortPerfumes(_ perfumes: [Perfume], sort: SortOption) -> [Perfume] {
        switch sort {
        case .recommended:
            return perfumes
        case .nameAsc:
            return perfumes.sorted {
                let lhsKey = englishSortKey(for: $0.name)
                let rhsKey = englishSortKey(for: $1.name)
                if lhsKey != rhsKey { return lhsKey < rhsKey }
                return $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending
            }
        case .nameDesc:
            return perfumes.sorted {
                let lhsKey = englishSortKey(for: $0.name)
                let rhsKey = englishSortKey(for: $1.name)
                if lhsKey != rhsKey { return lhsKey > rhsKey }
                return $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedDescending
            }
        }
    }

    nonisolated private static func normalizeOptionalString(_ value: String?) -> String? {
        guard let value else { return nil }
        return normalizeString(value)
    }

    nonisolated private static func normalizeString(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static func normalizedSeasonTokens(for season: Season) -> [String] {
        let display = normalizeString(season.displayName)
        let fragella = season.fragellaValue.map(normalizeString)
        return [display, fragella].compactMap { $0 }
    }

    nonisolated private static func normalizedSeasonTokens(for rawValue: String) -> [String] {
        let normalized = normalizeString(rawValue)

        switch normalized {
        case "봄", "spring":
            return ["봄", "spring"]
        case "여름", "summer":
            return ["여름", "summer"]
        case "가을", "fall", "autumn":
            return ["가을", "fall", "autumn"]
        case "겨울", "winter":
            return ["겨울", "winter"]
        default:
            return [normalized]
        }
    }

    nonisolated private static func englishSortKey(for value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
