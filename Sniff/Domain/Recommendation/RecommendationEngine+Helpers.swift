//
//  RecommendationEngine+Helpers.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

import Foundation

extension RecommendationEngine {

    func uniquePerfumes(from perfumes: [Perfume]) -> [Perfume] {
        var seen = Set<String>()

        return perfumes.filter { perfume in
            let keys = RecommendationPerfumeIdentity.keys(for: perfume)

            guard !keys.isEmpty else { return true }
            guard seen.isDisjoint(with: keys) else { return false }
            keys.forEach { seen.insert($0) }
            return true
        }
    }
}
