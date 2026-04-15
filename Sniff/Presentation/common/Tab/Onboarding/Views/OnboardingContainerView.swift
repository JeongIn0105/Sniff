//
//  OnboardingContainerView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI

struct OnboardingContainerView: View {

    @StateObject private var viewModel = OnboardingViewModel()
    let onBack: () -> Void
    let onComplete: () -> Void

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .nickname:
                OnboardingNicknameView(viewModel: viewModel, onBack: onBack)

            case .experience:
                OnboardingExperienceView(viewModel: viewModel)

            case .taste:
                OnboardingTasteView(viewModel: viewModel)

            case .result:
                OnboardingResultView(viewModel: viewModel, onComplete: onComplete)
            }
        }
    }
}
