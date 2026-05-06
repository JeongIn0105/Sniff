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
        static let popularRecommendTitle = "인기 맞춤 추천"
        static let popularRecommendInfoTitle = "인기 맞춤 추천 기준"
        static let popularRecommendInfoMessage = "취향 점수 + 국내 접근성 / 최근 출시 / 인기도를 함께 반영해요."
        static let recommendBasis = "취향 분석 기반 추천이에요"
        static let shortcutPerfume = "향수 등록"
        static let shortcutTasting = "시향기 등록"
        static let shortcutReport = "취향 리포트"
        static let emptyRecommend = "취향 데이터를 조금 더 쌓으면\n추천이 표시돼요"
        static let emptyRecommendLoadFailed = "추천을 불러오지 못했어요\n잠시 후 다시 시도해 주세요"
        static let emptyRecommendOwnedFiltered = "보유 향수와 겹치지 않는 추천을 찾는 중이에요\n취향 데이터가 더 쌓이면 새 추천이 표시돼요"
        static let emptyRecommendPreparing = "취향에 맞는 추천을 고르는 중이에요\n시향기나 보유 향수를 추가하면 더 정확해져요"
        static let fallbackAccords = "• Floral  • Musk"
        static let emptySummary = "취향에 맞는 향수를 골라봤어요"
        static let pendingTitle = "취향 프로필"

        static func familySummary(_ familyText: String) -> String {
            "\(familyText) 계열을 중심으로 추천을 이어가고 있어요"
        }
    }
}
