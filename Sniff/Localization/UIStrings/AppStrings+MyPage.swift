//
//  AppStrings+MyPage.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum MyPage {
        static let collectionTitle = "내 향수 컬렉션"
        static let collectionMore = "전체 보기"
        static let tasteCardTitle = "나의 취향 프로필"

        enum TasteCard {
            static let step0Title = "아직 취향 분석이 없어요"
            static let step0Cta = "취향 분석 시작하기"

            static func step2Message(count: Int) -> String {
                "향수를 \(count)개 기록했어요! 더 많이 기록할수록 취향이 더 정확해져요"
            }

            static func step3Update(nickname: String) -> String {
                "\(nickname)님의 취향이 더 선명해졌어요"
            }
        }
    }
}
