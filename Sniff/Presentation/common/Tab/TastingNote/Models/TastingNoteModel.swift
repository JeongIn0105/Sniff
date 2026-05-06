//
//  TastingNoteModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 데이터 모델
import Foundation
import SwiftUI

// MARK: - 시향 기록 모델

enum TastingUsageContext: String, CaseIterable, Codable {
    case today = "오늘 사용"
    case recent = "최근 사용"
    case memory = "기억으로 기록"

    nonisolated var displayName: String { rawValue }
}

enum TastingLongevityExperience: String, CaseIterable, Codable {
    case underTwoHours = "2h 이하"
    case twoToFourHours = "2~4h"
    case fourToSixHours = "4~6h"
    case overSixHours = "6h+"

    nonisolated var displayName: String { rawValue }
}

enum TastingSillageExperience: String, CaseIterable, Codable {
    case skinClose = "나만 맡음"
    case oneMeter = "주변 1m"
    case roomFilling = "방 전체"

    nonisolated var displayName: String { rawValue }
}

enum TastingDrydownChange: String, CaseIterable, Codable {
    case subtle = "거의 비슷함"
    case moderate = "조금 달라짐"
    case dramatic = "완전히 달라짐"

    nonisolated var displayName: String { rawValue }
}

enum TastingSkinChemistry: String, CaseIterable, Codable {
    case blooms = "더 살아남"
    case neutral = "그대로"
    case fades = "죽는 편"

    nonisolated var displayName: String { rawValue }
}

enum TastingWearSituation: String, CaseIterable, Codable {
    case daily = "데일리"
    case date = "데이트"
    case work = "출근"
    case special = "특별한 날"

    nonisolated var displayName: String { rawValue }
}

enum TastingWeatherContext: String, CaseIterable, Codable {
    case hotHumid = "덥고 습한 날"
    case dryWinter = "건조한 겨울"
    case mild = "선선한 날"
    case rainy = "비 오는 날"

    nonisolated var displayName: String { rawValue }
}

enum TastingApplicationArea: String, CaseIterable, Codable {
    case wrist = "손목"
    case neck = "목"
    case clothes = "옷"
    case hair = "머리카락"

    nonisolated var displayName: String { rawValue }
}

