//
//  AppStrings+ViewModelMessages.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum ViewModelMessages {
        enum Onboarding {
            static let nicknameChecking = "중복 여부를 확인하고 있어요..."
            static let missingExperience = "향수 경험을 먼저 선택해주세요."
            static let beginnerExperience = "향수를 처음 시작했어요"
            static let casualExperience = "향수를 가끔씩 뿌려요"
            static let expertExperience = "향수를 꽤 알고 있어요"
        }

        enum Settings {
            static let userFallback = "사용자"
        }

        enum Withdraw {
            static let requiresRecentLogin = "보안을 위해 로그아웃 후 다시 로그인한 뒤 탈퇴를 진행해주세요."
            static let failed = "탈퇴 처리 중 오류가 발생했어요. 다시 시도해주세요."
        }

        enum TastingNote {
            static let deleteFailed = "삭제 중 오류가 발생했어요"

            static func saved(_ perfumeName: String) -> String {
                "\(perfumeName) 시향기가 등록되었습니다"
            }

            static func deletedOwnedCount(_ count: Int) -> String {
                "\(count)개의 보유 향수가 삭제되었습니다"
            }
        }

        enum TastingNoteForm {
            static let minimumSearchLength = "2자 이상 입력해주세요"
            static let saveFailed = "저장 중 오류가 발생했어요"
            static let missingAPIKey = "Fragella API 키를 먼저 설정해주세요"
            static let invalidURL = "요청 URL 생성에 실패했어요"
            static let invalidResponse = "응답을 확인할 수 없어요"
            static let decodingFailed = "응답 해석에 실패했어요"
            static let unknownError = "알 수 없는 오류"

            static func serverError(_ code: Int, _ message: String) -> String {
                "검색 실패 (\(code))\n\(message)"
            }
        }
    }
}
