//
//  MoodTag.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    // MoodTag.swift
    // 킁킁(Sniff) - 무드&이미지 태그 + 필터 모델

import Foundation

// MARK: - MoodTag

typealias MoodTag = PreferenceTag

enum ScentFamilyFilter: String, CaseIterable, Codable {
    case citrus = "Citrus"
    case fruity = "Fruity"
    case green = "Green"
    case water = "Water"
    case aromatic = "Aromatic"
    case floral = "Floral"
    case softFloral = "Soft Floral"
    case floralAmber = "Floral Amber"
    case softAmber = "Soft Amber"
    case amber = "Amber"
    case woods = "Woods"
    case woodyAmber = "Woody Amber"
    case mossyWoods = "Mossy Woods"
    case dryWoods = "Dry Woods"

    nonisolated var displayName: String { rawValue }

    nonisolated var descriptionText: String {
        switch self {
        case .citrus:
            return AppStrings.DomainDisplay.SearchFilters.citrusDescription
        case .fruity:
            return AppStrings.DomainDisplay.SearchFilters.fruityDescription
        case .green:
            return AppStrings.DomainDisplay.SearchFilters.greenDescription
        case .water:
            return AppStrings.DomainDisplay.SearchFilters.waterDescription
        case .aromatic:
            return AppStrings.DomainDisplay.SearchFilters.aromaticDescription
        case .floral:
            return AppStrings.DomainDisplay.SearchFilters.floralDescription
        case .softFloral:
            return AppStrings.DomainDisplay.SearchFilters.softFloralDescription
        case .floralAmber:
            return AppStrings.DomainDisplay.SearchFilters.floralAmberDescription
        case .softAmber:
            return AppStrings.DomainDisplay.SearchFilters.softAmberDescription
        case .amber:
            return AppStrings.DomainDisplay.SearchFilters.amberDescription
        case .woods:
            return AppStrings.DomainDisplay.SearchFilters.woodsDescription
        case .woodyAmber:
            return AppStrings.DomainDisplay.SearchFilters.woodyAmberDescription
        case .mossyWoods:
            return AppStrings.DomainDisplay.SearchFilters.mossyWoodsDescription
        case .dryWoods:
            return AppStrings.DomainDisplay.SearchFilters.dryWoodsDescription
        }
    }

    static let freshFamilies: [ScentFamilyFilter] = [
        .citrus, .fruity, .green, .water, .aromatic
    ]

    static let softFamilies: [ScentFamilyFilter] = [
        .floral, .softFloral, .floralAmber
    ]

    static let deepFamilies: [ScentFamilyFilter] = [
        .softAmber, .amber, .woodyAmber, .woods, .mossyWoods, .dryWoods
    ]

    nonisolated var matchingRawAccords: [String] {
        switch self {
        case .citrus:
            return ["citrus", "bergamot", "lemon", "orange", "grapefruit", "mandarin"]

        case .fruity:
            return ["fruity", "sweet fruity", "berry", "peach", "apple", "pear", "tropical fruits"]

        case .green:
            return ["green", "fresh green", "leafy", "herbal", "vegetal"]

        case .water:
            return ["aquatic", "marine", "water", "watery", "oceanic"]

        case .aromatic:
            return ["aromatic", "fresh spicy", "lavender", "herbal", "tea"]

        case .floral:
            return ["floral", "white floral", "yellow floral", "rose"]

        case .softFloral:
            return ["soft floral", "powdery", "soapy", "clean", "iris", "violet", "musk", "white musk"]

        case .floralAmber:
            return ["floral amber", "oriental floral", "ylang ylang", "tuberose", "jasmine"]

        case .softAmber:
            return ["soft amber", "soft oriental", "vanilla", "balsamic", "gourmand"]

        case .amber:
            return ["amber", "oriental", "warm spicy", "resinous"]

        case .woods:
            return ["woody", "wood", "cedar", "sandalwood", "oud", "vetiver"]

        case .woodyAmber:
            return ["woody amber"]

        case .mossyWoods:
            return ["mossy woods", "earthy", "patchouli"]

        case .dryWoods:
            return ["dry woods", "dry wood", "leather", "smoky"]
        }
    }
}


    // MARK: - Concentration

