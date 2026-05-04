//
//  AppStrings+Onboarding.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Onboarding {
        static let experienceTitle = "현재 당신의\n향수 경험을 알려주세요"
        static let vibeTitle = "어떤 분위기를 내고 싶나요?"
        static let vibeSubtitle = "순서대로 선택해주세요"
        static let imageTitle = "어떤 이미지가 떠오르나요?"
        static let imageSubtitle = "순서대로 선택해주세요"
        static let vibeTags: [String] = [
            "세련된", "자연스러운", "신비로운",
            "활기찬", "여유로운", "청순한",
            "섹시한", "차분한", "시크한"
        ]
        static let imageTags: [String] = [
            "따뜻한", "시원한", "상큼한",
            "달콤한", "깨끗한", "부드러운",
            "은은한", "맑은", "짙은"
        ]
        static let next = "다음"
        static let complete = "완료"
        static let analyzing = "취향을 분석하고 있어요..."
        static let loadingTitle = "킁!킁! 취향 분석 중"
        static let loadingResult = "결과를 불러오는 중이에요"
        static let recommendationFamilies = "대표 향 계열"

        enum Experience {
            static let beginner = "향수, 이제 막 시작했어요"
            static let beginnerDesc = "계열이나 노트는 아직 잘 몰라요"
            static let casual = "향수, 가끔 뿌리는 편이에요"
            static let casualDesc = "계열 이름 정도는 들어본 것 같아요"
            static let expert = "향수, 꽤 잘 아는 편이에요"
            static let expertDesc = "노트 구성이나 계열도 구분할 수 있어요"
        }

        enum Result {
            static func title(nickname: String) -> String {
                "\(nickname)님의 취향 분석 완료!"
            }

            static let subtitle = "나만의 향수를 찾아볼게요"
            static let cta = "홈으로 이동"
            static let reanalyze = "재분석"
            static let reanalyzed = "재분석 완료"
            static let footnote = "*보유 향수와 시향기록이 쌓이면 향 계열, 추천 향수, 배경 색상이 함께 업데이트될 수 있습니다."
        }
    }
}
