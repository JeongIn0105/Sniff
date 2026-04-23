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

    var displayName: String { rawValue }

    var descriptionText: String {
        switch self {
        case .citrus:
            return "레몬과 베르가못처럼 상큼하고 밝은 계열"
        case .fruity:
            return "과즙감 있고 달콤한 생기가 느껴지는 계열"
        case .green:
            return "풀잎과 허브처럼 싱그럽고 내추럴한 계열"
        case .water:
            return "물기 어린 시원함과 맑은 공기가 느껴지는 계열"
        case .aromatic:
            return "허브와 잎사귀처럼 산뜻하고 깔끔한 계열"
        case .floral:
            return "꽃향 중심의 화사하고 우아한 계열"
        case .softFloral:
            return "보송하고 부드러운 꽃향이 감도는 계열"
        case .floralAmber:
            return "꽃향에 따뜻한 앰버 기운이 더해진 계열"
        case .softAmber:
            return "부드럽고 달콤하게 감도는 앰버 계열"
        case .amber:
            return "따뜻하고 묵직한 잔향이 느껴지는 계열"
        case .woods:
            return "나무결처럼 차분하고 자연스러운 우디 계열"
        case .woodyAmber:
            return "우디와 앰버가 겹쳐 따뜻하고 고급스러운 계열"
        case .mossyWoods:
            return "이끼와 흙내음이 감도는 깊고 차분한 우디 계열"
        case .dryWoods:
            return "건조하고 또렷한 나무 향이 중심인 우디 계열"
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

    var matchingRawAccords: [String] {
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
