//
//  TastingNoteModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 데이터 모델
import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - 시향 기록 모델

struct TastingNote: Identifiable, Codable {
    @DocumentID var id: String?
    var perfumeName: String
    var brandName: String
    var mainAccords: [String]
    var concentration: String?
    var rating: Int
    var moodTags: [String]
    var revisitDesire: String?   // 다시 쓰고 싶은지 태그 (선택)
    var memo: String
    var perfumeImageURL: String?
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
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(perfumeName, forKey: .perfumeName)
        try container.encode(brandName, forKey: .brandName)
        try container.encode(mainAccords, forKey: .mainAccords)
        try container.encodeIfPresent(concentration, forKey: .concentration)
        try container.encode(rating, forKey: .rating)
        try container.encode(moodTags, forKey: .moodTags)
        try container.encodeIfPresent(revisitDesire, forKey: .revisitDesire)
        try container.encode(memo, forKey: .memo)
        try container.encodeIfPresent(perfumeImageURL, forKey: .perfumeImageURL)
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

// MARK: - 분위기&이미지 태그 목록 (18개)

let kMoodTagList: [String] = [
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[0],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[1],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[2],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[3],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[4],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[5],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[6],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[7],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[8],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[9],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[10],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[11],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[12],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[13],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[14],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[15],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[16],
    AppStrings.DomainDisplay.TastingNoteData.moodTagList[17]
]

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
    "Woody": "묵직한",
    "Fresh": "상큼한",
    "Amber(Oriental)": "따뜻한",
    "Musky": "보송보송한",
    "White Floral": "은은한",
    "Rose": "은은한",
    "Powdery": "보송보송한",
    "Vanilla": "달콤한",
    "Sweet": "달콤한",
    "Spicy": "강렬한",
    "Citrus": "상큼한",
    "Green": "자연스러운",
    "Aquatic": "시원한",
    "Water": "시원한",
    "Leather": "묵직한",
    "Oud": "묵직한",
    "우디": "묵직한",
    "앰버(오리엔탈)": "따뜻한",
    "바닐라": "달콤한",
    "시트러스": "상큼한",
    "그린": "자연스러운",
    "아쿠아틱": "시원한",
    "워터": "시원한",
    "워터리": "시원한",
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
