//
//  AppStrings+AppShell.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum AppShell {
        static let appName = "킁킁"

        enum Splash {
            static let title = AppShell.appName
        }

        enum Login {
            static let title = AppShell.appName
            static let subtitle = "나만의 향수 취향을 찾아보세요"
            static let appleButton = "Apple로 로그인"
            static let defaultError = "로그인에 실패했습니다."
            static let invalidCredential = "인증 정보를 처리할 수 없습니다."
        }

        enum MainTab {
            static let home = "홈"
            static let search = "검색"
            static let tastingNote = "시향기"
            static let my = "MY"

            static func placeholder(_ title: String) -> String {
                "\(title) 화면 준비 중"
            }
        }

        enum Intro {
            static let title = "당신의 향수 취향을\n킁킁과 함께 발견해가요"
            static let subtitle = "보유하고 있는 향수, 관심있는 향수를 등록하고\n나만의 향수를 추천받아 보세요"
            static let start = "킁킁 시작하기"
        }
    }
}
