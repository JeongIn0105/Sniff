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
    case citrus = "시트러스"
    case fruity = "프루티"
    case green = "그린"
    case aquatic = "아쿠아틱"
    case aromatic = "아로마틱"
    case floral = "플로럴"
    case whiteFloral = "화이트 플로럴"
    case rose = "로즈"
    case powdery = "파우더리"
    case musky = "머스키"
    case woody = "우디"
    case amber = "앰버"
    case spicy = "스파이시"
    case vanilla = "바닐라"
    case gourmand = "구르망"
    case leather = "레더"

    var displayName: String { rawValue }

    var descriptionText: String {
        switch self {
        case .citrus:
            return "상큼하고 밝은 첫인상이 강한 계열"
        case .fruity:
            return "달콤하고 과즙감 있는 생기 있는 계열"
        case .green:
            return "풀잎처럼 싱그럽고 내추럴한 계열"
        case .aquatic:
            return "물기 어린 시원함과 맑은 공기가 느껴지는 계열"
        case .aromatic:
            return "허브와 잎사귀처럼 산뜻하고 깔끔한 계열"
        case .floral:
            return "꽃향 중심의 부드럽고 화사한 계열"
        case .whiteFloral:
            return "풍성하고 크리미한 꽃향이 도드라지는 계열"
        case .rose:
            return "장미 특유의 우아하고 로맨틱한 계열"
        case .powdery:
            return "보송하고 포근하게 감싸는 잔향의 계열"
        case .musky:
            return "살냄새처럼 부드럽고 은은하게 남는 계열"
        case .woody:
            return "나무결처럼 차분하고 깊이감 있는 계열"
        case .amber:
            return "따뜻하고 묵직한 잔향이 느껴지는 계열"
        case .spicy:
            return "향신료처럼 또렷하고 존재감 있는 계열"
        case .vanilla:
            return "달콤하고 크리미하게 감도는 계열"
        case .gourmand:
            return "디저트처럼 먹음직스럽고 진한 단향 계열"
        case .leather:
            return "가죽 특유의 드라이하고 시크한 계열"
        }
    }

    static let freshFamilies: [ScentFamilyFilter] = [
        .citrus, .fruity, .green, .aquatic, .aromatic
    ]

    static let softFamilies: [ScentFamilyFilter] = [
        .floral, .whiteFloral, .rose, .powdery, .musky
    ]

    static let deepFamilies: [ScentFamilyFilter] = [
        .woody, .amber, .spicy, .vanilla, .gourmand, .leather
    ]

    var matchingRawAccords: [String] {
        switch self {
        case .citrus:
            return ["citrus", "bergamot", "lemon", "orange", "grapefruit", "mandarin"]

        case .fruity:
            return ["fruity", "sweet fruity", "berry", "peach", "apple", "pear", "tropical fruits"]

        case .green:
            return ["green", "fresh green", "leafy", "herbal", "vegetal"]

        case .aquatic:
            return ["aquatic", "marine", "water", "watery", "oceanic"]

        case .aromatic:
            return ["aromatic", "fresh spicy", "lavender", "herbal", "tea"]

        case .floral:
            return ["floral", "yellow floral", "soft floral"]

        case .whiteFloral:
            return ["white floral", "tuberose", "jasmine", "orange blossom", "gardenia"]

        case .rose:
            return ["rose", "rosy"]

        case .powdery:
            return ["powdery", "soapy", "clean", "iris", "violet"]

        case .musky:
            return ["musk", "musky", "white musk", "soft musk", "clean musk"]

        case .woody:
            return ["woody", "cedar", "sandalwood", "dry woods", "mossy woods", "vetiver"]

        case .amber:
            return ["amber", "woody amber", "balsamic", "resinous"]

        case .spicy:
            return ["spicy", "warm spicy", "soft spicy", "fresh spicy"]

        case .vanilla:
            return ["vanilla", "vanilla powder"]

        case .gourmand:
            return ["gourmand", "caramel", "chocolate", "honey", "sweet", "dessert"]

        case .leather:
            return ["leather", "suede", "animalic"]
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

    var displayName: String { rawValue }

    var fragellaValue: String? {
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
    case nameAsc     = "이름순 (A-Z)"
    case nameDesc    = "이름역순 (Z-A)"

    var displayName: String { rawValue }
}
