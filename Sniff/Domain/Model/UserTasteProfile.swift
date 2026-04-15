//
//  UserTasteProfile.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//
import Foundation

enum RecommendationStage {
    case onboardingOnly
    case onboardingCollection
    case earlyTasting
    case heavyTasting
}

struct UserTasteProfile {
    let primaryProfileCode: String
    let primaryProfileName: String
    let secondaryProfileCode: String
    let secondaryProfileName: String
    let analysisSummary: String
    let preferredFamilies: [String]
    let intensityLevel: String
    let familyScores: [String: Double]
    let stage: RecommendationStage
}
