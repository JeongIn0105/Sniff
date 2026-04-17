//
//  UserPreference.swift
//  sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import Foundation

// 온보딩에서 수집하는 취향 데이터 모델
struct UserPreference {
    var experience: ExperienceLevel = .beginner
    var moods: [String] = []       // 최대 5개
    var families: [String] = []    // 최대 3개
}
