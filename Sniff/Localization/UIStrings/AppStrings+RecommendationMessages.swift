//
//  AppStrings+RecommendationMessages.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings {
    enum Recommendation {
        static let strongPresence = "진하고 존재감 있는 무드 선호를 반영한 추천이에요"
        static let lightFresh = "가볍고 산뜻한 무드 선호를 반영한 추천이에요"

        static func familyPreference(_ family: String) -> String {
            "\(family) 계열 선호가 반영된 추천이에요"
        }

        static func impressionPreference(_ impression: String) -> String {
            "\(impression) 인상을 살리기 좋은 추천이에요"
        }

        static func familyMoodMatch(_ family: String) -> String {
            "\(family) 무드가 현재 취향과 잘 맞아요"
        }

        static func profileFlow(_ title: String) -> String {
            "\(title) 흐름을 반영한 추천이에요"
        }
    }
}
