//
//  AppStrings+Home.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Home {
        static let tasteProfileTitle = "취향 프로필"
        static func greeting(nickname: String) -> String {
            "\(nickname)님의 취향에 맞는\n향수를 찾아왔어요"
        }

        static let recommendTitle = "취향 맞춤 향수"
        static let popularRecommendTitle = "국내에서 찾기 쉬운 취향 향수"
        static let recommendBasis = "취향 분석 기반 추천이에요"
        static let shortcutPerfume = "향수 등록"
        static let shortcutTasting = "시향기 등록"
        static let shortcutReport = "취향 리포트"
        static let emptyRecommend = "취향 분석을 완료하면\n맞춤 향수를 추천해드려요"
        static let fallbackAccords = "• Floral  • Musk"
        static let emptySummary = "취향에 맞는 향수를 골라봤어요"
        static let pendingTitle = "취향 프로필"

        static func familySummary(_ familyText: String) -> String {
            "\(familyText) 계열을 중심으로 추천을 이어가고 있어요"
        }
    }
}
