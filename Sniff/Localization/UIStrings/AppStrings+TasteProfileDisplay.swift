//
//  AppStrings+TasteProfileDisplay.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import Foundation

extension AppStrings.DomainDisplay {
    enum TasteProfile {
        nonisolated static let needsCollectionOrRecord = "향수를 등록하거나 시향 기록을 남기면 취향이 더 선명해져요"
        nonisolated static let needsTastingRecord = "시향 기록을 남기면 취향이 더 정확해져요"
        nonisolated static let updatedFromTasting = "시향 기록 기반으로 업데이트됐어요"

        nonisolated static func tastingCount(_ count: Int) -> String {
            "시향 기록 \(count)개"
        }

        nonisolated static func collectionCount(_ count: Int) -> String {
            "보유 향수 \(count)개"
        }

        nonisolated static func updatedFrom(_ parts: String) -> String {
            "\(parts) 기반으로 취향이 업데이트됐어요"
        }

        nonisolated static func prefersTwo(_ first: String, _ second: String) -> String {
            "사용자님은 \(first) 분위기와 \(second) 분위기를 선호해요"
        }

        nonisolated static func prefersOne(_ first: String) -> String {
            "사용자님은 \(first) 분위기를 선호해요"
        }
    }

    enum LikePerfumes {
        nonisolated static let title = "LIKE 향수"
        nonisolated static let empty = "등록된 LIKE 향수가 없어요"

        nonisolated static func count(_ count: Int) -> String {
            "LIKE 향수 \(count)개"
        }
    }
}
