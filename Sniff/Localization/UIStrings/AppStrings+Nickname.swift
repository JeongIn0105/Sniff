//
//  AppStrings+Nickname.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Nickname {
        static let title = "킁킁에서 사용할 닉네임을\n입력해주세요"
        static let label = "닉네임"
        static let placeholder = "닉네임 입력"
        static let description = "*한글, 영문, 숫자 포함 2~10자 제한"
        static let duplicateCheck = "중복 확인"
        static let available = "*사용 가능한 닉네임입니다."
        static let unavailable = "*중복된 닉네임입니다."
        static let invalid = "*한글, 영문, 숫자 포함 2~10자로 입력해주세요."
        static let confirm = "다음"

        static func welcome(nickname: String) -> String {
            "반가워요, \(nickname)님!\n취향에 맞는 향을 찾아드릴게요"
        }
    }
}
