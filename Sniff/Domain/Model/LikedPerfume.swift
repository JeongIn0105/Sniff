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
    let likedAt: Date?

    /// 화면 표시용 향 계열 배열 (nil 제거)
    var scentFamilies: [String] {
        [scentFamily, scentFamily2].compactMap { $0 }.filter { !$0.isEmpty }
    }
}
