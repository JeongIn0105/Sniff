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
    let rating: Int
    let moodTags: [String]
    let revisitDesire: String?   // 다시 쓰고 싶은지 태그 (선택)
    /// 최초 시향 날짜 — recencyMultiplier 계산 기준으로 사용
    let createdAt: Date
    let updatedAt: Date
}
