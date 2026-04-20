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
    /// 재사용 의향 태그 (V1 필드명 — 구 호환 유지)
    let wantToRevisit: String?
    /// 재사용 의향 태그 (V2 feature/tasting-note 필드명)
    let revisitDesire: String?
    /// 최초 시향 날짜 — recencyMultiplier 계산 기준
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - 편의 생성자 (다양한 호출 패턴 대응)
extension TastingRecord {

    /// VectorParsing (makeTastingRecordV2) 용: accordStrengths + memo + wantToRevisit (createdAt/revisitDesire 없음)
    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        rating: Int,
        moodTags: [String],
        memo: String?,
        wantToRevisit: String?,
        updatedAt: Date
    ) {
        self.init(
            id: id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            rating: rating,
            moodTags: moodTags,
            memo: memo,
            wantToRevisit: wantToRevisit,
            revisitDesire: wantToRevisit,   // 두 필드 동기화
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    /// 구 FirestoreService.makeTastingRecord 용: revisitDesire + createdAt (accordStrengths/memo 없음)
    init(
        id: String,
        perfumeName: String,
        brandName: String,
        mainAccords: [String],
        rating: Int,
        moodTags: [String],
        revisitDesire: String?,
        createdAt: Date,
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
            wantToRevisit: revisitDesire,
            revisitDesire: revisitDesire,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 최소 생성자 (accordStrengths/memo/revisitDesire 없음)
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

// MARK: - 재사용 의향 태그 상수
extension TastingRecord {
    static let revisitOptions: [String] = [
        "매일 뿌리고 싶어",
        "가끔 꺼내고 싶어",
        "기억에 남아, 근데 내 향은 아니야",
        "다시 맡고 싶지 않아"
    ]
}
