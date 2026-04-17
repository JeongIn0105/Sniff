//
//  TastingRecord.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//



import Foundation

struct TastingRecord {
    let id: String
    let perfumeName: String
    let brandName: String
    let mainAccords: [String]
    let accordStrengths: [String: AccordStrength]
    let rating: Int
    let moodTags: [String]
let memo: String?
    /// 재사용 의향 태그
    /// "매일 뿌리고 싶어" / "가끔 꺼내고 싶어" / "기억에 남아, 근데 내 향은 아니야" / "다시 맡고 싶지 않아"
    let wantToRevisit: String?
    let revisitDesire: String?
    /// 최초 시향 날짜 — recencyMultiplier 계산 기준으로 사용
    let createdAt: Date
    let updatedAt: Date
}

extension TastingRecord {
    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        rating: Int,
        moodTags: [String],
        updatedAt: Date
    ) {
        self.init(
            id: id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            accordStrengths: [:],
            rating: rating,
            moodTags: moodTags,
            memo: nil,
            wantToRevisit: nil,
            updatedAt: updatedAt
        )
    }
}

    // 재사용 의향 태그 상수 — UI에서 이 배열로 버튼 생성
extension TastingRecord {
    static let revisitOptions: [String] = [
        "매일 뿌리고 싶어",
        "가끔 꺼내고 싶어",
        "기억에 남아, 근데 내 향은 아니야",
        "다시 맡고 싶지 않아"
    ]
}
