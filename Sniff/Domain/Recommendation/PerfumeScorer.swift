//
//  PerfumeScorer.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.15.
//

import Foundation

struct PerfumeScorer {

    func score(
        perfume: FragellaPerfume,
        profile: UserTasteProfile
    ) -> Double {

        var total: Double = 0

        let families = [
            perfume.scentFamily ?? "",
            perfume.scentFamily2 ?? ""
        ].filter { !$0.isEmpty }

        for family in families {
            total += profile.familyScores[family, default: 0]
        }

        if profile.intensityLevel.contains("강") {
            if families.contains(where: { $0.contains("Amber") || $0.contains("Woody") }) {
                total += 5
            }
        }

        if profile.intensityLevel.contains("약") {
            if families.contains(where: { $0.contains("Fresh") || $0.contains("Citrus") || $0.contains("Water") }) {
                total += 5
            }
        }

        return total
    }
}
