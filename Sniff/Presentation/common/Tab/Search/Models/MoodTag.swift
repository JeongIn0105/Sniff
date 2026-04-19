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
    case floral = "플로럴"
    case woody = "우디"
    case fresh = "프레시"
    case amber = "앰버"
    case spicy = "스파이시"
    case musky = "머스키"
    case whiteFloral = "화이트 플로럴"
    case rose = "로즈"
    case powdery = "파우더리"
    case vanilla = "바닐라"
    case caramel = "카라멜"

    var displayName: String { rawValue }

    var matchingRawAccords: [String] {
        switch self {
        case .floral:
            return ["floral", "yellow floral"]
        case .woody:
            return ["woody", "cedar", "sandalwood", "oud", "dry woods", "mossy woods", "woody amber"]
        case .fresh:
            return ["fresh", "citrus", "water", "aquatic", "marine", "green"]
        case .amber:
            return ["amber", "woody amber", "balsamic"]
        case .spicy:
            return ["spicy", "warm spicy", "fresh spicy", "aromatic"]
        case .musky:
            return ["musk", "musky", "white musk"]
        case .whiteFloral:
            return ["white floral"]
        case .rose:
            return ["rose"]
        case .powdery:
            return ["powdery", "soft floral", "soapy", "clean"]
        case .vanilla:
            return ["vanilla", "gourmand"]
        case .caramel:
            return ["caramel"]
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

    var displayName: String { rawValue }

        // Fragella API 값 매핑
    var fragellaValues: [String] {
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
    case allSeason = "사계절"

    var displayName: String { rawValue }

    var fragellaValue: String? {
        switch self {
            case .spring:    return "spring"
            case .summer:    return "summer"
            case .fall:      return "fall"
            case .winter:    return "winter"
            case .allSeason: return nil // 특정 계절 없음 → 전체
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
        return remaining > 0 ? "\(first) 외 \(remaining)개" : first
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
    case nameAsc     = "이름 순 (ㄱ~ㅎ)"
    case nameDesc    = "이름 역순 (ㅎ~ㄱ)"

    var displayName: String { rawValue }
}
