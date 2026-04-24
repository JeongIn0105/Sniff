//
//  AppStrings+TastingNoteData.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings.DomainDisplay {
    enum TastingNoteData {
        nonisolated static let freshTag = "상큼한"
        nonisolated static let coolTag = "시원한"
        nonisolated static let subtleTag = "은은한"
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
            "따뜻한", "시원한", "은은한", "강렬한",
            "상큼한", "달콤한", "보송보송한", "묵직한",
            "가벼운", "깨끗한", "포근한", "세련된",
            "고급스러운", "자연스러운", "신비로운",
            "활기찬", "중성적인", "여유로운"
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
