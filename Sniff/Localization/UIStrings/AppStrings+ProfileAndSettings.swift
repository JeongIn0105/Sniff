//
//  AppStrings+ProfileAndSettings.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Profile {
        static let errorTitle = "오류"
        static let confirm = "확인"
        static let userFallback = "사용자"
        static let missingEmail = "등록된 이메일이 없어요"
        static let countSuffix = "개"

        enum MyPage {
            static let title = "마이페이지"
            static let ownedTitle = "보유 향수"
            static let likedTitle = "LIKE 향수"
            static let emptyOwnedTitle = "등록된 보유 향수가 없어요"
            static let emptyOwnedMessage = "향수 정보 페이지에서 보유 향수를 등록해주세요"
            static let emptyLikedTitle = "등록된 LIKE 향수가 없어요"
            static let emptyLikedMessage = "향수 카드의 하트 아이콘을 눌러 추가해주세요"

            static func count(_ count: Int) -> String {
                "\(count)\(Profile.countSuffix)"
            }
        }

        enum SettingsScreen {
            static let title = "환경설정"
            static let privacyPolicy = "개인정보처리방침"
            static let appVersion = "앱 버전"
            static let currentVersionPrefix = "현재 버전"
            static let logout = "로그아웃"
            static let withdraw = "회원 탈퇴"

            static func currentVersion(_ version: String) -> String {
                "\(currentVersionPrefix) \(version)"
            }
        }

        enum Withdraw {
            static let title = "회원 탈퇴"
            static let appName = AppStrings.AppShell.appName
            static let guide = "탈퇴하기 전 아래의 유의사항을 확인해주세요"
            static let noticeTitle = "계정 탈퇴 유의사항"
            static let noticeBody = "계정 탈퇴 시 서비스에 등록된 개인정보와 서비스 이용 중 작성하신 모든 글이 영구적으로 삭제되며, 다시는 복구할 수 없습니다."
            static let agreement = "계정 탈퇴 유의사항을 확인했습니다."
            static let action = "다음"
            static let confirmTitle = "정말 탈퇴하시겠습니까?"
            static let confirmMessage = "탈퇴 시 모든 데이터가 영구적으로 삭제되며\n복구할 수 없습니다."
            static let confirmDestructive = "탈퇴"
            static let cancel = "취소"

            static func nickname(_ nickname: String) -> String {
                "\(nickname)님"
            }
        }
    }
}
