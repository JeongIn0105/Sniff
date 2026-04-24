//
//  AppStrings+TastingNote.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum TastingNote {
        static let emptyList = "아직 기록이 없어요. 오늘 맡은 향수를 기록해보세요"
        static let searchPlaceholder = "향수명을 입력해주세요"
        static let contentPlaceholder = "향수를 맡은 느낌을 자유롭게 기록해보세요"
        static let saveButton = "기록 저장하기"
        static let cancelButton = "나중에 할게요"
        static let deleteConfirm = "기록을 삭제할까요? 한번 삭제하면 되돌릴 수 없어요"
        static let deleteButton = "삭제할게요"
        static let cancelDelete = "아니요, 유지할게요"

        static func firstRecord(nickname: String) -> String {
            "첫 번째 시향기를 기록했어요!\n\(nickname)님의 향수 여정이 시작됐네요"
        }

        static let savedSuccess = "기록이 저장됐어요"
        static let updatedSuccess = "기록이 수정됐어요"
    }
}
