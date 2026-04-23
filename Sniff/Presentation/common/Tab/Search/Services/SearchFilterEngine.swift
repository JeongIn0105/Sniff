//
//  SearchFilterEngine.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation

enum SearchFilterEngine {
    static func apply(
        perfumes: [Perfume],
        filter: SearchFilter,
        sort: SortOption = .recommended
    ) -> [Perfume] {
        sortPerfumes(filterPerfumes(perfumes, filter: filter), sort: sort)
    }

    static func filterPerfumes(_ perfumes: [Perfume], filter: SearchFilter) -> [Perfume] {
        var result = perfumes

        if !filter.scentFamilies.isEmpty {
            result = result.filter { perfume in
                let accords = Set(perfume.rawMainAccords.map { normalizeString($0) })
                return filter.scentFamilies.allSatisfy { family in
                    let targetAccords = Set(family.matchingRawAccords.map(normalizeString))
                    return !accords.isDisjoint(with: targetAccords)
                }
            }
        }

        if !filter.moodTags.isEmpty {
            result = result.filter { perfume in
                let accords = Set(perfume.rawMainAccords.map { normalizeString($0) })
                return filter.moodTags.allSatisfy { tag in
                    let targetAccords = Set(
                        tag.relatedScentFamilies
                            .flatMap(\.matchingRawAccords)
                            .map(normalizeString)
                    )
                    return !accords.isDisjoint(with: targetAccords)
                }
            }
        }

        if !filter.concentrations.isEmpty {
            result = result.filter { perfume in
                guard let concentration = normalizeOptionalString(perfume.concentration) else { return false }
                return filter.concentrations.allSatisfy { concentrationFilter in
                    let targetValues = Set(concentrationFilter.fragellaValues.map(normalizeString))
                    return targetValues.contains(concentration)
                }
            }
        }

        if !filter.seasons.isEmpty {
            result = result.filter { perfume in
                guard let seasons = perfume.season else { return false }
                let perfumeSeasonTokens = Set(
                    seasons.flatMap { seasonValue in
                        normalizedSeasonTokens(for: seasonValue)
                    }
                )

                return filter.seasons.allSatisfy { season in
                    let targetTokens = Set(normalizedSeasonTokens(for: season))
                    return !perfumeSeasonTokens.isDisjoint(with: targetTokens)
                }
            }
        }

        return result
    }

    static func sortPerfumes(_ perfumes: [Perfume], sort: SortOption) -> [Perfume] {
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

    private static func normalizeOptionalString(_ value: String?) -> String? {
        guard let value else { return nil }
        return normalizeString(value)
    }

    private static func normalizeString(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func normalizedSeasonTokens(for season: Season) -> [String] {
        let display = normalizeString(season.displayName)
        let fragella = season.fragellaValue.map(normalizeString)
        return [display, fragella].compactMap { $0 }
    }

    private static func normalizedSeasonTokens(for rawValue: String) -> [String] {
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

    private static func englishSortKey(for value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
