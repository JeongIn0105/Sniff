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
            result = result.filter { perfume in
                let accords = Set(perfume.rawMainAccords.map { normalizeString($0) })
                return filter.scentFamilies.contains { family in
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

                return filter.seasons.contains { season in
                    let targetTokens = Set(normalizedSeasonTokens(for: season))
                    return !perfumeSeasonTokens.isDisjoint(with: targetTokens)
                }
            }
        }

        return result
    }

    nonisolated static func sortPerfumes(_ perfumes: [Perfume], sort: SortOption) -> [Perfume] {
        switch sort {
        case .recommended:
            return perfumes
        case .latest:
            // 최신 등록순 — 데이터 모델에 날짜 필드가 없으므로 원본 역순(최근 추가 우선)으로 처리
            return perfumes.reversed()
        case .nameAsc:
            return perfumes.sorted {
                let lhsKey = normalizedSortKey($0.name)
                let rhsKey = normalizedSortKey($1.name)
                if lhsKey != rhsKey { return lhsKey < rhsKey }
                return normalizedSortKey($0.brand) < normalizedSortKey($1.brand)
            }
        case .nameDesc:
            return perfumes.sorted {
                let lhsKey = normalizedSortKey($0.name)
                let rhsKey = normalizedSortKey($1.name)
                if lhsKey != rhsKey { return lhsKey > rhsKey }
                return normalizedSortKey($0.brand) > normalizedSortKey($1.brand)
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
        let spring = normalizeString(Season.spring.displayName)
        let summer = normalizeString(Season.summer.displayName)
        let fall = normalizeString(Season.fall.displayName)
        let winter = normalizeString(Season.winter.displayName)

        switch normalized {
        case let value where value == spring || value == "spring":
            return [spring, "spring"]
        case let value where value == summer || value == "summer":
            return [summer, "summer"]
        case let value where value == fall || value == "fall" || value == "autumn":
            return [fall, "fall", "autumn"]
        case let value where value == winter || value == "winter":
            return [winter, "winter"]
        default:
            return [normalized]
        }
    }

    nonisolated private static func normalizedSortKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
