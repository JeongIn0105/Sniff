//
//  AppStrings+TastingNoteData.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings.DomainDisplay {
    enum TastingNoteData {
        nonisolated static let sophisticatedTag = "세련된"
        nonisolated static let naturalTag = "자연스러운"
        nonisolated static let mysteriousTag = "신비로운"
        nonisolated static let vibrantTag = "활기찬"
        nonisolated static let relaxedTag = "여유로운"
        nonisolated static let pureTag = "청순한"
        nonisolated static let sensualTag = "섹시한"
        nonisolated static let calmTag = "차분한"
        nonisolated static let chicTag = "시크한"
        nonisolated static let freshTag = "상큼한"
        nonisolated static let coolTag = "시원한"
        nonisolated static let subtleTag = "은은한"
        nonisolated static let sweetTag = "달콤한"
        nonisolated static let cleanTag = "깨끗한"
        nonisolated static let softTag = "부드러운"
        nonisolated static let clearTag = "맑은"
        nonisolated static let deepTag = "짙은"

        nonisolated static let powderyTag = "보송보송한"
        nonisolated static let warmTag = "따뜻한"
        nonisolated static let heavyTag = "묵직한"
        nonisolated static let airyGreenTag = "싱그러운"
        nonisolated static let heavierTag = "무거운"

        nonisolated static let revisitDesireList: [String] = [
            "매일 뿌리고 싶어",
            "가끔 꺼내고 싶어",
            "기억에 남아, 근데 내 향은 아니야",
            "다시 맡고 싶지 않아"
        ]

        nonisolated static let moodTagList: [String] = [
            sophisticatedTag, naturalTag, mysteriousTag,
            vibrantTag, relaxedTag, pureTag,
            sensualTag, calmTag, chicTag,
            warmTag, coolTag, freshTag,
            sweetTag, cleanTag, softTag,
            subtleTag, clearTag, deepTag
        ]

        nonisolated static func ratingLabel(_ rating: Int) -> String {
            switch rating {
            case 1: return "나와 맞지 않는 향이에요"
            case 2: return "조금 아쉬운 편이에요"
            case 3: return "보통이에요"
            case 4: return "나와 잘 맞는 향이에요"
            case 5: return "나와 매우 잘 맞는 향이에요"
            default: return ""
            }
        }
    }
}
