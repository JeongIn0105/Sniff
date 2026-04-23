//
//  UserTasteProfile.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//
    //
    //  UserTasteProfile.swift
    //  Sniff
    //

import Foundation

enum RecommendationStage {
    case onboardingOnly
    case onboardingCollection
    case earlyTasting
    case heavyTasting
}

struct UserTasteProfile {
    let analysisSummary: String
    let preferredImpressions: [String]
    let preferredFamilies: [String]       // 상위 5개 계열 이름 (display용)
    let intensityLevel: String
    let safeStartingPoint: String

        // 기존 — display·디버그용 원시 점수 (하위 호환 유지)
    let familyScores: [String: Double]

        // 신규 — 벡터 기반 추천에 사용되는 정규화된 취향 분포
        // 값의 합 = 1.0, 각 값은 해당 계열에 대한 선호 비율
        // PerfumeScorer가 이 값을 기준으로 코사인 유사도 계산
    let scentVector: [String: Double]

    let stage: RecommendationStage
}
