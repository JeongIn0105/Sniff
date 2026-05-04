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
                let perfumeSeasonTokens = seasonTokens(for: perfume)

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
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }

    nonisolated private static func normalizedSeasonTokens(for season: Season) -> [String] {
        let display = normalizeString(season.displayName)
        let fragella = season.fragellaValue.map(normalizeString)
        return [display, fragella].compactMap { $0 }
    }

    nonisolated private static func seasonTokens(for perfume: Perfume) -> Set<String> {
        let explicitSeasons = topSeasonRankingNames(for: perfume)
            ?? perfume.season
            ?? []
        var tokens = Set(
            explicitSeasons.flatMap { seasonValue in
                normalizedSeasonTokens(for: seasonValue)
            }
        )

        if tokens.isEmpty {
            tokens.formUnion(inferredSeasonTokens(for: perfume))
        }

        return tokens
    }

    nonisolated private static func topSeasonRankingNames(for perfume: Perfume) -> [String]? {
        let names = perfume.seasonRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)

        return names.isEmpty ? nil : Array(names)
    }

    nonisolated private static func inferredSeasonTokens(for perfume: Perfume) -> Set<String> {
        let text = seasonInferenceText(for: perfume)
        guard !text.isEmpty else { return [] }

        var tokens = Set<String>()

        if containsAny(
            text,
            [
                "green", "fresh", "floral", "soft floral", "white floral", "rose",
                "violet", "iris", "powdery", "aromatic", "herbal", "lavender"
            ]
        ) {
            tokens.formUnion(normalizedSeasonTokens(for: .spring))
        }

        if containsAny(
            text,
            [
                "citrus", "aquatic", "water", "marine", "ozonic", "tropical",
                "coconut", "fruity", "fresh spicy", "sea", "salt", "bergamot",
                "lemon", "orange", "grapefruit"
            ]
        ) {
            tokens.formUnion(normalizedSeasonTokens(for: .summer))
        }

        if containsAny(
            text,
            [
                "woody", "wood", "woods", "patchouli", "moss", "earthy", "tobacco",
                "leather", "coffee", "cacao", "warm spicy", "spicy", "cinnamon",
                "nutmeg", "cedar", "sandalwood", "vetiver"
            ]
        ) {
            tokens.formUnion(normalizedSeasonTokens(for: .fall))
        }

        if containsAny(
            text,
            [
                "amber", "vanilla", "sweet", "balsamic", "resinous", "oud",
                "smoky", "incense", "animalic", "honey", "caramel", "tonka",
                "gourmand", "chocolate", "cocoa", "musk"
            ]
        ) {
            tokens.formUnion(normalizedSeasonTokens(for: .winter))
        }

        return tokens
    }

    nonisolated private static func seasonInferenceText(for perfume: Perfume) -> String {
        // 타입 체커 시간 초과 방지를 위해 표현식을 단계적으로 분리
        var values: [String] = perfume.rawMainAccords
        values += perfume.mainAccords
        values += Array(perfume.mainAccordStrengths.keys)
        values += perfume.topNotes ?? []
        values += perfume.middleNotes ?? []
        values += perfume.baseNotes ?? []
        values += perfume.generalNotes ?? []
        values += perfume.situation ?? []

        return values.map(normalizeString).joined(separator: " ")
    }

    nonisolated private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains(normalizeString($0)) }
    }

    nonisolated private static func normalizedSeasonTokens(for rawValue: String) -> [String] {
        let normalized = normalizeString(rawValue)
        let spring = normalizeString(Season.spring.displayName)
        let summer = normalizeString(Season.summer.displayName)
        let fall = normalizeString(Season.fall.displayName)
        let winter = normalizeString(Season.winter.displayName)

        var tokens = Set([normalized])

        if normalized.contains(spring) || normalized.contains("spring") {
            tokens.formUnion([spring, "spring"])
        }
        if normalized.contains(summer) || normalized.contains("summer") {
            tokens.formUnion([summer, "summer"])
        }
        if normalized.contains(fall) || normalized.contains("fall") || normalized.contains("autumn") {
            tokens.formUnion([fall, "fall", "autumn"])
        }
        if normalized.contains(winter) || normalized.contains("winter") {
            tokens.formUnion([winter, "winter"])
        }

        return Array(tokens)
    }

    nonisolated private static func normalizedSortKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
