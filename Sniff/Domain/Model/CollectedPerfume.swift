//
//  CollectedPerfume.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//


import Foundation

struct CollectedPerfume {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let accordStrengths: [String: AccordStrength]
    /// 보유 향수 메모 — 취득 맥락, 보관 정보 등 자유 텍스트
    /// 시향기의 memo(감각적 기록)와 성격이 다름
    let memo: String?
    let createdAt: Date?

    /// 화면 표시용 향 계열 배열 (nil 제거)
    var scentFamilies: [String] {
        [scentFamily, scentFamily2].compactMap { $0 }.filter { !$0.isEmpty }
    }
}

extension CollectedPerfume {
    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            mainAccords: mainAccords,
            accordStrengths: [:],
            memo: nil,
            createdAt: createdAt
        )
    }

        // accordStrengths는 있지만 memo 없는 경우용
    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String? = nil,
        mainAccords: [String],
        accordStrengths: [String: AccordStrength],
        createdAt: Date?
    ) {
        self.init(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths,
            memo: nil,
            createdAt: createdAt
        )
    }
}

    // 보유 향수 → Perfume 변환 헬퍼
    // 보유 향수에서 시향 기록 남길 때 Fragella API 재호출 없이 사용
extension CollectedPerfume {
    func toPerfume() -> Perfume {
        Perfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            rawMainAccords: mainAccords,
            mainAccords: mainAccords,
            mainAccordStrengths: accordStrengths,
            topNotes: nil,
            middleNotes: nil,
            baseNotes: nil,
            concentration: nil,
            gender: nil,
            season: nil,
            situation: nil,
            longevity: nil,
            sillage: nil
        )
    }
}
