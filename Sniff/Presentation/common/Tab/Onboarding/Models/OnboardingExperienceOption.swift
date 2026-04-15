//
//  OnboardingExperienceOption.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import Foundation

struct OnboardingExperienceOption: Identifiable {
    let title: String
    let description: String
    let level: ExperienceLevel

    var id: ExperienceLevel { level }

    static let all: [OnboardingExperienceOption] = [
        .init(
            title: AppStrings.Onboarding.Experience.beginner,
            description: AppStrings.Onboarding.Experience.beginnerDesc,
            level: .beginner
        ),
        .init(
            title: AppStrings.Onboarding.Experience.casual,
            description: AppStrings.Onboarding.Experience.casualDesc,
            level: .casual
        ),
        .init(
            title: AppStrings.Onboarding.Experience.expert,
            description: AppStrings.Onboarding.Experience.expertDesc,
            level: .expert
        )
    ]
}
