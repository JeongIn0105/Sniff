//
//  AppStrings+Collection.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Collection {
        static let emptyTitle = "아직 등록된 향수가 없어요"
        static let emptyMessage = "첫 번째 향수를 찾아볼까요?"
        static let addSuccess = "컬렉션에 추가됐어요"
        static let removeConfirm = "컬렉션에서 제거할까요?"
        static let removeButton = "제거할게요"
        static let cancelButton = "아니요, 유지할게요"
    }

    enum CollectionUsageLimits {
        static let monthlyCollectionLimitReached = "이번 달 5개 한도를 채웠어요. 다음 달에 추가할 수 있어요"
        static let dailyLikeLimitReached = "오늘 10개 한도를 채웠어요"
        static let totalLikeLimitReached = "최대 100개까지 저장할 수 있어요"

        static func monthlyUsage(_ count: Int, limit: Int) -> String {
            "이번 달 \(count)/\(limit)"
        }
    }
}
