//
//  LikedPerfume.swift
//  Sniff
//

import Foundation

// MARK: - LIKE 향수 모델
// Firestore 경로: users/{uid}/likes/{docID}

struct LikedPerfume: Identifiable {
    let id: String
    let name: String
    let brand: String
    let scentFamily: String?
    let scentFamily2: String?
    let imageURL: String?
    let mainAccords: [String]
    let likedAt: Date?
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let seasonRanking: [SeasonRankingEntry]
    let concentration: String?
    let longevity: String?
    let sillage: String?

    /// 화면 표시용 향 계열 배열 (nil 제거)
    var scentFamilies: [String] {
        [scentFamily, scentFamily2].compactMap { $0 }.filter { !$0.isEmpty }
    }
}

extension LikedPerfume {
    func toPerfume() -> Perfume {
        Perfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageURL,
            rawMainAccords: mainAccords,
            mainAccords: mainAccords,
            mainAccordStrengths: [:],
            topNotes: topNotes,
            middleNotes: middleNotes,
            baseNotes: baseNotes,
            concentration: concentration,
            gender: nil,
            season: nil,
            seasonRanking: seasonRanking,
            situation: nil,
            longevity: longevity,
            sillage: sillage
        )
    }
}
