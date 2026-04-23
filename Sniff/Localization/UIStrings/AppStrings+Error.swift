//
//  AppStrings+Error.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Error {
        static let network = "잠깐, 연결이 끊겼나봐요. 다시 시도해볼까요?"
        static let retry = "다시 시도하기"
        static let unknown = "앗, 문제가 생겼어요. 잠시 후 다시 시도해주세요"
        static let loading = "불러오고 있어요"
        static let perfumeLoading = "향수를 찾고 있어요"
        static let analyzing = "취향에 맞는 향수를 찾고 있어요..."
    }
}