struct TastingNote: Identifiable, Codable {
    var id: String?
    var perfumeName: String
    var brandName: String
    var mainAccords: [String]
    var concentration: String?
    var rating: Int
    var moodTags: [String]
    var revisitDesire: String?   // 다시 쓰고 싶은지 태그 (선택)
    var memo: String
    var perfumeImageURL: String?
    var usageContext: String?
    var longevityExperience: String?
    var sillageExperience: String?
    var drydownChange: String?
    var skinChemistry: String?
    var wearSituations: [String]
    var weatherContexts: [String]
    var applicationAreas: [String]
    var createdAt: Date
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case perfumeName
        case brandName
        case mainAccords
        case concentration
        case rating
        case moodTags
        case revisitDesire
        case memo
        case perfumeImageURL
        case imageUrl
        case usageContext
        case longevityExperience
        case sillageExperience
        case drydownChange
        case skinChemistry
        case wearSituations
        case weatherContexts
        case applicationAreas
        case createdAt
        case updatedAt
    }

    init(
        id: String? = nil,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        concentration: String?,
        rating: Int,
        moodTags: [String],
        revisitDesire: String?,
        memo: String,
        perfumeImageURL: String?,
        usageContext: String? = nil,
        longevityExperience: String? = nil,
        sillageExperience: String? = nil,
        drydownChange: String? = nil,
        skinChemistry: String? = nil,
        wearSituations: [String] = [],
        weatherContexts: [String] = [],
        applicationAreas: [String] = [],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.perfumeName = perfumeName
        self.brandName = brandName
        self.mainAccords = mainAccords
        self.concentration = concentration
        self.rating = rating
        self.moodTags = moodTags
        self.revisitDesire = revisitDesire
        self.memo = memo
        self.perfumeImageURL = perfumeImageURL
        self.usageContext = usageContext
        self.longevityExperience = longevityExperience
        self.sillageExperience = sillageExperience
        self.drydownChange = drydownChange
        self.skinChemistry = skinChemistry
        self.wearSituations = wearSituations
        self.weatherContexts = weatherContexts
        self.applicationAreas = applicationAreas
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        perfumeName = try container.decode(String.self, forKey: .perfumeName)
        brandName = try container.decode(String.self, forKey: .brandName)
        mainAccords = try container.decodeIfPresent([String].self, forKey: .mainAccords) ?? []
        concentration = try container.decodeIfPresent(String.self, forKey: .concentration)
        rating = try container.decode(Int.self, forKey: .rating)
        moodTags = try container.decodeIfPresent([String].self, forKey: .moodTags) ?? []
        revisitDesire = try container.decodeIfPresent(String.self, forKey: .revisitDesire)
        memo = try container.decodeIfPresent(String.self, forKey: .memo) ?? ""
        perfumeImageURL =
            try container.decodeIfPresent(String.self, forKey: .perfumeImageURL)
            ?? container.decodeIfPresent(String.self, forKey: .imageUrl)
        usageContext = try container.decodeIfPresent(String.self, forKey: .usageContext)
        longevityExperience = try container.decodeIfPresent(String.self, forKey: .longevityExperience)
        sillageExperience = try container.decodeIfPresent(String.self, forKey: .sillageExperience)
        drydownChange = try container.decodeIfPresent(String.self, forKey: .drydownChange)
        skinChemistry = try container.decodeIfPresent(String.self, forKey: .skinChemistry)
        wearSituations = try container.decodeIfPresent([String].self, forKey: .wearSituations) ?? []
        weatherContexts = try container.decodeIfPresent([String].self, forKey: .weatherContexts) ?? []
        applicationAreas = try container.decodeIfPresent([String].self, forKey: .applicationAreas) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Firestore 문서 ID는 LocalTastingNoteRepository에서 직접 관리하므로 문서 데이터에는 포함하지 않습니다.
        // Firestore 보안 규칙의 hasOnly 검증 통과를 위해 id 필드를 제외합니다.
        try container.encode(perfumeName, forKey: .perfumeName)
        try container.encode(brandName, forKey: .brandName)
        try container.encode(mainAccords, forKey: .mainAccords)
        try container.encodeIfPresent(concentration, forKey: .concentration)
        try container.encode(rating, forKey: .rating)
        try container.encode(moodTags, forKey: .moodTags)
        try container.encodeIfPresent(revisitDesire, forKey: .revisitDesire)
        try container.encode(memo, forKey: .memo)
        try container.encodeIfPresent(perfumeImageURL, forKey: .perfumeImageURL)
        try container.encodeIfPresent(usageContext, forKey: .usageContext)
        try container.encodeIfPresent(longevityExperience, forKey: .longevityExperience)
        try container.encodeIfPresent(sillageExperience, forKey: .sillageExperience)
        try container.encodeIfPresent(drydownChange, forKey: .drydownChange)
        try container.encodeIfPresent(skinChemistry, forKey: .skinChemistry)
        if !wearSituations.isEmpty {
            try container.encode(wearSituations, forKey: .wearSituations)
        }
        if !weatherContexts.isEmpty {
            try container.encode(weatherContexts, forKey: .weatherContexts)
        }
        if !applicationAreas.isEmpty {
            try container.encode(applicationAreas, forKey: .applicationAreas)
        }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - 다시 쓰고 싶은지 태그 목록 (4개, 단일 선택)

let kRevisitDesireList: [String] = [
    AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[0],
    AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[1],
    AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[2],
    AppStrings.DomainDisplay.TastingNoteData.revisitDesireList[3]
]

// MARK: - Fragella 향수 검색 결과 모델

struct FragellaFragrance: Identifiable {
    let id: String
    let name: String            // 영문명 (원본)
    let brand: String           // 영문 브랜드명 (원본)
    let koreanName: String?     // 한국어 향수명
    let koreanBrand: String?    // 한국어 브랜드명
    let mainAccords: [String]   // 한국어로 변환된 향 계열
    let concentration: String?
    let imageURL: String?

    /// 화면 표시용 향수명 — 한국어 있으면 한국어 우선
    var displayName: String { koreanName ?? name }

    /// 화면 표시용 브랜드명 — 한국어 있으면 한국어 우선, 없으면 번역 시도
    var displayBrand: String {
        if let k = koreanBrand { return k }
        return PerfumeKoreanTranslator.koreanBrand(for: brand)
    }
}

// MARK: - 분위기&이미지 태그 목록

let kMoodTagList: [String] = AppStrings.DomainDisplay.TastingNoteData.moodTagList

// MARK: - 향 계열(Accord) 색상

extension String {

    var accordColor: Color {
        Color(uiColor: ScentFamilyColor.color(for: self))
    }
    var accordBackgroundColor: Color { accordColor.opacity(0.12) }
    var accordBorderColor: Color { accordColor.opacity(0.45) }
}

// MARK: - 이전 무드 태그 → 현재 무드 태그 매핑

let kLegacyMoodTagToKorean: [String: String] = [
    "Woody": "짙은",
    "Fresh": "상큼한",
    "Amber(Oriental)": "따뜻한",
    "Musky": "부드러운",
    "White Floral": "은은한",
    "Rose": "은은한",
    "Powdery": "부드러운",
    "Vanilla": "달콤한",
    "Sweet": "달콤한",
    "Spicy": "짙은",
    "Citrus": "상큼한",
    "Green": "자연스러운",
    "Aquatic": "시원한",
    "Water": "시원한",
    "Leather": "짙은",
    "Oud": "짙은",
    "우디": "짙은",
    "앰버(오리엔탈)": "따뜻한",
    "바닐라": "달콤한",
    "시트러스": "상큼한",
    "그린": "자연스러운",
    "아쿠아틱": "시원한",
    "워터": "시원한",
    "워터리": "시원한",
    "강렬한": "짙은",
    "보송보송한": "부드러운",
    "묵직한": "짙은",
    "가벼운": "맑은",
    "포근한": "따뜻한",
    "고급스러운": "세련된",
    "중성적인": "시크한",
    "싱그러운": "자연스러운",
    "무거운": "짙은",
]

// MARK: - 별점 라벨

extension Int {
    var ratingLabel: String {
        AppStrings.DomainDisplay.TastingNoteData.ratingLabel(self)
    }
}

// MARK: - 날짜 포맷

extension Date {
    var tastingNoteFormat: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy. MM. dd"
        return f.string(from: self)
    }
}