enum Concentration: String, CaseIterable, Codable {
    case parfum    = "퍼퓸"
    case edp       = "오드퍼퓸(EDP)"
    case edt       = "오드뚜왈렛(EDT)"
    case edc       = "오드콜로뉴(EDC)"
    case eauFraiche = "오프레시"

    nonisolated var displayName: String {
        switch self {
        case .parfum:
            return AppStrings.DomainDisplay.SearchFilters.parfum
        case .edp:
            return AppStrings.DomainDisplay.SearchFilters.eauDeParfum
        case .edt:
            return AppStrings.DomainDisplay.SearchFilters.eauDeToilette
        case .edc:
            return AppStrings.DomainDisplay.SearchFilters.eauDeCologne
        case .eauFraiche:
            return AppStrings.DomainDisplay.SearchFilters.eauFraiche
        }
    }

        // Fragella API 값 매핑
    nonisolated var fragellaValues: [String] {
        switch self {
            case .parfum:      return ["parfum", "extrait de parfum", "pure perfume"]
            case .edp:         return ["eau de parfum", "edp"]
            case .edt:         return ["eau de toilette", "edt"]
            case .edc:         return ["eau de cologne", "edc"]
            case .eauFraiche:  return ["eau fraiche", "eau fraîche"]
        }
    }
}

    // MARK: - Season

enum Season: String, CaseIterable, Codable {
    case spring    = "봄"
    case summer    = "여름"
    case fall      = "가을"
    case winter    = "겨울"

    nonisolated var displayName: String {
        switch self {
        case .spring:
            return AppStrings.DomainDisplay.SearchFilters.spring
        case .summer:
            return AppStrings.DomainDisplay.SearchFilters.summer
        case .fall:
            return AppStrings.DomainDisplay.SearchFilters.fall
        case .winter:
            return AppStrings.DomainDisplay.SearchFilters.winter
        }
    }

    nonisolated var fragellaValue: String? {
        switch self {
            case .spring:    return "spring"
            case .summer:    return "summer"
            case .fall:      return "fall"
            case .winter:    return "winter"
        }
    }
}

    // MARK: - SearchFilter (전체 필터 상태)

struct SearchFilter: Equatable {
    var scentFamilies: Set<ScentFamilyFilter> = []
    var moodTags: Set<MoodTag> = []
    var concentrations: Set<Concentration> = []
    var seasons: Set<Season> = []

    var isEmpty: Bool {
        scentFamilies.isEmpty && moodTags.isEmpty && concentrations.isEmpty && seasons.isEmpty
    }

    var totalCount: Int {
        scentFamilies.count + moodTags.count + concentrations.count + seasons.count
    }

        // 필터 버튼 레이블 ("플로럴 외 4개" 형식)
    var summaryLabel: String? {
        guard totalCount > 0 else { return nil }
        let first = scentFamilies.first?.displayName
        ?? moodTags.first?.displayName
        ?? concentrations.first?.displayName
        ?? seasons.first?.displayName
        ?? ""
        let remaining = totalCount - 1
        return remaining > 0 ? AppStrings.DomainDisplay.SearchFilters.summaryLabel(first, remaining) : first
    }

    mutating func reset() {
        scentFamilies = []
        moodTags = []
        concentrations = []
        seasons = []
    }
}

    // MARK: - SortOption

enum SortOption: String, CaseIterable {
    case recommended = "추천순"
    case nameAsc     = "이름순 (A-Z)"
    case nameDesc    = "이름역순 (Z-A)"

    var displayName: String {
        switch self {
        case .recommended:
            return AppStrings.DomainDisplay.SearchFilters.sortRecommended
        case .nameAsc:
            return AppStrings.DomainDisplay.SearchFilters.sortNameAsc
        case .nameDesc:
            return AppStrings.DomainDisplay.SearchFilters.sortNameDesc
        }
    }
}
